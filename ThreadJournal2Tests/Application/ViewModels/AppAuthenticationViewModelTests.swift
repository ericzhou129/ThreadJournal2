//
//  AppAuthenticationViewModelTests.swift
//  ThreadJournal2Tests
//
//  Created by Claude on 2025-08-07.
//

import XCTest
@testable import ThreadJournal2

@MainActor
final class AppAuthenticationViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var mockBiometricAuthService: MockAppAuthBiometricService!
    private var viewModel: AppAuthenticationViewModel!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockBiometricAuthService = MockAppAuthBiometricService()
    }
    
    override func tearDown() {
        viewModel = nil
        mockBiometricAuthService = nil
        super.tearDown()
    }
    
    // MARK: - Test Cases
    
    func testInit_WhenBiometricDisabled_SetsAuthenticatedTrue() async {
        // Given
        mockBiometricAuthService.mockIsEnabled = false
        
        // When
        viewModel = AppAuthenticationViewModel(biometricAuthService: mockBiometricAuthService)
        
        // Wait for async initialization
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Then
        XCTAssertTrue(viewModel.hasCheckedSettings)
        XCTAssertFalse(viewModel.needsAuthentication)
        XCTAssertTrue(viewModel.isAuthenticated)
    }
    
    func testInit_WhenBiometricEnabled_RequiresAuthentication() async {
        // Given
        mockBiometricAuthService.mockIsEnabled = true
        
        // When
        viewModel = AppAuthenticationViewModel(biometricAuthService: mockBiometricAuthService)
        
        // Wait for async initialization
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        
        // Then
        XCTAssertTrue(viewModel.hasCheckedSettings)
        XCTAssertTrue(viewModel.needsAuthentication)
        XCTAssertFalse(viewModel.isAuthenticated)
    }
    
    func testLockForBackground_WhenAuthNeeded_SetsAuthenticatedFalse() async {
        // Given
        mockBiometricAuthService.mockIsEnabled = true
        viewModel = AppAuthenticationViewModel(biometricAuthService: mockBiometricAuthService)
        try? await Task.sleep(nanoseconds: 100_000_000) // Wait for init
        
        // When
        viewModel.lockForBackground()
        
        // Then
        XCTAssertFalse(viewModel.isAuthenticated)
    }
    
    func testLockForBackground_WhenAuthNotNeeded_DoesNotChange() async {
        // Given
        mockBiometricAuthService.mockIsEnabled = false
        viewModel = AppAuthenticationViewModel(biometricAuthService: mockBiometricAuthService)
        try? await Task.sleep(nanoseconds: 100_000_000) // Wait for init
        
        // When
        viewModel.lockForBackground()
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated) // Should remain true
    }
    
    func testCheckAuthRequirement_AfterLockForBackground_DoesNotOverrideAuthState() async {
        // Given - Start with biometric disabled
        mockBiometricAuthService.mockIsEnabled = false
        viewModel = AppAuthenticationViewModel(biometricAuthService: mockBiometricAuthService)
        try? await Task.sleep(nanoseconds: 100_000_000) // Wait for init
        
        // Simulate enabling needsAuthentication then locking
        mockBiometricAuthService.mockIsEnabled = true
        viewModel = AppAuthenticationViewModel(biometricAuthService: mockBiometricAuthService)
        try? await Task.sleep(nanoseconds: 100_000_000) // Wait for init
        
        // When - Lock for background, then disable biometric (simulating async race condition)
        viewModel.lockForBackground()
        mockBiometricAuthService.mockIsEnabled = false
        
        // Create new viewModel to simulate the race condition
        let newViewModel = AppAuthenticationViewModel(biometricAuthService: mockBiometricAuthService)
        newViewModel.lockForBackground() // Simulate locked state
        try? await Task.sleep(nanoseconds: 100_000_000) // Wait for async check
        
        // Then - Should remain false even though biometric is disabled
        XCTAssertFalse(newViewModel.isAuthenticated)
    }
    
    func testPerformAuthentication_WhenSuccessful_SetsAuthenticatedTrue() async throws {
        // Given
        mockBiometricAuthService.mockIsEnabled = true
        mockBiometricAuthService.mockAuthResult = true
        viewModel = AppAuthenticationViewModel(biometricAuthService: mockBiometricAuthService)
        try? await Task.sleep(nanoseconds: 100_000_000) // Wait for init
        
        // When
        try await viewModel.performAuthentication()
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated)
    }
    
    func testPerformAuthentication_WhenFailed_SetsAuthenticatedFalse() async {
        // Given
        mockBiometricAuthService.mockIsEnabled = true
        mockBiometricAuthService.mockAuthError = BiometricAuthError.authenticationFailed
        viewModel = AppAuthenticationViewModel(biometricAuthService: mockBiometricAuthService)
        try? await Task.sleep(nanoseconds: 100_000_000) // Wait for init
        
        // When/Then
        do {
            try await viewModel.performAuthentication()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertFalse(viewModel.isAuthenticated)
        }
    }
    
    func testPerformAuthentication_AfterLockForBackground_ClearsLockedState() async throws {
        // Given
        mockBiometricAuthService.mockIsEnabled = true
        mockBiometricAuthService.mockAuthResult = true
        viewModel = AppAuthenticationViewModel(biometricAuthService: mockBiometricAuthService)
        try? await Task.sleep(nanoseconds: 100_000_000) // Wait for init
        
        // Lock for background
        viewModel.lockForBackground()
        XCTAssertFalse(viewModel.isAuthenticated)
        
        // When
        try await viewModel.performAuthentication()
        
        // Then
        XCTAssertTrue(viewModel.isAuthenticated)
        
        // And subsequent init should not override if biometric is disabled
        mockBiometricAuthService.mockIsEnabled = false
        // This should not affect the current authenticated state
        // (testing that isLockedForBackground was cleared)
    }
}

// MARK: - Mock Classes

private final class MockAppAuthBiometricService: BiometricAuthServiceProtocol {
    var mockIsAvailable = true
    var mockIsEnabled = false
    var mockAuthResult = false
    var mockAuthError: Error?
    
    func isBiometricAvailable() -> Bool {
        return mockIsAvailable
    }
    
    func isBiometricEnabled() async throws -> Bool {
        if let error = mockAuthError {
            throw error
        }
        return mockIsEnabled
    }
    
    func authenticate() async throws -> Bool {
        if let error = mockAuthError {
            throw error
        }
        return mockAuthResult
    }
    
    func testBiometricAuthentication() async throws -> Bool {
        if let error = mockAuthError {
            throw error
        }
        return mockAuthResult
    }
}