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
    
    // MARK: - Dependencies
    
    private var biometricAuthService: BiometricAuthService?
    
    // MARK: - Initialization
    
    init() {
        setupAuthentication()
        checkAuthenticationRequirement()
    }
    
    // MARK: - Public Methods
    
    func lockForBackground() {
        if needsAuthentication {
            isAuthenticated = false
            #if DEBUG
            print("AppAuthVM: Locked - isAuthenticated set to: \(isAuthenticated)")
            #endif
        }
    }
    
    func performAuthentication() async throws {
        guard let biometricService = biometricAuthService else { return }
        
        do {
            let authenticated = try await biometricService.authenticate()
            isAuthenticated = authenticated
            #if DEBUG
            print("AppAuthVM: Authentication result: \(authenticated)")
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
                isAuthenticated = true
                return
            }
            
            do {
                let authEnabled = try await biometricService.isBiometricEnabled()
                
                #if DEBUG
                print("AppAuthVM: Checking auth requirement - biometric enabled: \(authEnabled)")
                #endif
                
                needsAuthentication = authEnabled
                hasCheckedSettings = true
                
                // If biometric is not enabled, allow immediate access
                if !authEnabled {
                    isAuthenticated = true
                }
            } catch {
                #if DEBUG
                print("AppAuthVM: Error checking settings: \(error)")
                #endif
                
                needsAuthentication = false
                isAuthenticated = true
                hasCheckedSettings = true
            }
        }
    }
}