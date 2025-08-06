//
//  BiometricAuthService.swift
//  ThreadJournal2
//
//  Created by Claude on 2025-08-06.
//

import Foundation
import LocalAuthentication

/// Service for handling biometric authentication (Face ID/Touch ID) with strict security requirements.
/// This implementation enforces NO GRACE PERIOD - authentication is required every time the app
/// opens or returns from background for maximum privacy protection.
final class BiometricAuthService {
    
    // MARK: - Dependencies
    
    private let context: LAContext
    private let settingsRepository: SettingsRepository
    
    // MARK: - Initialization
    
    /// Creates a BiometricAuthService with the specified dependencies.
    /// - Parameters:
    ///   - context: The LAContext for biometric evaluation. Defaults to LAContext()
    ///   - settingsRepository: Repository for accessing user settings
    init(context: LAContext = LAContext(), settingsRepository: SettingsRepository) {
        self.context = context
        self.settingsRepository = settingsRepository
    }
    
    // MARK: - Public Methods
    
    /// Checks if biometric authentication is available on the current device.
    /// - Returns: true if Face ID or Touch ID is available, false otherwise
    func isBiometricAvailable() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    /// Checks if biometric authentication is enabled in user settings.
    /// - Returns: true if user has enabled biometric authentication
    /// - Throws: SettingsError if unable to retrieve settings
    func isBiometricEnabled() async throws -> Bool {
        let settings = try await settingsRepository.get()
        return settings.biometricAuthEnabled
    }
    
    /// Performs biometric authentication with strict security requirements.
    /// NO GRACE PERIOD - authentication is always required when biometric is enabled.
    /// - Returns: true if authentication succeeded or biometric is disabled
    /// - Throws: BiometricAuthError for various authentication failure scenarios
    func authenticate() async throws -> Bool {
        // Check if biometric authentication is enabled
        guard try await isBiometricEnabled() else {
            // Biometric is disabled, allow access
            return true
        }
        
        // Verify biometric is available on device
        guard isBiometricAvailable() else {
            throw BiometricAuthError.biometricNotAvailable
        }
        
        // Perform biometric authentication with no grace period
        return try await performBiometricAuthentication()
    }
    
    // MARK: - Private Methods
    
    /// Performs the actual biometric authentication using LocalAuthentication framework.
    /// - Returns: true if authentication succeeded
    /// - Throws: BiometricAuthError based on the specific failure reason
    private func performBiometricAuthentication() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Access your journal entries"
            ) { success, error in
                if success {
                    continuation.resume(returning: true)
                } else {
                    let authError = self.mapLAErrorToBiometricError(error)
                    continuation.resume(throwing: authError)
                }
            }
        }
    }
    
    /// Maps LocalAuthentication errors to BiometricAuthError with appropriate handling.
    /// - Parameter error: The error returned from LAContext.evaluatePolicy
    /// - Returns: Appropriate BiometricAuthError for the error scenario
    private func mapLAErrorToBiometricError(_ error: Error?) -> BiometricAuthError {
        guard let laError = error as? LAError else {
            return .unknown
        }
        
        switch laError.code {
        case .userCancel:
            return .userCancelled
        case .userFallback, .systemCancel, .passcodeNotSet, .biometryLockout:
            return .authenticationFailed
        case .biometryNotAvailable, .biometryNotEnrolled:
            return .biometricNotAvailable
        default:
            return .unknown
        }
    }
}

// MARK: - BiometricAuthError

/// Errors that can occur during biometric authentication
enum BiometricAuthError: Error, Equatable {
    case biometricNotAvailable
    case authenticationFailed
    case userCancelled
    case unknown
}

extension BiometricAuthError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device"
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .userCancelled:
            return "Authentication was cancelled by the user"
        case .unknown:
            return "An unknown error occurred during authentication"
        }
    }
}

// LAContext is used directly without protocol abstraction for simplicity