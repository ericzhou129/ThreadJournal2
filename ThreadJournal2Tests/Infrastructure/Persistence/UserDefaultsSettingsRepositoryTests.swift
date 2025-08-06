//
//  UserDefaultsSettingsRepositoryTests.swift
//  ThreadJournal2Tests
//
//  Created by Claude on 2025-08-06.
//

import XCTest
@testable import ThreadJournal2

final class UserDefaultsSettingsRepositoryTests: XCTestCase {
    
    private var repository: UserDefaultsSettingsRepository!
    private var userDefaults: UserDefaults!
    private let testSuiteName = "UserDefaultsSettingsRepositoryTests"
    
    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: testSuiteName)!
        userDefaults.removePersistentDomain(forName: testSuiteName)
        repository = UserDefaultsSettingsRepository(userDefaults: userDefaults)
    }
    
    override func tearDown() {
        userDefaults.removePersistentDomain(forName: testSuiteName)
        userDefaults = nil
        repository = nil
        super.tearDown()
    }
    
    // MARK: - Default Values Tests
    
    func testGetReturnsDefaultSettingsWhenNoneExist() async throws {
        let settings = try await repository.get()
        
        XCTAssertFalse(settings.biometricAuthEnabled)
        XCTAssertEqual(settings.textSizePercentage, 100)
    }
    
    // MARK: - Save and Retrieve Tests
    
    func testSaveAndRetrieveSettings() async throws {
        let originalSettings = UserSettings(biometricAuthEnabled: true, textSizePercentage: 120)
        
        try await repository.save(originalSettings)
        let retrievedSettings = try await repository.get()
        
        XCTAssertEqual(retrievedSettings, originalSettings)
    }
    
    func testSaveOverwritesPreviousSettings() async throws {
        let firstSettings = UserSettings(biometricAuthEnabled: true, textSizePercentage: 110)
        let secondSettings = UserSettings(biometricAuthEnabled: false, textSizePercentage: 130)
        
        try await repository.save(firstSettings)
        try await repository.save(secondSettings)
        let retrievedSettings = try await repository.get()
        
        XCTAssertEqual(retrievedSettings, secondSettings)
        XCTAssertNotEqual(retrievedSettings, firstSettings)
    }
    
    func testSaveMinimumSettings() async throws {
        let settings = UserSettings(biometricAuthEnabled: false, textSizePercentage: 80)
        
        try await repository.save(settings)
        let retrievedSettings = try await repository.get()
        
        XCTAssertEqual(retrievedSettings, settings)
    }
    
    func testSaveMaximumSettings() async throws {
        let settings = UserSettings(biometricAuthEnabled: true, textSizePercentage: 150)
        
        try await repository.save(settings)
        let retrievedSettings = try await repository.get()
        
        XCTAssertEqual(retrievedSettings, settings)
    }
    
    // MARK: - Persistence Tests
    
    func testSettingsPersistAcrossRepositoryInstances() async throws {
        let originalSettings = UserSettings(biometricAuthEnabled: true, textSizePercentage: 140)
        
        try await repository.save(originalSettings)
        
        // Create new repository instance with same UserDefaults
        let newRepository = UserDefaultsSettingsRepository(userDefaults: userDefaults)
        let retrievedSettings = try await newRepository.get()
        
        XCTAssertEqual(retrievedSettings, originalSettings)
    }
    
    // MARK: - Error Handling Tests
    
    func testGetWithCorruptedDataReturnsDefaults() async throws {
        // Write invalid JSON data to UserDefaults
        userDefaults.set("invalid json data", forKey: UserDefaultsSettingsRepository.defaultKey)
        
        let settings = try await repository.get()
        
        // Should return default settings when data is corrupted
        XCTAssertFalse(settings.biometricAuthEnabled)
        XCTAssertEqual(settings.textSizePercentage, 100)
    }
    
    func testGetWithWrongDataTypeReturnsDefaults() async throws {
        // Write wrong data type to UserDefaults
        userDefaults.set(123, forKey: UserDefaultsSettingsRepository.defaultKey)
        
        let settings = try await repository.get()
        
        // Should return default settings when data type is wrong
        XCTAssertFalse(settings.biometricAuthEnabled)
        XCTAssertEqual(settings.textSizePercentage, 100)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentAccess() async throws {
        let settings1 = UserSettings(biometricAuthEnabled: true, textSizePercentage: 90)
        let settings2 = UserSettings(biometricAuthEnabled: false, textSizePercentage: 120)
        
        // Perform concurrent save operations
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                try? await self.repository.save(settings1)
            }
            group.addTask {
                try? await self.repository.save(settings2)
            }
            group.addTask {
                _ = try? await self.repository.get()
            }
        }
        
        // Verify repository remains functional after concurrent access
        let finalSettings = try await repository.get()
        XCTAssertTrue(finalSettings == settings1 || finalSettings == settings2)
    }
    
    // MARK: - JSON Encoding/Decoding Tests
    
    func testJSONEncodingFormat() async throws {
        let settings = UserSettings(biometricAuthEnabled: true, textSizePercentage: 130)
        
        try await repository.save(settings)
        
        // Verify the JSON format stored in UserDefaults
        let storedData = userDefaults.data(forKey: UserDefaultsSettingsRepository.defaultKey)
        XCTAssertNotNil(storedData)
        
        let storedJSON = try JSONSerialization.jsonObject(with: storedData!, options: []) as? [String: Any]
        XCTAssertNotNil(storedJSON)
        XCTAssertEqual(storedJSON?["biometricAuthEnabled"] as? Bool, true)
        XCTAssertEqual(storedJSON?["textSizePercentage"] as? Int, 130)
    }
    
    // MARK: - Key Tests
    
    func testDefaultKeyConstant() {
        XCTAssertEqual(UserDefaultsSettingsRepository.defaultKey, "ThreadJournal.UserSettings")
    }
    
    // MARK: - Memory Management Tests
    
    func testRepositoryDeallocation() async throws {
        var repository: UserDefaultsSettingsRepository? = UserDefaultsSettingsRepository(userDefaults: userDefaults)
        weak var weakRepository = repository
        
        let settings = UserSettings(biometricAuthEnabled: true, textSizePercentage: 100)
        try await repository?.save(settings)
        
        repository = nil
        
        XCTAssertNil(weakRepository, "Repository should be deallocated")
    }
}