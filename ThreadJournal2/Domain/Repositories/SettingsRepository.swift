//
//  SettingsRepository.swift
//  ThreadJournal2
//
//  Created by Claude on 2025-08-06.
//

import Foundation

/// Repository protocol for managing user settings persistence.
/// This follows Clean Architecture principles by defining the interface in the Domain layer
/// while the implementation resides in the Infrastructure layer.
protocol SettingsRepository {
    
    /// Retrieves the current user settings.
    /// - Returns: The current UserSettings or default values if no settings exist
    /// - Throws: SettingsError.persistenceError if retrieval fails
    func get() async throws -> UserSettings
    
    /// Saves the provided user settings.
    /// - Parameter settings: The UserSettings to persist
    /// - Throws: SettingsError.persistenceError if saving fails
    func save(_ settings: UserSettings) async throws
}