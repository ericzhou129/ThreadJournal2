//
//  AuthenticationRequiredView.swift
//  ThreadJournal2
//
//  Created by Claude on 2025-08-06.
//

import SwiftUI

/// View displayed when biometric authentication is required to access the app.
/// Shows a privacy-focused message and authentication prompts.
struct AuthenticationRequiredView: View {
    
    // MARK: - Properties
    
    let onAuthenticate: () async throws -> Void
    @State private var isAuthenticating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Lock icon
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                
                // Title and description
                VStack(spacing: 16) {
                    Text("Authentication Required")
                        .font(.title)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                    
                    Text("Your journal entries are protected by biometric authentication. Please authenticate to continue.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Authentication button
                VStack(spacing: 16) {
                    Button(action: authenticate) {
                        HStack(spacing: 12) {
                            if isAuthenticating {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "faceid")
                                    .font(.system(size: 20))
                            }
                            
                            Text(isAuthenticating ? "Authenticating..." : "Authenticate with Face ID")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(25)
                    }
                    .disabled(isAuthenticating)
                    .padding(.horizontal, 32)
                    
                    // Privacy note
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                            
                            Text("Maximum Privacy Protection")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Authentication is required every time you open the app, with no grace period.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 32)
                }
                
                Spacer()
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