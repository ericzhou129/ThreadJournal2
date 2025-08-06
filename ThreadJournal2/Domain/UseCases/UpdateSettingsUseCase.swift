//
//  UpdateSettingsUseCase.swift
//  ThreadJournal2
//
//  Created by Claude on 2025-08-06.
//

import Foundation

/// Use case protocol for updating user settings.
/// Encapsulates the business rules for settings validation and persistence.
protocol UpdateSettingsUseCase {
    
    /// Updates the user settings after validation.
    /// - Parameter settings: The UserSettings to validate and save
    /// - Throws: SettingsError.invalidTextSize if text size is invalid
    /// - Throws: SettingsError.persistenceError if saving fails
    func execute(settings: UserSettings) async throws
}

/// Implementation of UpdateSettingsUseCase following Clean Architecture principles.
/// Contains business logic for settings validation and orchestrates persistence.
final class UpdateSettingsUseCaseImpl: UpdateSettingsUseCase {
    
    // MARK: - Dependencies
    
    private let repository: SettingsRepository
    
    // MARK: - Initialization
    
    /// Creates an UpdateSettingsUseCase with the specified repository.
    /// - Parameter repository: The settings repository for persistence
    init(repository: SettingsRepository) {
        self.repository = repository
    }
    
    // MARK: - Public Methods
    
    /// Updates the user settings after validation.
    /// Validates business rules before persisting to ensure data integrity.
    /// - Parameter settings: The UserSettings to validate and save
    /// - Throws: SettingsError.invalidTextSize if validation fails
    /// - Throws: SettingsError.persistenceError if saving fails
    func execute(settings: UserSettings) async throws {
        // Validate business rules
        try validateSettings(settings)
        
        // Persist validated settings
        do {
            try await repository.save(settings)
        } catch {
            throw SettingsError.persistenceError
        }
    }
    
    // MARK: - Private Methods
    
    /// Validates the settings according to business rules.
    /// - Parameter settings: The settings to validate
    /// - Throws: SettingsError.invalidTextSize if validation fails
    private func validateSettings(_ settings: UserSettings) throws {
        guard UserSettings.isValidTextSize(settings.textSizePercentage) else {
            throw SettingsError.invalidTextSize
        }
    }
}