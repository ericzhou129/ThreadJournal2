//
//  ThreadJournal2UITests.swift
//  ThreadJournal2UITests
//
//  Created by Eric Zhou on 2025-07-17.
//

import XCTest

final class ThreadJournal2UITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Thread Management Tests
    
    @MainActor
    func testCreateNewThread() throws {
        let addButton = app.navigationBars.buttons["Add"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()
        
        let threadNameField = app.textFields.firstMatch
        XCTAssertTrue(threadNameField.waitForExistence(timeout: 3))
        threadNameField.tap()
        threadNameField.typeText("Test Thread")
        
        let createButton = app.buttons["Create"]
        XCTAssertTrue(createButton.exists)
        createButton.tap()
        
        let createdThread = app.collectionViews.staticTexts["Test Thread"]
        XCTAssertTrue(createdThread.waitForExistence(timeout: 5))
    }
    
    @MainActor
    func testEditThreadName() throws {
        try testCreateNewThread()
        
        let thread = app.collectionViews.staticTexts["Test Thread"]
        thread.tap()
        
        let moreButton = app.navigationBars.buttons["More"]
        if moreButton.waitForExistence(timeout: 3) {
            moreButton.tap()
            
            let editButton = app.buttons["Edit Thread"]
            if editButton.waitForExistence(timeout: 2) {
                editButton.tap()
                
                let nameField = app.textFields.firstMatch
                nameField.tap()
                nameField.doubleTap()
                nameField.typeText("Updated Thread")
                
                let saveButton = app.buttons["Save"]
                saveButton.tap()
                
                XCTAssertTrue(app.navigationBars["Updated Thread"].waitForExistence(timeout: 3))
            }
        }
    }
    
    @MainActor
    func testDeleteThread() throws {
        try testCreateNewThread()
        
        let thread = app.collectionViews.cells.firstMatch
        thread.swipeLeft()
        
        let deleteButton = app.buttons["Delete"]
        if deleteButton.waitForExistence(timeout: 3) {
            deleteButton.tap()
            
            let confirmButton = app.alerts.buttons["Delete"]
            if confirmButton.waitForExistence(timeout: 2) {
                confirmButton.tap()
            }
            
            let deletedThread = app.collectionViews.staticTexts["Test Thread"]
            XCTAssertFalse(deletedThread.exists)
        }
    }
    
    // MARK: - Entry Creation Tests
    
    @MainActor
    func testCreateTextEntry() throws {
        try testCreateNewThread()
        
        let thread = app.collectionViews.staticTexts["Test Thread"]
        thread.tap()
        
        let addEntryButton = app.buttons["plus.circle.fill"]
        if !addEntryButton.exists {
            let floatingButton = app.buttons.matching(identifier: "AddEntryButton").firstMatch
            if floatingButton.waitForExistence(timeout: 3) {
                floatingButton.tap()
            }
        } else {
            addEntryButton.tap()
        }
        
        let textEditor = app.textViews.firstMatch
        if textEditor.waitForExistence(timeout: 3) {
            textEditor.tap()
            textEditor.typeText("This is a test entry with some content.")
            
            let saveButton = app.navigationBars.buttons["Save"]
            if saveButton.exists {
                saveButton.tap()
            }
            
            let savedEntry = app.collectionViews.staticTexts["This is a test entry"]
            XCTAssertTrue(savedEntry.waitForExistence(timeout: 5))
        }
    }
    
    // MARK: - Voice Entry Tests
    
    @MainActor
    func testVoiceRecording() throws {
        try testCreateNewThread()
        
        let thread = app.collectionViews.staticTexts["Test Thread"]
        thread.tap()
        
        let voiceButton = app.buttons["mic.circle.fill"]
        if !voiceButton.exists {
            let alternativeVoiceButton = app.buttons.matching(identifier: "VoiceRecordButton").firstMatch
            if alternativeVoiceButton.waitForExistence(timeout: 3) {
                alternativeVoiceButton.tap()
            }
        } else {
            voiceButton.tap()
        }
        
        let recordButton = app.buttons["Record"]
        if !recordButton.exists {
            let micButton = app.buttons["mic.fill"]
            if micButton.waitForExistence(timeout: 3) {
                micButton.tap()
                
                Thread.sleep(forTimeInterval: 2)
                
                let stopButton = app.buttons["stop.fill"]
                if stopButton.exists {
                    stopButton.tap()
                }
                
                let saveButton = app.buttons["Save"]
                if saveButton.waitForExistence(timeout: 2) {
                    saveButton.tap()
                }
            }
        }
    }
    
    @MainActor
    func testVoiceRecordingPauseResume() throws {
        try testCreateNewThread()
        
        let thread = app.collectionViews.staticTexts["Test Thread"]
        thread.tap()
        
        let voiceButton = app.buttons.matching(identifier: "VoiceRecordButton").firstMatch
        if voiceButton.waitForExistence(timeout: 3) {
            voiceButton.tap()
            
            let micButton = app.buttons["mic.fill"]
            if micButton.waitForExistence(timeout: 3) {
                micButton.tap()
                
                Thread.sleep(forTimeInterval: 1)
                
                let pauseButton = app.buttons["pause.fill"]
                if pauseButton.waitForExistence(timeout: 2) {
                    pauseButton.tap()
                    
                    let resumeButton = app.buttons["play.fill"]
                    XCTAssertTrue(resumeButton.waitForExistence(timeout: 2))
                    resumeButton.tap()
                    
                    Thread.sleep(forTimeInterval: 1)
                    
                    let stopButton = app.buttons["stop.fill"]
                    stopButton.tap()
                }
            }
        }
    }
    
    // MARK: - Search Tests
    
    @MainActor
    func testSearchFunctionality() throws {
        try testCreateTextEntry()
        
        app.navigationBars.buttons["Back"].tap()
        
        let searchField = app.searchFields.firstMatch
        if searchField.waitForExistence(timeout: 3) {
            searchField.tap()
            searchField.typeText("test entry")
            
            let searchResults = app.collectionViews.staticTexts["This is a test entry"]
            XCTAssertTrue(searchResults.waitForExistence(timeout: 3))
            
            searchField.buttons["Clear text"].tap()
            searchField.typeText("nonexistent")
            
            Thread.sleep(forTimeInterval: 1)
            
            let noResults = app.staticTexts["No results found"]
            XCTAssertTrue(noResults.exists || app.collectionViews.cells.count == 0)
        }
    }
    
    // MARK: - Settings Tests
    
    @MainActor
    func testSettingsAccess() throws {
        let settingsButton = app.navigationBars.buttons["gearshape"]
        if !settingsButton.exists {
            let alternativeSettings = app.buttons["Settings"]
            if alternativeSettings.waitForExistence(timeout: 3) {
                alternativeSettings.tap()
            }
        } else {
            settingsButton.tap()
        }
        
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        
        let privacyOption = app.cells.staticTexts["Privacy & Security"]
        if privacyOption.exists {
            privacyOption.tap()
            XCTAssertTrue(app.navigationBars["Privacy & Security"].waitForExistence(timeout: 3))
            app.navigationBars.buttons["Settings"].tap()
        }
        
        app.navigationBars.buttons["Done"].tap()
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    @MainActor
    func testScrollingPerformance() throws {
        try testCreateTextEntry()
        
        measure {
            let collectionView = app.collectionViews.firstMatch
            collectionView.swipeUp()
            collectionView.swipeDown()
        }
    }
}