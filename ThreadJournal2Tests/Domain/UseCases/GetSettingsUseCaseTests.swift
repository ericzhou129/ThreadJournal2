//
//  GetSettingsUseCaseTests.swift
//  ThreadJournal2Tests
//
//  Created by Claude on 2025-08-06.
//

import XCTest
@testable import ThreadJournal2

final class GetSettingsUseCaseTests: XCTestCase {
    
    private var mockRepository: MockSettingsRepository!
    private var useCase: GetSettingsUseCaseImpl!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockSettingsRepository()
        useCase = GetSettingsUseCaseImpl(repository: mockRepository)
    }
    
    override func tearDown() {
        mockRepository = nil
        useCase = nil
        super.tearDown()
    }
    
    // MARK: - Success Cases
    
    func testExecuteReturnsSettingsFromRepository() async throws {
        let expectedSettings = UserSettings(biometricAuthEnabled: true, textSizePercentage: 110)
        mockRepository.settingsToReturn = expectedSettings
        
        let actualSettings = try await useCase.execute()
        
        XCTAssertEqual(mockRepository.loadCallCount, 1)
        XCTAssertEqual(actualSettings, expectedSettings)
    }
    
    func testExecuteReturnsDefaultSettingsWhenNoSettingsExist() async throws {
        mockRepository.settingsToReturn = UserSettings() // Default settings
        
        let actualSettings = try await useCase.execute()
        
        XCTAssertEqual(mockRepository.loadCallCount, 1)
        XCTAssertFalse(actualSettings.biometricAuthEnabled)
        XCTAssertEqual(actualSettings.textSizePercentage, 100)
    }
    
    func testExecuteWithCustomSettings() async throws {
        let expectedSettings = UserSettings(biometricAuthEnabled: false, textSizePercentage: 130)
        mockRepository.settingsToReturn = expectedSettings
        
        let actualSettings = try await useCase.execute()
        
        XCTAssertEqual(mockRepository.loadCallCount, 1)
        XCTAssertEqual(actualSettings, expectedSettings)
    }
    
    // MARK: - Error Handling Tests
    
    func testExecuteWithRepositoryError() async {
        mockRepository.shouldThrowError = true
        
        do {
            _ = try await useCase.execute()
            XCTFail("Expected repository error to be propagated")
        } catch MockSettingsRepository.MockError.loadError {
            // Expected error
            XCTAssertEqual(mockRepository.loadCallCount, 1)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Business Logic Tests
    
    func testExecuteDoesNotModifyReturnedSettings() async throws {
        let originalSettings = UserSettings(biometricAuthEnabled: true, textSizePercentage: 120)
        mockRepository.settingsToReturn = originalSettings
        
        let returnedSettings = try await useCase.execute()
        
        // Verify the use case doesn't have any side effects
        XCTAssertEqual(returnedSettings, originalSettings)
        XCTAssertEqual(mockRepository.saveCallCount, 0) // Should not save
        XCTAssertEqual(mockRepository.loadCallCount, 1) // Should only load once
    }
}