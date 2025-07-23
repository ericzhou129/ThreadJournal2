//
//  LongPressContextMenuTests.swift
//  ThreadJournal2UITests
//
//  UI tests for long press context menu functionality
//

import XCTest

final class LongPressContextMenuTests: XCTestCase {
    
    private var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testLongPressShowsContextMenu() throws {
        // Given: A thread with an entry exists
        // First create a thread
        let addButton = app.buttons["Add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()
        
        let titleField = app.textFields["Thread Title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("Test Thread")
        
        let createButton = app.buttons["Create Thread"]
        createButton.tap()
        
        // Wait for thread detail view
        let composeArea = app.textViews.firstMatch
        XCTAssertTrue(composeArea.waitForExistence(timeout: 5))
        
        // Add an entry
        composeArea.tap()
        composeArea.typeText("Test entry for context menu")
        
        let sendButton = app.buttons["Send"]
        sendButton.tap()
        
        // When: Long press on the entry
        let entryText = app.staticTexts["Test entry for context menu"]
        XCTAssertTrue(entryText.waitForExistence(timeout: 5))
        
        // Perform long press (press and hold for 0.5 seconds)
        entryText.press(forDuration: 0.6)
        
        // Then: Context menu should appear with Edit and Delete options
        let editButton = app.buttons["Edit"]
        let deleteButton = app.buttons["Delete"]
        
        XCTAssertTrue(editButton.waitForExistence(timeout: 2))
        XCTAssertTrue(deleteButton.exists)
        
        // Verify the buttons have correct labels
        XCTAssertEqual(editButton.label, "Edit")
        XCTAssertEqual(deleteButton.label, "Delete")
    }
    
    func testContextMenuDismissesOnTapOutside() throws {
        // Given: A thread with an entry exists
        let addButton = app.buttons["Add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()
        
        let titleField = app.textFields["Thread Title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("Test Thread 2")
        
        let createButton = app.buttons["Create Thread"]
        createButton.tap()
        
        // Add an entry
        let composeArea = app.textViews.firstMatch
        XCTAssertTrue(composeArea.waitForExistence(timeout: 5))
        composeArea.tap()
        composeArea.typeText("Test entry for dismissal")
        
        let sendButton = app.buttons["Send"]
        sendButton.tap()
        
        // When: Long press to show context menu
        let entryText = app.staticTexts["Test entry for dismissal"]
        XCTAssertTrue(entryText.waitForExistence(timeout: 5))
        entryText.press(forDuration: 0.6)
        
        // Verify menu appears
        let editButton = app.buttons["Edit"]
        XCTAssertTrue(editButton.waitForExistence(timeout: 2))
        
        // Tap outside to dismiss
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
        
        // Then: Context menu should be dismissed
        XCTAssertFalse(editButton.waitForExistence(timeout: 1))
    }
    
    func testDeleteButtonShowsConfirmationDialog() throws {
        // Given: A thread with an entry exists
        let addButton = app.buttons["Add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()
        
        let titleField = app.textFields["Thread Title"]
        XCTAssertTrue(titleField.waitForExistence(timeout: 5))
        titleField.tap()
        titleField.typeText("Test Thread 3")
        
        let createButton = app.buttons["Create Thread"]
        createButton.tap()
        
        // Add an entry
        let composeArea = app.textViews.firstMatch
        XCTAssertTrue(composeArea.waitForExistence(timeout: 5))
        composeArea.tap()
        composeArea.typeText("Entry to delete")
        
        let sendButton = app.buttons["Send"]
        sendButton.tap()
        
        // When: Long press and tap Delete
        let entryText = app.staticTexts["Entry to delete"]
        XCTAssertTrue(entryText.waitForExistence(timeout: 5))
        entryText.press(forDuration: 0.6)
        
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 2))
        deleteButton.tap()
        
        // Then: Confirmation dialog should appear
        let alert = app.alerts["Delete Entry?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 2))
        
        // Verify dialog message
        let message = alert.staticTexts["This entry will be removed from your journal."]
        XCTAssertTrue(message.exists)
        
        // Verify buttons
        XCTAssertTrue(alert.buttons["Cancel"].exists)
        XCTAssertTrue(alert.buttons["Delete"].exists)
        
        // Cancel for now
        alert.buttons["Cancel"].tap()
        
        // Entry should still exist
        XCTAssertTrue(entryText.exists)
    }
}