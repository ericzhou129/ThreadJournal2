//
//  VoiceRecordButtonTests.swift
//  ThreadJournal2Tests
//
//  Unit tests for VoiceRecordButton component
//

import XCTest
import SwiftUI
@testable import ThreadJournal2

final class VoiceRecordButtonTests: XCTestCase {
    
    func testVoiceRecordButtonActionTriggered() {
        // Given
        var actionTriggered = false
        let button = VoiceRecordButton {
            actionTriggered = true
        }
        
        // When
        // Note: In a real UI test, this would simulate a button tap
        // For unit tests, we verify the button was created with the action
        XCTAssertNotNil(button)
        
        // Then
        // Call the action to verify it's properly captured
        button.action()
        XCTAssertTrue(actionTriggered, "Button action should be triggered")
    }
    
    func testVoiceRecordButtonHasCorrectAppearance() {
        // Given
        let button = VoiceRecordButton {
            // Empty action for testing
        }
        
        // When/Then
        // Verify button is created successfully
        XCTAssertNotNil(button)
        
        // Note: SwiftUI View testing is limited in unit tests
        // Full UI verification would require UI tests or ViewInspector
    }
    
    func testVoiceRecordButtonInitialization() {
        // Given/When
        let button = VoiceRecordButton {
            print("Test action")
        }
        
        // Then
        XCTAssertNotNil(button)
        
        // Test that action closure is properly stored
        // by creating a button with a counting action
        var callCount = 0
        let countingButton = VoiceRecordButton {
            callCount += 1
        }
        
        // Call action multiple times
        countingButton.action()
        countingButton.action()
        
        XCTAssertEqual(callCount, 2, "Action should be callable multiple times")
    }
    
    func testVoiceRecordButtonActionRetainsCorrectBehavior() {
        // Given
        var result = "initial"
        let button = VoiceRecordButton {
            result = "action_executed"
        }
        
        // When
        button.action()
        
        // Then
        XCTAssertEqual(result, "action_executed", "Button action should modify captured variables")
    }
}