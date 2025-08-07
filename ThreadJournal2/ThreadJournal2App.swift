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
    @StateObject private var authViewModel = AppAuthenticationViewModel()
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Main content - always present to maintain state
                ThreadListView(viewModel: makeThreadListViewModel())
                    .opacity(authViewModel.hasCheckedSettings ? 1 : 0)
                
                // Loading overlay while checking settings
                if !authViewModel.hasCheckedSettings {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                        .overlay(ProgressView())
                }
                
                // Authentication overlay when needed
                if authViewModel.hasCheckedSettings && authViewModel.needsAuthentication && !authViewModel.isAuthenticated {
                    #if DEBUG
                    let _ = print("App: Showing AuthenticationRequiredView - hasChecked: \(authViewModel.hasCheckedSettings), needsAuth: \(authViewModel.needsAuthentication), isAuth: \(authViewModel.isAuthenticated)")
                    #endif
                    AuthenticationRequiredView {
                        try await authViewModel.performAuthentication()
                    }
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                handleScenePhaseChange(newPhase)
            }
        }
    }
    
    // MARK: - Scene Phase Handling
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        #if DEBUG
        print("App: Scene phase changed to: \(newPhase), needsAuth: \(authViewModel.needsAuthentication), isAuth: \(authViewModel.isAuthenticated)")
        #endif
        
        switch newPhase {
        case .background:
            // Lock immediately when app goes to background
            #if DEBUG
            print("App: Going to background - locking if needed")
            #endif
            authViewModel.lockForBackground()
            
        case .active:
            // When returning to active, refresh authentication state
            #if DEBUG
            print("App: Returning to active - needsAuth: \(authViewModel.needsAuthentication), isAuth: \(authViewModel.isAuthenticated)")
            print("App: Should show auth screen: \(authViewModel.needsAuthentication && !authViewModel.isAuthenticated)")
            #endif
            authViewModel.refreshAuthenticationState()
            
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
