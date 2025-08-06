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
    @State private var needsAuthentication = false  // Default to no authentication
    @State private var biometricAuthService: BiometricAuthService?
    @State private var hasCheckedSettings = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                // Only show authentication view after we've checked settings
                if hasCheckedSettings && needsAuthentication && !isAuthenticated {
                    AuthenticationRequiredView {
                        try await performAuthentication()
                    }
                } else if !hasCheckedSettings {
                    // Show a loading state while checking settings
                    Color(.systemBackground)
                        .ignoresSafeArea()
                        .overlay(ProgressView())
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
            guard let biometricService = biometricAuthService else { 
                await MainActor.run {
                    hasCheckedSettings = true
                    isAuthenticated = true
                }
                return 
            }
            
            do {
                let authEnabled = try await biometricService.isBiometricEnabled()
                
                #if DEBUG
                print("App: Checking auth requirement - biometric enabled: \(authEnabled)")
                #endif
                
                await MainActor.run {
                    needsAuthentication = authEnabled
                    hasCheckedSettings = true
                    
                    // If biometric is not enabled, allow immediate access
                    if !authEnabled {
                        isAuthenticated = true
                    }
                    // If biometric IS enabled, keep isAuthenticated = false to trigger auth
                }
            } catch {
                // On error checking settings, default to not requiring authentication
                #if DEBUG
                print("App: Error checking settings: \(error)")
                #endif
                
                await MainActor.run {
                    needsAuthentication = false
                    isAuthenticated = true
                    hasCheckedSettings = true
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
            // When returning to active, if we need auth and aren't authenticated, 
            // the UI will automatically show the auth screen
            // Don't re-check settings here as it causes state issues
            break
            
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
