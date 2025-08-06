//
//  UserSettings.swift
//  ThreadJournal2
//
//  Created by Claude on 2025-08-06.
//

import Foundation

/// User preferences and configuration settings for the ThreadJournal app.
/// This entity follows Clean Architecture principles and contains no UI or infrastructure dependencies.
struct UserSettings: Codable, Equatable {
    
    // MARK: - Properties
    
    /// Whether biometric authentication (Face ID/Touch ID) is required to access the app.
    /// When enabled, authentication is required EVERY time the app opens or returns from background
    /// with no grace period for maximum privacy protection.
    let biometricAuthEnabled: Bool
    
    /// Text size percentage for journal entry content.
    /// Valid range: 80-150% in 10% increments.
    /// This setting is independent of system Dynamic Type.
    let textSizePercentage: Int
    
    // MARK: - Initialization
    
    /// Creates UserSettings with specified values.
    /// - Parameters:
    ///   - biometricAuthEnabled: Whether biometric authentication is required. Defaults to false.
    ///   - textSizePercentage: Text size percentage (80-150). Defaults to 100.
    init(biometricAuthEnabled: Bool = false, textSizePercentage: Int = 100) {
        self.biometricAuthEnabled = biometricAuthEnabled
        self.textSizePercentage = textSizePercentage
    }
}

// MARK: - Business Rules

extension UserSettings {
    
    /// The minimum allowed text size percentage.
    static let minimumTextSize: Int = 80
    
    /// The maximum allowed text size percentage.
    static let maximumTextSize: Int = 150
    
    /// The increment for text size adjustments.
    static let textSizeIncrement: Int = 10
    
    /// Validates that the text size is within the allowed range and increment.
    /// - Parameter textSize: The text size percentage to validate
    /// - Returns: true if the text size is valid, false otherwise
    static func isValidTextSize(_ textSize: Int) -> Bool {
        return textSize >= minimumTextSize &&
               textSize <= maximumTextSize &&
               textSize % textSizeIncrement == 0
    }
}

// MARK: - Settings Error

/// Errors that can occur during settings operations
enum SettingsError: Error, Equatable {
    case invalidTextSize
    case biometricNotAvailable
    case persistenceError
    case unknown
}

extension SettingsError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidTextSize:
            return "Text size must be between 80% and 150% in 10% increments"
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device"
        case .persistenceError:
            return "Unable to save settings"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}