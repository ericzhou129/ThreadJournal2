//
//  CreateThreadViewModelTests.swift
//  ThreadJournal2Tests
//
//  Tests for CreateThreadViewModel
//

import XCTest
@testable import ThreadJournal2

@MainActor
final class CreateThreadViewModelTests: XCTestCase {
    private var mockRepository: MockThreadRepository!
    private var createThreadUseCase: CreateThreadUseCase!
    private var mockDraftManager: MockDraftManager!
    private var sut: CreateThreadViewModel!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockThreadRepository()
        createThreadUseCase = CreateThreadUseCase(repository: mockRepository)
        mockDraftManager = MockDraftManager()
        sut = CreateThreadViewModel(
            createThreadUseCase: createThreadUseCase,
            draftManager: mockDraftManager
        )
    }
    
    override func tearDown() {
        sut = nil
        mockDraftManager = nil
        createThreadUseCase = nil
        mockRepository = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertEqual(sut.threadTitle, "")
        XCTAssertEqual(sut.firstEntryContent, "")
        XCTAssertFalse(sut.isCreating)
        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.createdThread)
        XCTAssertFalse(sut.isCreateButtonEnabled)
    }
    
    func testLoadsExistingDraft() {
        // Given
        let draftContent = "My Draft Title||||My draft entry"
        mockDraftManager.drafts[UUID(uuidString: "00000000-0000-0000-0000-000000000000")!] = draftContent
        
        // When
        sut = CreateThreadViewModel(
            createThreadUseCase: createThreadUseCase,
            draftManager: mockDraftManager
        )
        
        // Then
        XCTAssertEqual(sut.threadTitle, "My Draft Title")
        XCTAssertEqual(sut.firstEntryContent, "My draft entry")
    }
    
    // MARK: - Create Button State Tests
    
    func testCreateButtonDisabledWhenTitleEmpty() {
        sut.threadTitle = ""
        XCTAssertFalse(sut.isCreateButtonEnabled)
        
        sut.threadTitle = "   "
        XCTAssertFalse(sut.isCreateButtonEnabled)
    }
    
    func testCreateButtonEnabledWhenTitleNotEmpty() {
        sut.threadTitle = "My Thread"
        XCTAssertTrue(sut.isCreateButtonEnabled)
    }
    
    func testCreateButtonDisabledWhileCreating() async {
        sut.threadTitle = "My Thread"
        
        let expectation = XCTestExpectation(description: "Create thread")
        
        Task {
            await sut.createThread()
            expectation.fulfill()
        }
        
        // Should be disabled immediately
        XCTAssertFalse(sut.isCreateButtonEnabled)
        
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    // MARK: - Thread Creation Tests
    
    func testCreateThreadSuccess() async throws {
        // Given
        sut.threadTitle = "Test Thread"
        sut.firstEntryContent = "First entry"
        
        // When
        await sut.createThread()
        
        // Then
        XCTAssertNotNil(sut.createdThread)
        XCTAssertEqual(sut.createdThread?.title, "Test Thread")
        XCTAssertFalse(sut.isCreating)
        XCTAssertNil(sut.errorMessage)
        
        // Verify draft was cleared
        XCTAssertTrue(mockDraftManager.clearedDraftIds.contains(
            UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        ))
    }
    
    func testCreateThreadTrimsWhitespace() async throws {
        // Given
        sut.threadTitle = "  Test Thread  "
        sut.firstEntryContent = "  First entry  "
        
        // When
        await sut.createThread()
        
        // Then
        XCTAssertEqual(sut.createdThread?.title, "Test Thread")
    }
    
    func testCreateThreadWithoutFirstEntry() async throws {
        // Given
        sut.threadTitle = "Test Thread"
        sut.firstEntryContent = ""
        
        // When
        await sut.createThread()
        
        // Then
        XCTAssertNotNil(sut.createdThread)
        XCTAssertEqual(sut.createdThread?.title, "Test Thread")
    }
    
    func testCreateThreadFailure() async {
        // Given
        sut.threadTitle = "Test Thread"
        mockRepository.shouldFailCreate = true
        
        // When
        await sut.createThread()
        
        // Then
        XCTAssertNil(sut.createdThread)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isCreating)
    }
    
    // MARK: - Draft Management Tests
    
    func testDraftSavedOnTitleChange() {
        // Given
        sut.threadTitle = "My Title"
        
        // When
        sut.onTitleChange()
        
        // Wait for debounce
        let expectation = XCTestExpectation(description: "Draft saved")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
        
        // Then
        let savedDraft = mockDraftManager.drafts[UUID(uuidString: "00000000-0000-0000-0000-000000000000")!]
        XCTAssertEqual(savedDraft, "My Title||||")
    }
    
    func testDraftSavedOnFirstEntryChange() {
        // Given
        sut.threadTitle = "Title"
        sut.firstEntryContent = "Entry content"
        
        // When
        sut.onFirstEntryChange()
        
        // Wait for debounce
        let expectation = XCTestExpectation(description: "Draft saved")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
        
        // Then
        let savedDraft = mockDraftManager.drafts[UUID(uuidString: "00000000-0000-0000-0000-000000000000")!]
        XCTAssertEqual(savedDraft, "Title||||Entry content")
    }
    
    func testErrorClearedOnTitleChange() {
        // Given
        sut.errorMessage = "Some error"
        
        // When
        sut.onTitleChange()
        
        // Then
        XCTAssertNil(sut.errorMessage)
    }
    
    func testClearDraft() {
        // Given
        sut.threadTitle = "Title"
        sut.firstEntryContent = "Content"
        
        // When
        sut.clearDraft()
        
        // Then
        XCTAssertEqual(sut.threadTitle, "")
        XCTAssertEqual(sut.firstEntryContent, "")
        XCTAssertTrue(mockDraftManager.clearedDraftIds.contains(
            UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        ))
    }
}

// MARK: - Mock Draft Manager

private class MockDraftManager: DraftManager {
    var drafts: [UUID: String] = [:]
    var clearedDraftIds: Set<UUID> = []
    
    func saveDraft(_ content: String, for threadId: UUID) {
        drafts[threadId] = content
    }
    
    func getDraft(for threadId: UUID) -> String? {
        return drafts[threadId]
    }
    
    func clearDraft(for threadId: UUID) {
        drafts.removeValue(forKey: threadId)
        clearedDraftIds.insert(threadId)
    }
}