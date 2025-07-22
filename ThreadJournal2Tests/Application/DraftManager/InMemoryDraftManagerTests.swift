//
//  InMemoryDraftManagerTests.swift
//  ThreadJournal2Tests
//
//  Created on 1/19/25.
//

import XCTest
@testable import ThreadJournal2

final class InMemoryDraftManagerTests: XCTestCase {
    
    // MARK: - Properties
    
    var sut: InMemoryDraftManager!
    var autoSaveCallCount: Int = 0
    var lastAutoSavedThreadId: UUID?
    var lastAutoSavedContent: String?
    
    // MARK: - Setup
    
    override func setUp() {
        super.setUp()
        sut = InMemoryDraftManager()
        autoSaveCallCount = 0
        lastAutoSavedThreadId = nil
        lastAutoSavedContent = nil
        
        // Set up auto-save callback
        sut.onAutoSave = { [weak self] threadId, content in
            self?.autoSaveCallCount += 1
            self?.lastAutoSavedThreadId = threadId
            self?.lastAutoSavedContent = content
        }
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testSaveDraft_StoresContentInMemory() {
        // Given
        let threadId = UUID()
        let content = "Test draft content"
        
        // When
        sut.saveDraft(content, for: threadId)
        
        // Then
        XCTAssertEqual(sut.getDraft(for: threadId), content)
    }
    
    func testGetDraft_ReturnsNilForNonexistentDraft() {
        // Given
        let threadId = UUID()
        
        // When/Then
        XCTAssertNil(sut.getDraft(for: threadId))
    }
    
    func testClearDraft_RemovesDraftFromMemory() {
        // Given
        let threadId = UUID()
        let content = "Test draft"
        sut.saveDraft(content, for: threadId)
        
        // When
        sut.clearDraft(for: threadId)
        
        // Then
        XCTAssertNil(sut.getDraft(for: threadId))
    }
    
    func testSaveDraft_OverwritesExistingDraft() {
        // Given
        let threadId = UUID()
        let originalContent = "Original draft"
        let updatedContent = "Updated draft"
        
        // When
        sut.saveDraft(originalContent, for: threadId)
        sut.saveDraft(updatedContent, for: threadId)
        
        // Then
        XCTAssertEqual(sut.getDraft(for: threadId), updatedContent)
    }
    
    func testDebouncing_WaitsForKeystrokesToStop() {
        // Given
        let threadId = UUID()
        let expectation = expectation(description: "Debounce should trigger")
        
        // When - Simulate rapid typing
        sut.saveDraft("H", for: threadId)
        sut.saveDraft("He", for: threadId)
        sut.saveDraft("Hel", for: threadId)
        sut.saveDraft("Hell", for: threadId)
        sut.saveDraft("Hello", for: threadId)
        
        // Then - Wait for debounce (2 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            XCTAssertEqual(self.autoSaveCallCount, 1)
            XCTAssertEqual(self.lastAutoSavedContent, "Hello")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 3.0)
    }
    
    func testAutoSave_TriggersEvery30Seconds() {
        // Given
        let threadId = UUID()
        let content = "Auto-save test content"
        let expectation = expectation(description: "Auto-save should trigger")
        
        // When
        sut.saveDraft(content, for: threadId)
        
        // Then - Wait for auto-save (30 seconds)
        // Note: In real tests, we'd inject a timer or use a shorter interval
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.5) {
            XCTAssertGreaterThanOrEqual(self.autoSaveCallCount, 1)
            XCTAssertEqual(self.lastAutoSavedContent, content)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 31.0)
    }
    
    func testMultipleThreads_MaintainsSeparateDrafts() {
        // Given
        let threadId1 = UUID()
        let threadId2 = UUID()
        let content1 = "Draft for thread 1"
        let content2 = "Draft for thread 2"
        
        // When
        sut.saveDraft(content1, for: threadId1)
        sut.saveDraft(content2, for: threadId2)
        
        // Then
        XCTAssertEqual(sut.getDraft(for: threadId1), content1)
        XCTAssertEqual(sut.getDraft(for: threadId2), content2)
    }
    
    func testClearDraft_DoesNotAffectOtherDrafts() {
        // Given
        let threadId1 = UUID()
        let threadId2 = UUID()
        sut.saveDraft("Draft 1", for: threadId1)
        sut.saveDraft("Draft 2", for: threadId2)
        
        // When
        sut.clearDraft(for: threadId1)
        
        // Then
        XCTAssertNil(sut.getDraft(for: threadId1))
        XCTAssertEqual(sut.getDraft(for: threadId2), "Draft 2")
    }
    
    func testThreadSafety_ConcurrentAccess() {
        // Given
        let threadId = UUID()
        let expectation = expectation(description: "Concurrent operations complete")
        let group = DispatchGroup()
        
        // When - Perform concurrent operations
        for i in 0..<100 {
            group.enter()
            DispatchQueue.global().async {
                self.sut.saveDraft("Content \(i)", for: threadId)
                _ = self.sut.getDraft(for: threadId)
                group.leave()
            }
        }
        
        // Then
        group.notify(queue: .main) {
            // Should not crash and should have a value
            XCTAssertNotNil(self.sut.getDraft(for: threadId))
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testHasDraft_ReturnsTrueWhenDraftExists() {
        // Given
        let threadId = UUID()
        
        // When/Then - No draft
        XCTAssertFalse(sut.hasDraft(for: threadId))
        
        // When/Then - With draft
        sut.saveDraft("Test", for: threadId)
        XCTAssertTrue(sut.hasDraft(for: threadId))
        
        // When/Then - After clear
        sut.clearDraft(for: threadId)
        XCTAssertFalse(sut.hasDraft(for: threadId))
    }
    
    func testGetAllDrafts_ReturnsAllStoredDrafts() {
        // Given
        let threadId1 = UUID()
        let threadId2 = UUID()
        
        // When
        sut.saveDraft("Draft 1", for: threadId1)
        sut.saveDraft("Draft 2", for: threadId2)
        
        // Then
        let allDrafts = sut.getAllDrafts()
        XCTAssertEqual(allDrafts.count, 2)
        XCTAssertEqual(allDrafts[threadId1], "Draft 1")
        XCTAssertEqual(allDrafts[threadId2], "Draft 2")
    }
}