//
//  ThreadDetailViewModelTests.swift
//  ThreadJournal2Tests
//
//  Unit tests for ThreadDetailViewModel including draft management and retry logic
//

import XCTest
@testable import ThreadJournal2

@MainActor
final class ThreadDetailViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var sut: ThreadDetailViewModel!
    private var mockRepository: MockThreadRepository!
    private var mockDraftManager: MockDraftManager!
    private var addEntryUseCase: AddEntryUseCase!
    private var updateEntryUseCase: UpdateEntryUseCase!
    private var deleteEntryUseCase: DeleteEntryUseCase!
    
    // MARK: - Setup
    
    override func setUp() async throws {
        try await super.setUp()
        
        mockRepository = MockThreadRepository()
        mockDraftManager = MockDraftManager()
        addEntryUseCase = AddEntryUseCase(repository: mockRepository)
        updateEntryUseCase = UpdateEntryUseCase(repository: mockRepository)
        deleteEntryUseCase = DeleteEntryUseCase(repository: mockRepository)
        
        // Create mock exporter and export use case
        let mockExporter = MockExporter()
        let exportThreadUseCase = ExportThreadUseCase(
            repository: mockRepository,
            exporter: mockExporter
        )
        
        sut = ThreadDetailViewModel(
            repository: mockRepository,
            addEntryUseCase: addEntryUseCase,
            updateEntryUseCase: updateEntryUseCase,
            deleteEntryUseCase: deleteEntryUseCase,
            draftManager: mockDraftManager,
            exportThreadUseCase: exportThreadUseCase
        )
    }
    
    override func tearDown() async throws {
        sut = nil
        mockRepository = nil
        mockDraftManager = nil
        addEntryUseCase = nil
        updateEntryUseCase = nil
        deleteEntryUseCase = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertNil(sut.thread)
        XCTAssertTrue(sut.entries.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.draftContent, "")
        XCTAssertFalse(sut.isSavingDraft)
        XCTAssertFalse(sut.hasFailedSave)
        XCTAssertNil(sut.saveError)
        XCTAssertFalse(sut.shouldScrollToLatest)
        XCTAssertEqual(sut.draftStateDescription, "")
    }
    
    // MARK: - Thread Loading Tests
    
    func testLoadThreadSuccess() async throws {
        // Given
        let thread = try Thread(
            id: UUID(),
            title: "Test Thread",
            createdAt: Date(),
            updatedAt: Date()
        )
        let entry1 = try Entry(
            threadId: thread.id,
            content: "First entry",
            timestamp: Date().addingTimeInterval(-60)
        )
        let entry2 = try Entry(
            threadId: thread.id,
            content: "Second entry",
            timestamp: Date()
        )
        
        mockRepository.mockThreads = [thread]
        mockRepository.mockEntries[thread.id] = [entry1, entry2]
        
        // When
        await sut.loadThread(id: thread.id)
        
        // Then
        XCTAssertEqual(sut.thread?.id, thread.id)
        XCTAssertEqual(sut.thread?.title, thread.title)
        XCTAssertEqual(sut.entries.count, 2)
        XCTAssertEqual(sut.entries[0].content, "First entry")
        XCTAssertEqual(sut.entries[1].content, "Second entry")
        XCTAssertFalse(sut.isLoading)
    }
    
    func testLoadThreadWithExistingDraft() async throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread")
        let draftContent = "This is my draft"
        
        mockRepository.mockThreads = [thread]
        mockRepository.mockEntries[thread.id] = []
        mockDraftManager.drafts[thread.id] = draftContent
        
        // When
        await sut.loadThread(id: thread.id)
        
        // Then
        XCTAssertEqual(sut.draftContent, draftContent)
        XCTAssertEqual(sut.draftStateDescription, "Draft")
    }
    
    func testLoadThreadNotFound() async {
        // Given
        let nonExistentId = UUID()
        
        // When
        await sut.loadThread(id: nonExistentId)
        
        // Then
        XCTAssertNil(sut.thread)
        XCTAssertTrue(sut.entries.isEmpty)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testLoadThreadSetsScrollFlag() async throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread")
        mockRepository.mockThreads = [thread]
        
        // When
        await sut.loadThread(id: thread.id)
        
        // Then
        XCTAssertTrue(sut.shouldScrollToLatest)
        
        // Wait for flag to reset
        try await Task.sleep(nanoseconds: 600_000_000)
        XCTAssertFalse(sut.shouldScrollToLatest)
    }
    
    // MARK: - Entry Addition Tests
    
    func testAddEntrySuccess() async throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread")
        mockRepository.mockThreads = [thread]
        await sut.loadThread(id: thread.id)
        
        sut.draftContent = "New entry content"
        
        // When
        await sut.addEntry()
        
        // Then
        XCTAssertEqual(sut.entries.count, 1)
        XCTAssertEqual(sut.entries[0].content, "New entry content")
        XCTAssertEqual(sut.draftContent, "")
        XCTAssertFalse(sut.hasFailedSave)
        XCTAssertNil(sut.saveError)
        XCTAssertTrue(mockDraftManager.clearedDrafts.contains(thread.id))
    }
    
    func testAddEntryEmptyContent() async throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread")
        mockRepository.mockThreads = [thread]
        await sut.loadThread(id: thread.id)
        
        sut.draftContent = "   "
        
        // When
        await sut.addEntry()
        
        // Then
        XCTAssertTrue(sut.entries.isEmpty)
        XCTAssertEqual(sut.draftContent, "   ")
    }
    
    func testAddEntryFailure() async throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread")
        mockRepository.mockThreads = [thread]
        mockRepository.shouldFailAddEntry = true
        await sut.loadThread(id: thread.id)
        
        sut.draftContent = "Content that will fail"
        
        // When
        await sut.addEntry()
        
        // Then
        XCTAssertTrue(sut.entries.isEmpty)
        XCTAssertEqual(sut.draftContent, "Content that will fail")
        XCTAssertTrue(sut.hasFailedSave)
        XCTAssertNotNil(sut.saveError)
        XCTAssertEqual(sut.draftStateDescription, "Save failed")
    }
    
    // MARK: - Retry Tests
    
    func testRetrySaveSuccess() async throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread")
        mockRepository.mockThreads = [thread]
        mockRepository.shouldFailAddEntry = true
        await sut.loadThread(id: thread.id)
        
        sut.draftContent = "Retry content"
        await sut.addEntry()
        
        XCTAssertTrue(sut.hasFailedSave)
        
        // When - fix the error and retry
        mockRepository.shouldFailAddEntry = false
        await sut.retrySave()
        
        // Then
        XCTAssertEqual(sut.entries.count, 1)
        XCTAssertEqual(sut.entries[0].content, "Retry content")
        XCTAssertEqual(sut.draftContent, "")
        XCTAssertFalse(sut.hasFailedSave)
    }
    
    func testRetryMaxAttempts() async throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread")
        mockRepository.mockThreads = [thread]
        mockRepository.shouldFailAddEntry = true
        await sut.loadThread(id: thread.id)
        
        sut.draftContent = "Will fail multiple times"
        
        // When - try max attempts
        await sut.addEntry() // First attempt
        await sut.retrySave() // Retry 1
        await sut.retrySave() // Retry 2
        await sut.retrySave() // Retry 3
        await sut.retrySave() // Should not execute (exceeds max)
        
        // Then
        XCTAssertTrue(sut.entries.isEmpty)
        XCTAssertTrue(sut.hasFailedSave)
    }
    
    // MARK: - Draft Management Tests
    
    func testDraftContentChangeTriggersSave() async throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread")
        mockRepository.mockThreads = [thread]
        await sut.loadThread(id: thread.id)
        
        // When
        sut.draftContent = "Draft text"
        
        // Then
        XCTAssertEqual(sut.draftStateDescription, "Draft")
        XCTAssertTrue(mockDraftManager.savedDrafts.contains { $0.threadId == thread.id })
    }
    
    func testEmptyDraftNotSaved() async throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread")
        mockRepository.mockThreads = [thread]
        await sut.loadThread(id: thread.id)
        
        // When
        sut.draftContent = "Some text"
        sut.draftContent = ""
        
        // Then
        XCTAssertEqual(sut.draftStateDescription, "")
    }
    
    func testDraftStateTransitions() async throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread")
        mockRepository.mockThreads = [thread]
        await sut.loadThread(id: thread.id)
        
        // When typing
        sut.draftContent = "Typing..."
        XCTAssertEqual(sut.draftStateDescription, "Draft")
        
        // When saving (would be triggered by auto-save in real scenario)
        // This is tested indirectly through the auto-save callback
    }
    
    // MARK: - Helper Tests
    
    func testCanSendEntry() async throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread")
        mockRepository.mockThreads = [thread]
        await sut.loadThread(id: thread.id)
        
        // When empty
        XCTAssertFalse(sut.canSendEntry)
        
        // When has content
        sut.draftContent = "Some content"
        XCTAssertTrue(sut.canSendEntry)
        
        // When whitespace only
        sut.draftContent = "   "
        XCTAssertFalse(sut.canSendEntry)
    }
    
    // MARK: - Edit Entry Tests
    
    func testStartEditingEntry() async throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread")
        let entry = try Entry(
            threadId: thread.id,
            content: "Original content",
            timestamp: Date()
        )
        mockRepository.mockThreads = [thread]
        mockRepository.mockEntries[thread.id] = [entry]
        await sut.loadThread(id: thread.id)
        
        // When
        sut.startEditingEntry(entry)
        
        // Then
        XCTAssertEqual(sut.editingEntry?.id, entry.id)
        XCTAssertEqual(sut.editedContent, "Original content")
        XCTAssertTrue(sut.isEditFieldFocused)
    }
    
    func testSaveEditedEntry() async throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread")
        let entry = try Entry(
            threadId: thread.id,
            content: "Original content",
            timestamp: Date()
        )
        mockRepository.mockThreads = [thread]
        mockRepository.mockEntries[thread.id] = [entry]
        await sut.loadThread(id: thread.id)
        
        sut.startEditingEntry(entry)
        sut.editedContent = "Updated content"
        
        // When
        await sut.saveEditedEntry()
        
        // Then
        XCTAssertNil(sut.editingEntry)
        XCTAssertEqual(sut.editedContent, "")
        XCTAssertFalse(sut.isEditFieldFocused)
        XCTAssertEqual(sut.entries[0].content, "Updated content")
    }
    
    func testSaveEditedEntryWithEmptyContent() async throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread")
        let entry = try Entry(
            threadId: thread.id,
            content: "Original content",
            timestamp: Date()
        )
        mockRepository.mockThreads = [thread]
        mockRepository.mockEntries[thread.id] = [entry]
        await sut.loadThread(id: thread.id)
        
        sut.startEditingEntry(entry)
        sut.editedContent = "   " // Empty/whitespace content
        
        // When
        await sut.saveEditedEntry()
        
        // Then
        XCTAssertNil(sut.editingEntry)
        XCTAssertEqual(sut.entries[0].content, "Original content") // Should not update
    }
    
    func testSaveEditedEntryWithUnchangedContent() async throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread")
        let entry = try Entry(
            threadId: thread.id,
            content: "Original content",
            timestamp: Date()
        )
        mockRepository.mockThreads = [thread]
        mockRepository.mockEntries[thread.id] = [entry]
        await sut.loadThread(id: thread.id)
        
        sut.startEditingEntry(entry)
        // Content remains the same
        
        // When
        await sut.saveEditedEntry()
        
        // Then
        XCTAssertNil(sut.editingEntry)
        XCTAssertEqual(sut.entries[0].content, "Original content")
    }
    
    func testCancelEditing() async throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread")
        let entry = try Entry(
            threadId: thread.id,
            content: "Original content",
            timestamp: Date()
        )
        mockRepository.mockThreads = [thread]
        mockRepository.mockEntries[thread.id] = [entry]
        await sut.loadThread(id: thread.id)
        
        sut.startEditingEntry(entry)
        sut.editedContent = "Changed content"
        
        // When
        sut.cancelEditing()
        
        // Then
        XCTAssertNil(sut.editingEntry)
        XCTAssertEqual(sut.editedContent, "")
        XCTAssertFalse(sut.isEditFieldFocused)
        XCTAssertEqual(sut.entries[0].content, "Original content") // Should not change
    }
    
    // MARK: - Delete Entry Tests
    
    func testConfirmDeleteEntry() async throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread")
        let entry = try Entry(
            threadId: thread.id,
            content: "Entry to delete",
            timestamp: Date()
        )
        mockRepository.mockThreads = [thread]
        mockRepository.mockEntries[thread.id] = [entry]
        await sut.loadThread(id: thread.id)
        
        // When
        sut.confirmDeleteEntry(entry)
        
        // Then
        XCTAssertEqual(sut.entryToDelete?.id, entry.id)
        XCTAssertTrue(sut.showDeleteConfirmation)
    }
    
    func testExecuteDeleteEntry() async throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread")
        let entry1 = try Entry(
            threadId: thread.id,
            content: "First entry",
            timestamp: Date()
        )
        let entry2 = try Entry(
            threadId: thread.id,
            content: "Entry to delete",
            timestamp: Date()
        )
        mockRepository.mockThreads = [thread]
        mockRepository.mockEntries[thread.id] = [entry1, entry2]
        await sut.loadThread(id: thread.id)
        
        sut.confirmDeleteEntry(entry2)
        
        // When
        await sut.executeDeleteEntry()
        
        // Then
        XCTAssertNil(sut.entryToDelete)
        XCTAssertFalse(sut.showDeleteConfirmation)
        XCTAssertEqual(sut.entries.count, 1)
        XCTAssertEqual(sut.entries[0].content, "First entry")
    }
    
    func testCancelDeleteEntry() async throws {
        // Given
        let thread = try Thread(id: UUID(), title: "Test Thread")
        let entry = try Entry(
            threadId: thread.id,
            content: "Entry",
            timestamp: Date()
        )
        mockRepository.mockThreads = [thread]
        mockRepository.mockEntries[thread.id] = [entry]
        await sut.loadThread(id: thread.id)
        
        sut.confirmDeleteEntry(entry)
        
        // When
        sut.cancelDeleteEntry()
        
        // Then
        XCTAssertNil(sut.entryToDelete)
        XCTAssertFalse(sut.showDeleteConfirmation)
        XCTAssertEqual(sut.entries.count, 1) // Entry should still exist
    }
    
    // MARK: - Voice Recording Tests
    
    func testVoiceRecordingAvailability_WithServices() {
        // Given
        let mockAudioService = MockAudioCaptureService()
        let mockTranscriptionService = MockWhisperKitService()
        let mockExporter = MockExporter()
        let exportThreadUseCase = ExportThreadUseCase(
            repository: mockRepository,
            exporter: mockExporter
        )
        
        let sutWithVoiceServices = ThreadDetailViewModel(
            repository: mockRepository,
            addEntryUseCase: addEntryUseCase,
            updateEntryUseCase: updateEntryUseCase,
            deleteEntryUseCase: deleteEntryUseCase,
            draftManager: mockDraftManager,
            exportThreadUseCase: exportThreadUseCase,
            audioService: mockAudioService,
            transcriptionService: mockTranscriptionService
        )
        
        // Then
        XCTAssertTrue(sutWithVoiceServices.isVoiceRecordingAvailable)
        XCTAssertNotNil(sutWithVoiceServices.voiceCoordinator)
    }
    
    func testVoiceRecordingAvailability_WithoutServices() {
        // When/Then
        XCTAssertFalse(sut.isVoiceRecordingAvailable)
        XCTAssertNil(sut.voiceCoordinator)
    }
    
    func testStartVoiceRecording_WithoutServices() async {
        // When
        await sut.startVoiceRecording()
        
        // Then
        XCTAssertEqual(sut.voiceRecordingError, "Voice recording not available")
        XCTAssertFalse(sut.isVoiceRecording)
    }
    
    func testStopAndEdit_WithoutServices() async {
        // When
        await sut.stopAndEdit()
        
        // Then - Should complete without error
        XCTAssertEqual(sut.draftContent, "")
    }
    
    func testStopAndSave_WithoutServices() async {
        // When
        await sut.stopAndSave()
        
        // Then - Should complete without error
        XCTAssertEqual(sut.draftContent, "")
    }
    
    func testCancelVoiceRecording_WithoutServices() async {
        // When
        await sut.cancelVoiceRecording()
        
        // Then - Should complete without error (no-op)
    }
}

// MARK: - Mock Voice Services

private class MockAudioCaptureService: AudioCaptureServiceProtocol {
    var shouldStartRecordingSucceed = true
    var startRecordingCalled = false
    var stopRecordingCalled = false
    var recordingData = Data()
    private var _isRecording = false
    
    func requestMicrophonePermission() async -> Bool {
        return true
    }
    
    func startRecording() async throws {
        startRecordingCalled = true
        if shouldStartRecordingSucceed {
            _isRecording = true
        } else {
            throw AudioCaptureError.recordingFailed
        }
    }
    
    func stopRecording() async throws -> Data {
        stopRecordingCalled = true
        _isRecording = false
        return recordingData
    }
    
    func getAudioLevel() -> Float {
        return 0.5
    }
    
    func isRecording() -> Bool {
        return _isRecording
    }
    
    func getRecordingDuration() -> TimeInterval {
        return 10.0
    }
}

// MARK: - Mock Draft Manager

private final class MockDraftManager: DraftManager {
    var drafts: [UUID: String] = [:]
    var savedDrafts: [(threadId: UUID, content: String)] = []
    var clearedDrafts: [UUID] = []
    
    func saveDraft(_ content: String, for threadId: UUID) {
        drafts[threadId] = content
        savedDrafts.append((threadId: threadId, content: content))
    }
    
    func getDraft(for threadId: UUID) -> String? {
        drafts[threadId]
    }
    
    func clearDraft(for threadId: UUID) {
        drafts.removeValue(forKey: threadId)
        clearedDrafts.append(threadId)
    }
}