//
//  UserSettingsTests.swift
//  ThreadJournal2Tests
//
//  Created by Claude on 2025-08-06.
//

import XCTest
@testable import ThreadJournal2

final class UserSettingsTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitWithDefaultValues() {
        let settings = UserSettings()
        
        XCTAssertFalse(settings.biometricAuthEnabled)
        XCTAssertEqual(settings.textSizePercentage, 100)
    }
    
    func testInitWithCustomValues() {
        let settings = UserSettings(
            biometricAuthEnabled: true,
            textSizePercentage: 120
        )
        
        XCTAssertTrue(settings.biometricAuthEnabled)
        XCTAssertEqual(settings.textSizePercentage, 120)
    }
    
    // MARK: - Value Type Tests
    
    func testUserSettingsIsValueType() {
        let original = UserSettings(biometricAuthEnabled: true, textSizePercentage: 120)
        var copy = original
        
        copy = UserSettings(biometricAuthEnabled: false, textSizePercentage: 80)
        
        XCTAssertTrue(original.biometricAuthEnabled)
        XCTAssertFalse(copy.biometricAuthEnabled)
        XCTAssertEqual(original.textSizePercentage, 120)
        XCTAssertEqual(copy.textSizePercentage, 80)
    }
    
    // MARK: - Equatable Tests
    
    func testEquatableWhenEqual() {
        let settings1 = UserSettings(biometricAuthEnabled: true, textSizePercentage: 110)
        let settings2 = UserSettings(biometricAuthEnabled: true, textSizePercentage: 110)
        
        XCTAssertEqual(settings1, settings2)
    }
    
    func testEquatableWhenNotEqual() {
        let settings1 = UserSettings(biometricAuthEnabled: true, textSizePercentage: 110)
        let settings2 = UserSettings(biometricAuthEnabled: false, textSizePercentage: 110)
        
        XCTAssertNotEqual(settings1, settings2)
    }
    
    // MARK: - Codable Tests
    
    func testCodableEncoding() throws {
        let settings = UserSettings(biometricAuthEnabled: true, textSizePercentage: 130)
        let encoder = JSONEncoder()
        
        let data = try encoder.encode(settings)
        
        XCTAssertGreaterThan(data.count, 0)
    }
    
    func testCodableDecoding() throws {
        let json = """
        {
            "biometricAuthEnabled": true,
            "textSizePercentage": 140
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let settings = try decoder.decode(UserSettings.self, from: json)
        
        XCTAssertTrue(settings.biometricAuthEnabled)
        XCTAssertEqual(settings.textSizePercentage, 140)
    }
    
    func testCodableRoundTrip() throws {
        let original = UserSettings(biometricAuthEnabled: true, textSizePercentage: 90)
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(UserSettings.self, from: data)
        
        XCTAssertEqual(original, decoded)
    }
    
    // MARK: - Text Size Range Tests
    
    func testTextSizeValidRange() {
        // Valid range 80-150
        let minSettings = UserSettings(biometricAuthEnabled: false, textSizePercentage: 80)
        let maxSettings = UserSettings(biometricAuthEnabled: false, textSizePercentage: 150)
        let midSettings = UserSettings(biometricAuthEnabled: false, textSizePercentage: 100)
        
        XCTAssertEqual(minSettings.textSizePercentage, 80)
        XCTAssertEqual(maxSettings.textSizePercentage, 150)
        XCTAssertEqual(midSettings.textSizePercentage, 100)
    }
}