//
//  UpdateSettingsUseCaseTests.swift
//  ThreadJournal2Tests
//
//  Created by Claude on 2025-08-06.
//

import XCTest
@testable import ThreadJournal2

final class UpdateSettingsUseCaseTests: XCTestCase {
    
    private var mockRepository: MockSettingsRepository!
    private var useCase: UpdateSettingsUseCaseImpl!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockSettingsRepository()
        useCase = UpdateSettingsUseCaseImpl(repository: mockRepository)
    }
    
    override func tearDown() {
        mockRepository = nil
        useCase = nil
        super.tearDown()
    }
    
    // MARK: - Success Cases
    
    func testExecuteWithValidSettings() async throws {
        let settings = UserSettings(biometricAuthEnabled: true, textSizePercentage: 120)
        
        try await useCase.execute(settings: settings)
        
        XCTAssertEqual(mockRepository.saveCallCount, 1)
        XCTAssertEqual(mockRepository.lastSavedSettings, settings)
    }
    
    func testExecuteWithMinimumTextSize() async throws {
        let settings = UserSettings(biometricAuthEnabled: false, textSizePercentage: 80)
        
        try await useCase.execute(settings: settings)
        
        XCTAssertEqual(mockRepository.saveCallCount, 1)
        XCTAssertEqual(mockRepository.lastSavedSettings?.textSizePercentage, 80)
    }
    
    func testExecuteWithMaximumTextSize() async throws {
        let settings = UserSettings(biometricAuthEnabled: true, textSizePercentage: 150)
        
        try await useCase.execute(settings: settings)
        
        XCTAssertEqual(mockRepository.saveCallCount, 1)
        XCTAssertEqual(mockRepository.lastSavedSettings?.textSizePercentage, 150)
    }
    
    // MARK: - Validation Tests
    
    func testExecuteWithTextSizeBelowMinimum() async {
        let settings = UserSettings(biometricAuthEnabled: false, textSizePercentage: 70)
        
        do {
            try await useCase.execute(settings: settings)
            XCTFail("Expected validation error for text size below minimum")
        } catch SettingsError.invalidTextSize {
            // Expected error
            XCTAssertEqual(mockRepository.saveCallCount, 0)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testExecuteWithTextSizeAboveMaximum() async {
        let settings = UserSettings(biometricAuthEnabled: false, textSizePercentage: 160)
        
        do {
            try await useCase.execute(settings: settings)
            XCTFail("Expected validation error for text size above maximum")
        } catch SettingsError.invalidTextSize {
            // Expected error
            XCTAssertEqual(mockRepository.saveCallCount, 0)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testExecuteWithTextSizeNotMultipleOfTen() async {
        let settings = UserSettings(biometricAuthEnabled: false, textSizePercentage: 95)
        
        do {
            try await useCase.execute(settings: settings)
            XCTFail("Expected validation error for text size not multiple of 10")
        } catch SettingsError.invalidTextSize {
            // Expected error
            XCTAssertEqual(mockRepository.saveCallCount, 0)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testExecuteWithRepositoryError() async {
        let settings = UserSettings(biometricAuthEnabled: true, textSizePercentage: 100)
        mockRepository.shouldThrowError = true
        
        do {
            try await useCase.execute(settings: settings)
            XCTFail("Expected repository error to be propagated")
        } catch MockSettingsRepository.MockError.saveError {
            // Expected error
            XCTAssertEqual(mockRepository.saveCallCount, 1)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}

// MARK: - Mock Settings Repository

class MockSettingsRepository: SettingsRepository {
    
    enum MockError: Error, Equatable {
        case saveError
        case loadError
    }
    
    var shouldThrowError = false
    var saveCallCount = 0
    var loadCallCount = 0
    var lastSavedSettings: UserSettings?
    var settingsToReturn: UserSettings?
    
    func save(_ settings: UserSettings) async throws {
        saveCallCount += 1
        lastSavedSettings = settings
        
        if shouldThrowError {
            throw MockError.saveError
        }
    }
    
    func get() async throws -> UserSettings {
        loadCallCount += 1
        
        if shouldThrowError {
            throw MockError.loadError
        }
        
        return settingsToReturn ?? UserSettings()
    }
}