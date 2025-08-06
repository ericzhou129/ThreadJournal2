//
//  SettingsViewModel.swift
//  ThreadJournal2
//
//  Created by Claude on 2025-08-06.
//

import Foundation

/// ViewModel for managing settings screen state and user interactions.
/// Orchestrates settings use cases and provides reactive state for the UI.
/// This class follows Clean Architecture by containing no business logic
/// and delegating all operations to use cases.
@MainActor
final class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether biometric authentication (Face ID/Touch ID) is enabled.
    /// When enabled, authentication is required every time the app opens.
    @Published var biometricAuthEnabled: Bool = false
    
    /// Text size percentage for journal entry content (80-150%).
    @Published var textSizePercentage: Int = 100
    
    /// Whether the privacy policy sheet is currently being shown.
    @Published var showingPrivacyPolicy: Bool = false
    
    /// Current error message to display to the user.
    /// Empty string indicates no error.
    @Published var errorMessage: String = ""
    
    // MARK: - Dependencies
    
    private let getSettingsUseCase: GetSettingsUseCase
    private let updateSettingsUseCase: UpdateSettingsUseCase
    private let biometricAuthService: BiometricAuthService
    
    // MARK: - Initialization
    
    /// Creates a SettingsViewModel with the specified dependencies.
    /// Automatically loads current settings on initialization.
    /// - Parameters:
    ///   - getSettingsUseCase: Use case for retrieving current settings
    ///   - updateSettingsUseCase: Use case for saving settings changes
    ///   - biometricAuthService: Service for biometric authentication operations
    init(
        getSettingsUseCase: GetSettingsUseCase,
        updateSettingsUseCase: UpdateSettingsUseCase,
        biometricAuthService: BiometricAuthService
    ) {
        self.getSettingsUseCase = getSettingsUseCase
        self.updateSettingsUseCase = updateSettingsUseCase
        self.biometricAuthService = biometricAuthService
        
        // Load current settings asynchronously on initialization
        Task {
            await loadSettings()
        }
    }
    
    // MARK: - Public Methods
    
    /// Toggles biometric authentication on/off.
    /// Checks biometric availability before enabling and saves changes immediately.
    func toggleBiometric() async {
        // Check if biometric authentication is available on device
        guard biometricAuthService.isBiometricAvailable() else {
            errorMessage = "Biometric authentication is not available on this device"
            return
        }
        
        // Toggle the setting
        biometricAuthEnabled.toggle()
        
        // Save the changes
        await saveCurrentSettings()
    }
    
    /// Updates the text size percentage with validation.
    /// Clamps the value to the valid range (80-150%) and saves immediately.
    /// - Parameter percentage: The new text size percentage
    func updateTextSize(_ percentage: Int) async {
        // Clamp to valid range
        textSizePercentage = max(
            UserSettings.minimumTextSize,
            min(UserSettings.maximumTextSize, percentage)
        )
        
        // Save the changes
        await saveCurrentSettings()
    }
    
    /// Shows the privacy policy sheet.
    func showPrivacyPolicy() {
        showingPrivacyPolicy = true
    }
    
    /// Hides the privacy policy sheet.
    func hidePrivacyPolicy() {
        showingPrivacyPolicy = false
    }
    
    /// Clears the current error message.
    func clearError() {
        errorMessage = ""
    }
    
    // MARK: - Private Methods
    
    /// Loads current settings from the repository.
    /// Uses default values if loading fails.
    private func loadSettings() async {
        do {
            let settings = try await getSettingsUseCase.execute()
            
            // Update published properties on main thread
            biometricAuthEnabled = settings.biometricAuthEnabled
            textSizePercentage = settings.textSizePercentage
            
        } catch {
            // Use default values if loading fails
            biometricAuthEnabled = false
            textSizePercentage = 100
            
            // Don't show error for failed load - just use defaults
            // This handles first-time users gracefully
        }
    }
    
    /// Saves the current settings state to the repository.
    /// Shows error message if saving fails.
    private func saveCurrentSettings() async {
        let settings = UserSettings(
            biometricAuthEnabled: biometricAuthEnabled,
            textSizePercentage: textSizePercentage
        )
        
        do {
            try await updateSettingsUseCase.execute(settings: settings)
            // Clear any previous error on successful save
            errorMessage = ""
            
        } catch {
            errorMessage = "Unable to save settings. Please try again."
        }
    }
}