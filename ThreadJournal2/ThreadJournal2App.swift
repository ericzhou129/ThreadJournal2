//
//  ThreadJournal2App.swift
//  ThreadJournal2
//
//  Created by Eric Zhou on 2025-07-17.
//

import SwiftUI

@main
struct ThreadJournal2App: App {
    let persistenceController = PersistenceController.shared
    
    @Environment(\.scenePhase) private var scenePhase
    
    // Authentication state
    @State private var isAuthenticated = false
    @State private var needsAuthentication = true
    @State private var biometricAuthService: BiometricAuthService?
    
    var body: some Scene {
        WindowGroup {
            Group {
                if needsAuthentication && !isAuthenticated {
                    AuthenticationRequiredView {
                        try await performAuthentication()
                    }
                } else {
                    ThreadListView(viewModel: makeThreadListViewModel())
                }
            }
            .onAppear {
                setupAuthentication()
                checkAuthenticationRequirement()
            }
            .onChange(of: scenePhase) {
                handleScenePhaseChange(scenePhase)
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    private func setupAuthentication() {
        let settingsRepository = UserDefaultsSettingsRepository()
        biometricAuthService = BiometricAuthService(settingsRepository: settingsRepository)
    }
    
    private func checkAuthenticationRequirement() {
        Task {
            guard let biometricService = biometricAuthService else { return }
            
            do {
                needsAuthentication = try await biometricService.isBiometricEnabled()
                
                // If biometric is not enabled, allow immediate access
                if !needsAuthentication {
                    await MainActor.run {
                        isAuthenticated = true
                    }
                }
            } catch {
                // On error checking settings, default to not requiring authentication
                await MainActor.run {
                    needsAuthentication = false
                    isAuthenticated = true
                }
            }
        }
    }
    
    private func performAuthentication() async throws {
        guard let biometricService = biometricAuthService else { return }
        
        do {
            let authenticated = try await biometricService.authenticate()
            
            await MainActor.run {
                isAuthenticated = authenticated
            }
        } catch {
            // Authentication failed - remain locked
            await MainActor.run {
                isAuthenticated = false
            }
            throw error
        }
    }
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            // Lock immediately when app goes to background
            if needsAuthentication {
                isAuthenticated = false
            }
            
        case .active:
            // Re-check authentication requirement when returning to active
            checkAuthenticationRequirement()
            
        case .inactive:
            // App is transitioning, maintain current state
            break
            
        @unknown default:
            break
        }
    }
    
    // MARK: - Factory Methods
    
    private func makeThreadListViewModel() -> ThreadListViewModel {
        let repository = persistenceController.makeThreadRepository()
        let createThreadUseCase = CreateThreadUseCase(repository: repository)
        let deleteThreadUseCase = DeleteThreadUseCaseImpl(repository: repository)
        
        return ThreadListViewModel(
            repository: repository,
            createThreadUseCase: createThreadUseCase,
            deleteThreadUseCase: deleteThreadUseCase
        )
    }
}
