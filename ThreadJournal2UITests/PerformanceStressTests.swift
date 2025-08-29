//
//  PerformanceStressTests.swift
//  ThreadJournal2UITests
//
//  Performance and stress tests for ThreadJournal2
//

import XCTest

final class PerformanceStressTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--performance"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - 100 Threads Stress Test
    
    @MainActor
    func testCreate100Threads() throws {
        let metrics: [XCTMetric] = [
            XCTMemoryMetric(),
            XCTCPUMetric(),
            XCTStorageMetric(),
            XCTClockMetric()
        ]
        
        measure(metrics: metrics) {
            createMultipleThreads(count: 10)
        }
        
        let totalThreads = app.collectionViews.cells.count
        XCTAssertGreaterThanOrEqual(totalThreads, 10, "Should have created at least 10 threads")
        
        testScrollPerformanceWithManyThreads()
    }
    
    @MainActor
    func testHeavyThreadCreation() throws {
        for batch in 0..<10 {
            autoreleasepool {
                createMultipleThreads(count: 10, prefix: "Batch\(batch)")
            }
            
            if batch % 3 == 0 {
                testScrollPerformanceWithManyThreads()
            }
        }
        
        let finalCount = app.collectionViews.cells.count
        print("Created \(finalCount) threads total")
        
        measure {
            let collectionView = app.collectionViews.firstMatch
            collectionView.swipeUp()
            Thread.sleep(forTimeInterval: 0.5)
            collectionView.swipeUp()
            Thread.sleep(forTimeInterval: 0.5)
            collectionView.swipeDown()
            Thread.sleep(forTimeInterval: 0.5)
            collectionView.swipeDown()
        }
    }
    
    // MARK: - 1000 Entries Stress Test
    
    @MainActor
    func testCreate1000Entries() throws {
        createSampleThread(name: "Stress Test Thread")
        
        let thread = app.collectionViews.staticTexts["Stress Test Thread"]
        thread.tap()
        
        let metrics: [XCTMetric] = [
            XCTMemoryMetric(),
            XCTCPUMetric(),
            XCTStorageMetric()
        ]
        
        measure(metrics: metrics) {
            createMultipleEntries(count: 50)
        }
        
        testScrollPerformanceWithManyEntries()
    }
    
    @MainActor
    func testHeavyEntryCreation() throws {
        createSampleThread(name: "Heavy Entry Thread")
        
        let thread = app.collectionViews.staticTexts["Heavy Entry Thread"]
        thread.tap()
        
        for batch in 0..<20 {
            autoreleasepool {
                createMultipleEntries(count: 50, prefix: "Batch \(batch)")
            }
            
            if batch % 5 == 0 {
                testScrollPerformanceWithManyEntries()
            }
        }
        
        print("Created approximately 1000 entries")
        
        measure {
            let collectionView = app.collectionViews.firstMatch
            for _ in 0..<5 {
                collectionView.swipeUp()
                Thread.sleep(forTimeInterval: 0.2)
            }
            for _ in 0..<5 {
                collectionView.swipeDown()
                Thread.sleep(forTimeInterval: 0.2)
            }
        }
    }
    
    // MARK: - Mixed Load Test
    
    @MainActor
    func testMixedHeavyLoad() throws {
        for i in 0..<10 {
            createSampleThread(name: "Load Test \(i)")
            
            let thread = app.collectionViews.staticTexts["Load Test \(i)"]
            thread.tap()
            
            createMultipleEntries(count: 100, prefix: "Thread \(i)")
            
            app.navigationBars.buttons.firstMatch.tap()
        }
        
        testSearchPerformanceWithHeavyData()
    }
    
    // MARK: - Memory Tests
    
    @MainActor
    func testMemoryUnderLoad() throws {
        let memoryMetric = XCTMemoryMetric()
        
        measure(metrics: [memoryMetric]) {
            createSampleThread(name: "Memory Test")
            
            let thread = app.collectionViews.staticTexts["Memory Test"]
            thread.tap()
            
            for i in 0..<10 {
                let addButton = findAddButton()
                addButton?.tap()
                
                let textEditor = app.textViews.firstMatch
                if textEditor.waitForExistence(timeout: 2) {
                    textEditor.tap()
                    textEditor.typeText(generateLongText(index: i))
                    
                    let saveButton = app.navigationBars.buttons["Save"]
                    if saveButton.exists {
                        saveButton.tap()
                        Thread.sleep(forTimeInterval: 0.5)
                    }
                }
            }
            
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Search Performance
    
    @MainActor
    func testSearchPerformanceWithHeavyData() {
        let searchField = app.searchFields.firstMatch
        
        measure {
            if searchField.waitForExistence(timeout: 2) {
                searchField.tap()
                searchField.typeText("Entry")
                Thread.sleep(forTimeInterval: 1)
                
                searchField.buttons["Clear text"].tap()
                searchField.typeText("Test")
                Thread.sleep(forTimeInterval: 1)
                
                searchField.buttons["Clear text"].tap()
                searchField.typeText("Batch")
                Thread.sleep(forTimeInterval: 1)
                
                searchField.buttons["Clear text"].tap()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMultipleThreads(count: Int, prefix: String = "Thread") {
        for i in 0..<count {
            let addButton = app.navigationBars.buttons["Add"]
            if addButton.waitForExistence(timeout: 1) {
                addButton.tap()
                
                let threadNameField = app.textFields.firstMatch
                if threadNameField.waitForExistence(timeout: 1) {
                    threadNameField.tap()
                    threadNameField.typeText("\(prefix) \(i)")
                    
                    let createButton = app.buttons["Create"]
                    createButton.tap()
                    
                    Thread.sleep(forTimeInterval: 0.2)
                }
            }
        }
    }
    
    private func createMultipleEntries(count: Int, prefix: String = "Entry") {
        for i in 0..<count {
            autoreleasepool {
                let addButton = findAddButton()
                if let button = addButton {
                    button.tap()
                    
                    let textEditor = app.textViews.firstMatch
                    if textEditor.waitForExistence(timeout: 1) {
                        textEditor.tap()
                        textEditor.typeText("\(prefix) - Entry \(i): Test content for performance testing.")
                        
                        let saveButton = app.navigationBars.buttons["Save"]
                        if saveButton.exists {
                            saveButton.tap()
                            Thread.sleep(forTimeInterval: 0.1)
                        }
                    }
                }
            }
        }
    }
    
    private func createSampleThread(name: String) {
        let addButton = app.navigationBars.buttons["Add"]
        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
            
            let threadNameField = app.textFields.firstMatch
            if threadNameField.waitForExistence(timeout: 2) {
                threadNameField.tap()
                threadNameField.typeText(name)
                
                let createButton = app.buttons["Create"]
                createButton.tap()
                
                Thread.sleep(forTimeInterval: 1)
            }
        }
    }
    
    private func findAddButton() -> XCUIElement? {
        let plusButton = app.buttons["plus.circle.fill"]
        if plusButton.exists {
            return plusButton
        }
        
        let floatingButton = app.buttons.matching(identifier: "AddEntryButton").firstMatch
        if floatingButton.exists {
            return floatingButton
        }
        
        return nil
    }
    
    private func testScrollPerformanceWithManyThreads() {
        let collectionView = app.collectionViews.firstMatch
        
        measure {
            collectionView.swipeUp()
            collectionView.swipeUp()
            collectionView.swipeDown()
            collectionView.swipeDown()
        }
    }
    
    private func testScrollPerformanceWithManyEntries() {
        let collectionView = app.collectionViews.firstMatch
        
        measure {
            for _ in 0..<3 {
                collectionView.swipeUp()
                Thread.sleep(forTimeInterval: 0.3)
            }
            for _ in 0..<3 {
                collectionView.swipeDown()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }
    }
    
    private func generateLongText(index: Int) -> String {
        return """
        This is entry number \(index) with a substantial amount of text content.
        It includes multiple lines to test the performance of the text editor.
        The purpose is to ensure the app can handle large amounts of text data.
        Performance testing is crucial for maintaining a smooth user experience.
        This text continues to add more content for stress testing purposes.
        """
    }
}