//
//  AppAuthenticationViewModel.swift
//  ThreadJournal2
//
//  Created by Claude on 2025-08-06.
//

import Foundation
import SwiftUI

/// ViewModel for managing app-level authentication state
@MainActor
final class AppAuthenticationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isAuthenticated = false
    @Published var needsAuthentication = false
    @Published var hasCheckedSettings = false
    
    // MARK: - Private Properties
    
    /// Tracks whether the app has been explicitly locked for background
    private var isLockedForBackground = false
    
    // MARK: - Dependencies
    
    private var biometricAuthService: BiometricAuthServiceProtocol?
    
    // MARK: - Initialization
    
    init() {
        setupAuthentication()
        checkAuthenticationRequirement()
    }
    
    /// Testable initializer with dependency injection
    init(biometricAuthService: BiometricAuthServiceProtocol) {
        self.biometricAuthService = biometricAuthService
        checkAuthenticationRequirement()
    }
    
    // MARK: - Public Methods
    
    func lockForBackground() {
        if needsAuthentication {
            isAuthenticated = false
            isLockedForBackground = true
            #if DEBUG
            print("AppAuthVM: Locked - isAuthenticated set to: \(isAuthenticated), isLockedForBackground: \(isLockedForBackground)")
            #endif
        }
    }
    
    func performAuthentication() async throws {
        guard let biometricService = biometricAuthService else { return }
        
        do {
            let authenticated = try await biometricService.authenticate()
            isAuthenticated = authenticated
            // Clear the locked state once successfully authenticated
            if authenticated {
                isLockedForBackground = false
            }
            #if DEBUG
            print("AppAuthVM: Authentication result: \(authenticated), isLockedForBackground: \(isLockedForBackground)")
            #endif
        } catch {
            isAuthenticated = false
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAuthentication() {
        let settingsRepository = UserDefaultsSettingsRepository()
        biometricAuthService = BiometricAuthService(settingsRepository: settingsRepository)
    }
    
    private func checkAuthenticationRequirement() {
        Task {
            guard let biometricService = biometricAuthService else {
                hasCheckedSettings = true
                // Only set authenticated if not locked for background
                if !isLockedForBackground {
                    isAuthenticated = true
                }
                return
            }
            
            do {
                let authEnabled = try await biometricService.isBiometricEnabled()
                
                #if DEBUG
                print("AppAuthVM: Checking auth requirement - biometric enabled: \(authEnabled), isLockedForBackground: \(isLockedForBackground)")
                #endif
                
                needsAuthentication = authEnabled
                hasCheckedSettings = true
                
                // If biometric is not enabled, allow immediate access only if not locked for background
                if !authEnabled && !isLockedForBackground {
                    isAuthenticated = true
                }
            } catch {
                #if DEBUG
                print("AppAuthVM: Error checking settings: \(error)")
                #endif
                
                needsAuthentication = false
                // Only set authenticated if not locked for background
                if !isLockedForBackground {
                    isAuthenticated = true
                }
                hasCheckedSettings = true
            }
        }
    }
}