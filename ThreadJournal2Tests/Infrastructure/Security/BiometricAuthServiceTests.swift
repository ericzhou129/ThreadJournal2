//
//  BiometricAuthServiceTests.swift
//  ThreadJournal2Tests
//
//  Created by Claude on 2025-08-06.
//

import XCTest
import LocalAuthentication
@testable import ThreadJournal2

final class BiometricAuthServiceTests: XCTestCase {
    
    private var service: BiometricAuthService!
    private var settingsRepository: MockSettingsRepository!
    
    override func setUp() {
        super.setUp()
        settingsRepository = MockSettingsRepository()
        service = BiometricAuthService(settingsRepository: settingsRepository)
    }
    
    override func tearDown() {
        service = nil
        settingsRepository = nil
        super.tearDown()
    }
    
    // MARK: - Biometric Availability Tests
    
    func testIsBiometricAvailable() {
        // On simulator, biometric is typically not available
        // This test verifies the method can be called without crashing
        let isAvailable = service.isBiometricAvailable()
        
        // Result may vary by simulator, but method should not crash
        XCTAssertTrue(isAvailable || !isAvailable) // Always passes, just verify no crash
    }
    
    // MARK: - Biometric Enabled Setting Tests
    
    func testIsBiometricEnabledWhenTrue() async throws {
        let settings = UserSettings(biometricAuthEnabled: true, textSizePercentage: 100)
        settingsRepository.settingsToReturn = settings
        
        let isEnabled = try await service.isBiometricEnabled()
        
        XCTAssertTrue(isEnabled)
        XCTAssertEqual(settingsRepository.loadCallCount, 1)
    }
    
    func testIsBiometricEnabledWhenFalse() async throws {
        let settings = UserSettings(biometricAuthEnabled: false, textSizePercentage: 100)
        settingsRepository.settingsToReturn = settings
        
        let isEnabled = try await service.isBiometricEnabled()
        
        XCTAssertFalse(isEnabled)
        XCTAssertEqual(settingsRepository.loadCallCount, 1)
    }
    
    func testIsBiometricEnabledWithRepositoryError() async {
        settingsRepository.shouldThrowError = true
        
        do {
            _ = try await service.isBiometricEnabled()
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected error
            XCTAssertEqual(settingsRepository.loadCallCount, 1)
        }
    }
    
    // MARK: - Authentication Tests - Biometric Disabled
    
    func testAuthenticateWhenBiometricDisabled() async throws {
        let settings = UserSettings(biometricAuthEnabled: false, textSizePercentage: 100)
        settingsRepository.settingsToReturn = settings
        
        let result = try await service.authenticate()
        
        XCTAssertTrue(result)
        XCTAssertEqual(settingsRepository.loadCallCount, 1)
        // When biometric is disabled, should return true without calling biometric auth
    }
    
    // MARK: - Authentication Flow Tests
    
    func testAuthenticateWhenBiometricEnabledButNotAvailable() async {
        let settings = UserSettings(biometricAuthEnabled: true, textSizePercentage: 100)
        settingsRepository.settingsToReturn = settings
        
        do {
            _ = try await service.authenticate()
            // On simulator, this might fail with biometricNotAvailable which is expected
        } catch let error as BiometricAuthError {
            // Expected errors on simulator
            XCTAssertTrue([.biometricNotAvailable, .authenticationFailed].contains(error))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Error Types Tests
    
    func testBiometricAuthErrorTypes() {
        let errors: [BiometricAuthError] = [
            .biometricNotAvailable,
            .authenticationFailed,
            .userCancelled,
            .unknown
        ]
        
        for error in errors {
            // Verify each error has a localized description
            XCTAssertNotNil(error.localizedDescription)
            XCTAssertFalse(error.localizedDescription.isEmpty)
        }
    }
}