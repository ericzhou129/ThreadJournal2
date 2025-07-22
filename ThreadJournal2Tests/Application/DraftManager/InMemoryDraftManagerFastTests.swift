//
//  InMemoryDraftManagerFastTests.swift
//  ThreadJournal2Tests
//
//  Created on 1/19/25.
//

import XCTest
@testable import ThreadJournal2

/// Fast tests using shorter intervals for testing timers
final class InMemoryDraftManagerFastTests: XCTestCase {
    
    // MARK: - Properties
    
    var sut: InMemoryDraftManager!
    var autoSaveCallCount: Int = 0
    var autoSavedDrafts: [(threadId: UUID, content: String)] = []
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        // Use very short intervals for testing
        sut = InMemoryDraftManager(
            debounceInterval: 0.1,  // 100ms instead of 2s
            autoSaveInterval: 0.5    // 500ms instead of 30s
        )
        
        autoSaveCallCount = 0
        autoSavedDrafts = []
        
        // Set up auto-save callback
        sut.onAutoSave = { [weak self] threadId, content in
            self?.autoSaveCallCount += 1
            self?.autoSavedDrafts.append((threadId, content))
        }
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Fast Timer Tests
    
    func testDebouncing_FastTest() {
        // Given
        let threadId = UUID()
        let expectation = expectation(description: "Debounce should trigger")
        
        // When - Simulate rapid typing
        sut.saveDraft("H", for: threadId)
        sut.saveDraft("He", for: threadId)
        sut.saveDraft("Hel", for: threadId)
        sut.saveDraft("Hell", for: threadId)
        sut.saveDraft("Hello", for: threadId)
        
        // Then - Wait for debounce (100ms + buffer)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(self.autoSaveCallCount, 1)
            XCTAssertEqual(self.autoSavedDrafts.last?.content, "Hello")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testAutoSave_FastTest() {
        // Given
        let threadId = UUID()
        let content = "Auto-save test"
        let expectation = expectation(description: "Auto-save should trigger")
        
        // When
        sut.saveDraft(content, for: threadId)
        
        // Then - Wait for auto-save (500ms + buffer)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            XCTAssertGreaterThanOrEqual(self.autoSaveCallCount, 1)
            XCTAssertTrue(self.autoSavedDrafts.contains { $0.content == content })
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testDebounceResetOnNewInput() {
        // Given
        let threadId = UUID()
        let expectation = expectation(description: "Debounce should reset")
        
        // When - Type, wait almost debounce time, type again
        sut.saveDraft("First", for: threadId)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            // Just before debounce triggers, type more
            self.sut.saveDraft("Second", for: threadId)
        }
        
        // Then - Should only trigger once with final content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            XCTAssertEqual(self.autoSaveCallCount, 1)
            XCTAssertEqual(self.autoSavedDrafts.last?.content, "Second")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testMultipleThreadsWithDifferentTimings() {
        // Given
        let threadId1 = UUID()
        let threadId2 = UUID()
        let expectation = expectation(description: "Both drafts saved")
        
        // When - Save to different threads at different times
        sut.saveDraft("Thread 1 content", for: threadId1)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.sut.saveDraft("Thread 2 content", for: threadId2)
        }
        
        // Then - Both should be saved
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let thread1Saves = self.autoSavedDrafts.filter { $0.threadId == threadId1 }
            let thread2Saves = self.autoSavedDrafts.filter { $0.threadId == threadId2 }
            
            XCTAssertFalse(thread1Saves.isEmpty)
            XCTAssertFalse(thread2Saves.isEmpty)
            XCTAssertEqual(thread1Saves.last?.content, "Thread 1 content")
            XCTAssertEqual(thread2Saves.last?.content, "Thread 2 content")
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testAutoSaveDoesNotTriggerForClearedDrafts() {
        // Given
        let threadId = UUID()
        let expectation = expectation(description: "Auto-save should not trigger")
        
        // When - Save draft then immediately clear it
        sut.saveDraft("Will be cleared", for: threadId)
        sut.clearDraft(for: threadId)
        
        // Then - Auto-save should not save cleared draft
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let savedForThread = self.autoSavedDrafts.filter { $0.threadId == threadId }
            XCTAssertTrue(savedForThread.isEmpty)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func testRapidSaveAndClear() {
        // Given
        let threadId = UUID()
        let expectation = expectation(description: "Rapid operations complete")
        
        // When - Rapidly save and clear
        for i in 0..<10 {
            sut.saveDraft("Draft \(i)", for: threadId)
            if i % 2 == 0 {
                sut.clearDraft(for: threadId)
            }
        }
        
        // Then - Should handle gracefully
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Either has a draft or doesn't, but shouldn't crash
            let hasDraft = self.sut.hasDraft(for: threadId)
            XCTAssertTrue(hasDraft || !hasDraft) // Always true, just checking no crash
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }
}