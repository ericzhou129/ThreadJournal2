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
            ZStack {
                // Main content
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
                if !hasCheckedSettings {
                    setupAuthentication()
                    checkAuthenticationRequirement()
                }
            }
            .onChange(of: scenePhase) { newPhase in
                handleScenePhaseChange(newPhase)
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
        #if DEBUG
        print("App: Scene phase changed to: \(newPhase), needsAuth: \(needsAuthentication), isAuth: \(isAuthenticated)")
        #endif
        
        switch newPhase {
        case .background:
            // Lock immediately when app goes to background
            #if DEBUG
            print("App: Going to background - locking if needed")
            #endif
            if needsAuthentication {
                // Use Task to ensure state change happens on MainActor
                Task { @MainActor in
                    isAuthenticated = false
                    #if DEBUG
                    print("App: Locked - will require auth on return")
                    #endif
                }
            }
            
        case .active:
            // When returning to active, log the state
            #if DEBUG
            print("App: Returning to active - needsAuth: \(needsAuthentication), isAuth: \(isAuthenticated)")
            #endif
            // The UI should automatically show auth screen if needed
            // Force a small delay to ensure UI updates
            if needsAuthentication && !isAuthenticated {
                Task { @MainActor in
                    // This forces the UI to re-evaluate
                    isAuthenticated = false
                }
            }
            
        case .inactive:
            // App is transitioning, maintain current state
            #if DEBUG
            print("App: Inactive phase")
            #endif
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
