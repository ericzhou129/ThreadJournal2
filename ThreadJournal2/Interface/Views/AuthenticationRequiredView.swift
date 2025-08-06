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
    @State private var hasAttemptedAuth = false
    
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
        .onAppear {
            // Automatically trigger authentication when view appears
            if !hasAttemptedAuth {
                hasAttemptedAuth = true
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
            isAuthenticating = true
            
            do {
                try await onAuthenticate()
            } catch {
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