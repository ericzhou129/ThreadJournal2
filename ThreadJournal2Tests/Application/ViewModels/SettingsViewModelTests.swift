//
//  SettingsViewModelTests.swift
//  ThreadJournal2Tests
//
//  Created by Claude on 2025-08-06.
//

import XCTest
@testable import ThreadJournal2

@MainActor
final class SettingsViewModelTests: XCTestCase {
    
    // MARK: - Test Dependencies
    
    private var viewModel: SettingsViewModel!
    private var mockGetSettingsUseCase: MockGetSettingsUseCase!
    private var mockUpdateSettingsUseCase: MockUpdateSettingsUseCase!
    private var mockBiometricAuthService: MockBiometricAuthService!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockGetSettingsUseCase = MockGetSettingsUseCase()
        mockUpdateSettingsUseCase = MockUpdateSettingsUseCase()
        mockBiometricAuthService = MockBiometricAuthService()
        
        viewModel = SettingsViewModel(
            getSettingsUseCase: mockGetSettingsUseCase,
            updateSettingsUseCase: mockUpdateSettingsUseCase,
            biometricAuthService: mockBiometricAuthService
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockGetSettingsUseCase = nil
        mockUpdateSettingsUseCase = nil
        mockBiometricAuthService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_LoadsSettingsOnInit() async {
        // Given
        let expectedSettings = UserSettings(biometricAuthEnabled: true, textSizePercentage: 120)
        mockGetSettingsUseCase.mockSettings = expectedSettings
        
        // When
        let newViewModel = SettingsViewModel(
            getSettingsUseCase: mockGetSettingsUseCase,
            updateSettingsUseCase: mockUpdateSettingsUseCase,
            biometricAuthService: mockBiometricAuthService
        )
        
        // Wait for async initialization
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        XCTAssertEqual(newViewModel.biometricAuthEnabled, true)
        XCTAssertEqual(newViewModel.textSizePercentage, 120)
        XCTAssertEqual(mockGetSettingsUseCase.executeCallCount, 1)
    }
    
    func testInitialization_HandlesSettingsLoadError() async {
        // Given
        mockGetSettingsUseCase.mockError = SettingsError.persistenceError
        
        // When
        let newViewModel = SettingsViewModel(
            getSettingsUseCase: mockGetSettingsUseCase,
            updateSettingsUseCase: mockUpdateSettingsUseCase,
            biometricAuthService: mockBiometricAuthService
        )
        
        // Wait for async initialization
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then - should use default values
        XCTAssertEqual(newViewModel.biometricAuthEnabled, false)
        XCTAssertEqual(newViewModel.textSizePercentage, 100)
        XCTAssertTrue(newViewModel.errorMessage.isEmpty)
    }
    
    // MARK: - Biometric Authentication Tests
    
    func testToggleBiometric_EnablesWhenAvailable() async {
        // Given
        mockBiometricAuthService.isBiometricAvailableResult = true
        viewModel.biometricAuthEnabled = false
        
        // When
        await viewModel.toggleBiometric()
        
        // Then
        XCTAssertTrue(viewModel.biometricAuthEnabled)
        XCTAssertEqual(mockUpdateSettingsUseCase.saveCallCount, 1)
        XCTAssertEqual(mockUpdateSettingsUseCase.lastSavedSettings?.biometricAuthEnabled, true)
    }
    
    func testToggleBiometric_DisablesWhenEnabled() async {
        // Given
        mockBiometricAuthService.isBiometricAvailableResult = true
        viewModel.biometricAuthEnabled = true
        
        // When
        await viewModel.toggleBiometric()
        
        // Then
        XCTAssertFalse(viewModel.biometricAuthEnabled)
        XCTAssertEqual(mockUpdateSettingsUseCase.saveCallCount, 1)
        XCTAssertEqual(mockUpdateSettingsUseCase.lastSavedSettings?.biometricAuthEnabled, false)
    }
    
    func testToggleBiometric_ShowsErrorWhenNotAvailable() async {
        // Given
        mockBiometricAuthService.isBiometricAvailableResult = false
        viewModel.biometricAuthEnabled = false
        
        // When
        await viewModel.toggleBiometric()
        
        // Then
        XCTAssertFalse(viewModel.biometricAuthEnabled) // Should remain unchanged
        XCTAssertFalse(viewModel.errorMessage.isEmpty)
        XCTAssertEqual(mockUpdateSettingsUseCase.saveCallCount, 0) // Should not save
    }
    
    // MARK: - Text Size Tests
    
    func testUpdateTextSize_ValidPercentage() async {
        // Given
        let validSize = 120
        
        // When
        await viewModel.updateTextSize(validSize)
        
        // Then
        XCTAssertEqual(viewModel.textSizePercentage, validSize)
        XCTAssertEqual(mockUpdateSettingsUseCase.saveCallCount, 1)
        XCTAssertEqual(mockUpdateSettingsUseCase.lastSavedSettings?.textSizePercentage, validSize)
    }
    
    func testUpdateTextSize_ClampsToMinimum() async {
        // Given
        let belowMin = 70
        
        // When
        await viewModel.updateTextSize(belowMin)
        
        // Then
        XCTAssertEqual(viewModel.textSizePercentage, 80) // Clamped to minimum
        XCTAssertEqual(mockUpdateSettingsUseCase.lastSavedSettings?.textSizePercentage, 80)
    }
    
    func testUpdateTextSize_ClampsToMaximum() async {
        // Given
        let aboveMax = 200
        
        // When
        await viewModel.updateTextSize(aboveMax)
        
        // Then
        XCTAssertEqual(viewModel.textSizePercentage, 150) // Clamped to maximum
        XCTAssertEqual(mockUpdateSettingsUseCase.lastSavedSettings?.textSizePercentage, 150)
    }
    
    // MARK: - Error Handling Tests
    
    func testSaveSettings_HandlesUpdateError() async {
        // Given
        mockUpdateSettingsUseCase.mockError = SettingsError.persistenceError
        
        // When
        await viewModel.updateTextSize(110)
        
        // Then
        XCTAssertFalse(viewModel.errorMessage.isEmpty)
        XCTAssertTrue(viewModel.errorMessage.contains("save"))
    }
    
    func testClearError_ResetsErrorMessage() {
        // Given
        viewModel.errorMessage = "Test error"
        
        // When
        viewModel.clearError()
        
        // Then
        XCTAssertTrue(viewModel.errorMessage.isEmpty)
    }
    
    // MARK: - Privacy Policy Tests
    
    func testShowPrivacyPolicy_TogglesFlag() {
        // Given
        XCTAssertFalse(viewModel.showingPrivacyPolicy)
        
        // When
        viewModel.showPrivacyPolicy()
        
        // Then
        XCTAssertTrue(viewModel.showingPrivacyPolicy)
    }
    
    func testHidePrivacyPolicy_TogglesFlag() {
        // Given
        viewModel.showingPrivacyPolicy = true
        
        // When
        viewModel.hidePrivacyPolicy()
        
        // Then
        XCTAssertFalse(viewModel.showingPrivacyPolicy)
    }
}

// MARK: - Mock GetSettingsUseCase

private final class MockGetSettingsUseCase: GetSettingsUseCase {
    var executeCallCount = 0
    var mockSettings = UserSettings() // Default settings
    var mockError: SettingsError?
    
    func execute() async throws -> UserSettings {
        executeCallCount += 1
        
        if let error = mockError {
            throw error
        }
        
        return mockSettings
    }
}

// MARK: - Mock UpdateSettingsUseCase

private final class MockUpdateSettingsUseCase: UpdateSettingsUseCase {
    var saveCallCount = 0
    var lastSavedSettings: UserSettings?
    var mockError: SettingsError?
    
    func execute(settings: UserSettings) async throws {
        saveCallCount += 1
        lastSavedSettings = settings
        
        if let error = mockError {
            throw error
        }
    }
}

// MARK: - Mock BiometricAuthService

private final class MockBiometricAuthService: BiometricAuthServiceProtocol {
    var isBiometricAvailableResult = true
    var isBiometricEnabledResult = false
    var authenticateResult = true
    var authenticateError: Error?
    
    func isBiometricAvailable() -> Bool {
        return isBiometricAvailableResult
    }
    
    func isBiometricEnabled() async throws -> Bool {
        return isBiometricEnabledResult
    }
    
    func authenticate() async throws -> Bool {
        if let error = authenticateError {
            throw error
        }
        return authenticateResult
    }
    
    func testBiometricAuthentication() async throws -> Bool {
        if let error = authenticateError {
            throw error
        }
        return authenticateResult
    }
}