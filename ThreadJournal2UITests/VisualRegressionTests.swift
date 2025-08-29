//
//  VisualRegressionTests.swift
//  ThreadJournal2UITests
//
//  Visual regression and screenshot tests
//

import XCTest

final class VisualRegressionTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--screenshots"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Screenshot Tests
    
    @MainActor
    func testMainScreenScreenshot() throws {
        Thread.sleep(forTimeInterval: 2)
        
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Main_Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testThreadDetailScreenshot() throws {
        createSampleThread()
        
        let thread = app.collectionViews.staticTexts["Sample Thread"]
        thread.tap()
        
        Thread.sleep(forTimeInterval: 1)
        
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Thread_Detail_View"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testVoiceRecordingScreenshot() throws {
        createSampleThread()
        
        let thread = app.collectionViews.staticTexts["Sample Thread"]
        thread.tap()
        
        let voiceButton = findVoiceButton()
        voiceButton?.tap()
        
        Thread.sleep(forTimeInterval: 1)
        
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Voice_Recording_Interface"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testSettingsScreenshot() throws {
        navigateToSettings()
        
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Settings_Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Dynamic Type Tests
    
    @MainActor
    func testDynamicTypeLarge() throws {
        app.terminate()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXL"]
        app.launch()
        
        Thread.sleep(forTimeInterval: 2)
        
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Dynamic_Type_Extra_Large"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    @MainActor
    func testDynamicTypeSmall() throws {
        app.terminate()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryS"]
        app.launch()
        
        Thread.sleep(forTimeInterval: 2)
        
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Dynamic_Type_Small"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Dark Mode Tests
    
    @MainActor
    func testDarkModeInterface() throws {
        app.terminate()
        app.launchArguments += ["-UIUserInterfaceStyle", "Dark"]
        app.launch()
        
        createSampleThread()
        
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Dark_Mode_Thread_List"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        let thread = app.collectionViews.staticTexts["Sample Thread"]
        thread.tap()
        
        Thread.sleep(forTimeInterval: 1)
        
        let detailScreenshot = app.screenshot()
        let detailAttachment = XCTAttachment(screenshot: detailScreenshot)
        detailAttachment.name = "Dark_Mode_Thread_Detail"
        detailAttachment.lifetime = .keepAlways
        add(detailAttachment)
    }
    
    // MARK: - Helper Methods
    
    private func createSampleThread() {
        let addButton = app.navigationBars.buttons["Add"]
        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
            
            let threadNameField = app.textFields.firstMatch
            if threadNameField.waitForExistence(timeout: 2) {
                threadNameField.tap()
                threadNameField.typeText("Sample Thread")
                
                let createButton = app.buttons["Create"]
                createButton.tap()
                
                Thread.sleep(forTimeInterval: 1)
            }
        }
    }
    
    private func findVoiceButton() -> XCUIElement? {
        let voiceButton = app.buttons["mic.circle.fill"]
        if voiceButton.exists {
            return voiceButton
        }
        
        let alternativeButton = app.buttons.matching(identifier: "VoiceRecordButton").firstMatch
        if alternativeButton.exists {
            return alternativeButton
        }
        
        return nil
    }
    
    private func navigateToSettings() {
        let settingsButton = app.navigationBars.buttons["gearshape"]
        if settingsButton.exists {
            settingsButton.tap()
        } else {
            let alternativeSettings = app.buttons["Settings"]
            if alternativeSettings.waitForExistence(timeout: 3) {
                alternativeSettings.tap()
            }
        }
    }
}