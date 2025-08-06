//
//  UserDefaultsSettingsRepository.swift
//  ThreadJournal2
//
//  Created by Claude on 2025-08-06.
//

import Foundation

/// UserDefaults-based implementation of SettingsRepository.
/// Stores settings as JSON data in UserDefaults for persistence between app launches.
/// This implementation follows Clean Architecture by implementing the Domain layer protocol
/// while residing in the Infrastructure layer.
final class UserDefaultsSettingsRepository: SettingsRepository {
    
    // MARK: - Constants
    
    /// The key used to store settings in UserDefaults
    static let defaultKey = "ThreadJournal.UserSettings"
    
    // MARK: - Dependencies
    
    private let userDefaults: UserDefaults
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Initialization
    
    /// Creates a UserDefaultsSettingsRepository with the specified UserDefaults instance.
    /// - Parameters:
    ///   - userDefaults: The UserDefaults instance to use for persistence. Defaults to .standard
    ///   - key: The key to use for storing settings. Defaults to "ThreadJournal.UserSettings"
    init(userDefaults: UserDefaults = .standard, key: String = defaultKey) {
        self.userDefaults = userDefaults
        self.key = key
    }
    
    // MARK: - SettingsRepository Protocol
    
    /// Retrieves the current user settings from UserDefaults.
    /// Returns default settings if no settings exist or if data is corrupted.
    /// - Returns: The current UserSettings or default values if none exist
    /// - Throws: SettingsError.persistenceError if there's an unexpected error during retrieval
    func get() async throws -> UserSettings {
        guard let data = userDefaults.data(forKey: key) else {
            // No settings exist, return defaults
            return UserSettings()
        }
        
        do {
            let settings = try decoder.decode(UserSettings.self, from: data)
            return settings
        } catch {
            // Data is corrupted or in wrong format, return defaults
            // Log error in DEBUG builds but don't throw - graceful degradation
            #if DEBUG
            print("UserDefaultsSettingsRepository: Failed to decode settings, returning defaults. Error: \(error)")
            #endif
            return UserSettings()
        }
    }
    
    /// Saves the provided user settings to UserDefaults.
    /// The settings are encoded as JSON data for storage.
    /// - Parameter settings: The UserSettings to persist
    /// - Throws: SettingsError.persistenceError if encoding or saving fails
    func save(_ settings: UserSettings) async throws {
        do {
            let data = try encoder.encode(settings)
            userDefaults.set(data, forKey: key)
            
            // Force synchronization to ensure data is written
            userDefaults.synchronize()
        } catch {
            // Encoding failed - this is a serious error we should propagate
            #if DEBUG
            print("UserDefaultsSettingsRepository: Failed to encode settings. Error: \(error)")
            #endif
            throw SettingsError.persistenceError
        }
    }
}