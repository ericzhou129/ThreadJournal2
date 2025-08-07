//
//  AuthenticationRequiredView.swift
//  ThreadJournal2
//
//  Created by Claude on 2025-08-06.
//

import SwiftUI

/// View displayed when biometric authentication is required to access the app.
/// Automatically triggers Face ID without requiring user interaction.
struct AuthenticationRequiredView: View {
    
    // MARK: - Properties
    
    let onAuthenticate: () async throws -> Void
    @State private var isAuthenticating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @Environment(\.scenePhase) private var scenePhase
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background - subtle blur effect
            Color(.systemBackground)
                .ignoresSafeArea()
            
            // Simple loading state while authenticating
            if isAuthenticating {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.accentColor)
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            // Only trigger authentication when app becomes active
            if newPhase == .active && oldPhase != .active {
                #if DEBUG
                print("AuthenticationRequiredView: App became active - triggering authentication")
                #endif
                authenticate()
            }
        }
        .onAppear {
            // Only authenticate if app is already active (initial launch)
            if scenePhase == .active {
                #if DEBUG
                print("AuthenticationRequiredView: onAppear with active scene - triggering authentication")
                #endif
                authenticate()
            }
        }
        .alert("Authentication Failed", isPresented: $showingError) {
            Button("Try Again") {
                authenticate()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Private Methods
    
    private func authenticate() {
        Task {
            #if DEBUG
            print("AuthenticationRequiredView: Starting authentication")
            #endif
            isAuthenticating = true
            
            do {
                try await onAuthenticate()
                #if DEBUG
                print("AuthenticationRequiredView: Authentication succeeded")
                #endif
            } catch {
                #if DEBUG
                print("AuthenticationRequiredView: Authentication failed - \(error)")
                #endif
                errorMessage = error.localizedDescription
                showingError = true
            }
            
            isAuthenticating = false
        }
    }
}

// MARK: - Preview

struct AuthenticationRequiredView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationRequiredView {
            // Mock authentication
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        }
        .preferredColorScheme(.light)
        
        AuthenticationRequiredView {
            // Mock authentication
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        }
        .preferredColorScheme(.dark)
    }
}