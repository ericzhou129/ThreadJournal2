//
//  GetSettingsUseCase.swift
//  ThreadJournal2
//
//  Created by Claude on 2025-08-06.
//

import Foundation

/// Use case protocol for retrieving user settings.
/// Encapsulates the business logic for loading and providing default settings.
protocol GetSettingsUseCase {
    
    /// Retrieves the current user settings.
    /// - Returns: The current UserSettings or default values if no settings exist
    /// - Throws: SettingsError.persistenceError if retrieval fails
    func execute() async throws -> UserSettings
}

/// Implementation of GetSettingsUseCase following Clean Architecture principles.
/// Orchestrates settings retrieval and provides default values when needed.
final class GetSettingsUseCaseImpl: GetSettingsUseCase {
    
    // MARK: - Dependencies
    
    private let repository: SettingsRepository
    
    // MARK: - Initialization
    
    /// Creates a GetSettingsUseCase with the specified repository.
    /// - Parameter repository: The settings repository for data retrieval
    init(repository: SettingsRepository) {
        self.repository = repository
    }
    
    // MARK: - Public Methods
    
    /// Retrieves the current user settings.
    /// Loads settings from the repository and ensures valid defaults are provided.
    /// - Returns: The current UserSettings or default values if no settings exist
    /// - Throws: SettingsError.persistenceError if retrieval fails
    func execute() async throws -> UserSettings {
        do {
            return try await repository.get()
        } catch {
            throw SettingsError.persistenceError
        }
    }
}