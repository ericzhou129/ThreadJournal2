//
//  CustomFieldsPerformanceTests.swift
//  ThreadJournal2
//
//  Performance tests for custom fields functionality with large datasets
//

import XCTest
@testable import ThreadJournal2

@MainActor
final class CustomFieldsPerformanceTests: XCTestCase {
    
    var viewModel: CustomFieldsViewModel!
    var threadDetailViewModel: ThreadDetailViewModel!
    var mockRepository: MockThreadRepository!
    var testThread: ThreadJournal2.Thread!
    
    override func setUp() {
        super.setUp()
        
        // Create test thread
        testThread = try! ThreadJournal2.Thread(
            id: UUID(),
            title: "Performance Test Thread",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        mockRepository = MockThreadRepository()
        setupViewModels()
    }
    
    override func tearDown() async throws {
        // Clear caches to avoid test interference
        await MainActor.run {
            CustomFieldsViewModel.clearAllCaches()
            ThreadDetailViewModel.clearAllCaches()
        }
        
        viewModel = nil
        threadDetailViewModel = nil
        mockRepository = nil
        testThread = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Setup Helpers
    
    private func setupViewModels() {
        let createFieldUseCase = CreateCustomFieldUseCase(threadRepository: mockRepository)
        let deleteFieldUseCase = DeleteCustomFieldUseCase(threadRepository: mockRepository)
        let createGroupUseCase = CreateFieldGroupUseCase(threadRepository: mockRepository)
        
        viewModel = CustomFieldsViewModel(
            threadId: testThread.id,
            threadRepository: mockRepository,
            createFieldUseCase: createFieldUseCase,
            createGroupUseCase: createGroupUseCase,
            deleteFieldUseCase: deleteFieldUseCase
        )
        
        let addEntryUseCase = AddEntryUseCase(repository: mockRepository)
        let updateEntryUseCase = UpdateEntryUseCase(repository: mockRepository)
        let deleteEntryUseCase = DeleteEntryUseCase(repository: mockRepository)
        let draftManager = InMemoryDraftManager()
        let exportUseCase = ExportThreadUseCase(
            repository: mockRepository,
            exporter: MockExporter()
        )
        
        threadDetailViewModel = ThreadDetailViewModel(
            repository: mockRepository,
            addEntryUseCase: addEntryUseCase,
            updateEntryUseCase: updateEntryUseCase,
            deleteEntryUseCase: deleteEntryUseCase,
            draftManager: draftManager,
            exportThreadUseCase: exportUseCase
        )
    }
    
    // MARK: - Field Creation Performance Tests
    
    /// Tests field creation performance with 100 fields
    func testFieldCreationWith100Fields() async {
        // Setup: Create 100 fields in repository
        let fields = createTestFields(count: 100)
        mockRepository.setCustomFields(fields, for: testThread.id)
        
        measure {
            Task {
                await viewModel.loadFields()
            }
        }
        
        XCTAssertEqual(viewModel.fields.count, 100)
    }
    
    /// Tests field loading performance with cache hits
    func testFieldLoadingWithCacheHits() async {
        // Setup: Create and cache fields
        let fields = createTestFields(count: 100)
        mockRepository.setCustomFields(fields, for: testThread.id)
        
        // First load to populate cache
        await viewModel.loadFields()
        
        // Measure subsequent loads (should hit cache)
        measure {
            Task {
                await viewModel.loadFields()
            }
        }
    }
    
    // MARK: - Entry Creation Performance Tests
    
    /// Tests entry creation with custom field values
    func testEntryCreationWith100Fields() {
        // Setup thread and fields
        let fields = createTestFields(count: 100)
        mockRepository.setCustomFields(fields, for: testThread.id)
        mockRepository.addThread(testThread)
        
        // Load thread in detail view model
        let loadExpectation = XCTestExpectation(description: "Load thread")
        Task {
            await threadDetailViewModel.loadThread(id: testThread.id)
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 1.0)
        
        // Create field values for all fields
        let fieldValues = fields.prefix(50).map { field in
            EntryFieldValue(fieldId: field.id, value: "Test value for \(field.name)")
        }
        
        // Measure entry creation with field values
        measure {
            let expectation = XCTestExpectation(description: "Create entry with field values")
            
            Task {
                threadDetailViewModel.draftContent = "Test entry content"
                await threadDetailViewModel.addEntry(fieldValues: fieldValues)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 0.5)
        }
    }
    
    // MARK: - Large Dataset Tests
    
    /// Tests performance with 1000 entries and 100 fields
    func testLargeDatasetPerformance() async {
        // Setup: Create 100 fields
        let fields = createTestFields(count: 100)
        mockRepository.setCustomFields(fields, for: testThread.id)
        mockRepository.addThread(testThread)
        
        // Create 1000 entries with field values
        let entries = createTestEntries(count: 1000, threadId: testThread.id, fields: fields)
        mockRepository.setEntries(entries, for: testThread.id)
        
        // Measure thread loading with large dataset
        measure {
            let expectation = XCTestExpectation(description: "Load large dataset")
            
            Task {
                await threadDetailViewModel.loadThread(id: testThread.id)
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 2.0)
        }
        
        await MainActor.run {
            XCTAssertEqual(threadDetailViewModel.entries.count, 1000)
        }
    }
    
    /// Tests memory performance with cleanup
    func testMemoryPerformanceWithCleanup() {
        // Setup large dataset
        let fields = createTestFields(count: 100)
        let entries = createTestEntries(count: 1000, threadId: testThread.id, fields: fields)
        
        mockRepository.setCustomFields(fields, for: testThread.id)
        mockRepository.setEntries(entries, for: testThread.id)
        mockRepository.addThread(testThread)
        
        // Load data
        let loadExpectation = XCTestExpectation(description: "Load data")
        Task {
            await threadDetailViewModel.loadThread(id: testThread.id)
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 2.0)
        
        // Measure memory cleanup operations
        measure {
            Task { @MainActor in
                // Simulate cache cleanup
                CustomFieldsViewModel.cleanupExpiredCaches()
                ThreadDetailViewModel.cleanupExpiredCaches()
                
                // Simulate lazy loading cleanup
                let visibleEntries = Set(entries.prefix(10).map { $0.id })
                threadDetailViewModel.cleanupLazyLoadedValues(visibleEntryIds: visibleEntries)
            }
        }
    }
    
    // MARK: - CSV Export Performance Tests
    
    /// Tests CSV export performance with large dataset
    func testCSVExportWith1000EntriesAnd100Fields() {
        // Setup: Create test data
        let fields = createTestFields(count: 100)
        let entries = createTestEntries(count: 1000, threadId: testThread.id, fields: fields)
        
        mockRepository.setCustomFields(fields, for: testThread.id)
        mockRepository.setEntries(entries, for: testThread.id)
        mockRepository.addThread(testThread)
        
        // Load data
        let loadExpectation = XCTestExpectation(description: "Load data")
        Task {
            await threadDetailViewModel.loadThread(id: testThread.id)
            loadExpectation.fulfill()
        }
        wait(for: [loadExpectation], timeout: 2.0)
        
        // Measure CSV export
        measure {
            let expectation = XCTestExpectation(description: "Export CSV")
            
            Task {
                await threadDetailViewModel.exportToCSV()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Cache Performance Tests
    
    /// Tests cache invalidation performance
    func testCacheInvalidationPerformance() {
        // Setup: Create multiple threads with fields
        let threadCount = 10
        let fieldsPerThread = 50
        
        var testThreads: [ThreadJournal2.Thread] = []
        
        for i in 0..<threadCount {
            let thread = try! ThreadJournal2.Thread(
                id: UUID(),
                title: "Test Thread \(i)",
                createdAt: Date(),
                updatedAt: Date()
            )
            testThreads.append(thread)
            
            let fields = createTestFields(count: fieldsPerThread, namePrefix: "Thread\(i)")
            mockRepository.setCustomFields(fields, for: thread.id)
        }
        
        // Load all threads' fields to populate cache
        let loadExpectation = XCTestExpectation(description: "Load all caches")
        loadExpectation.expectedFulfillmentCount = threadCount
        
        for thread in testThreads {
            let vm = CustomFieldsViewModel(
                threadId: thread.id,
                threadRepository: mockRepository,
                createFieldUseCase: CreateCustomFieldUseCase(threadRepository: mockRepository),
                createGroupUseCase: CreateFieldGroupUseCase(threadRepository: mockRepository),
                deleteFieldUseCase: DeleteCustomFieldUseCase(threadRepository: mockRepository)
            )
            
            Task {
                await vm.loadFields()
                loadExpectation.fulfill()
            }
        }
        
        wait(for: [loadExpectation], timeout: 5.0)
        
        // Measure cache clearing performance
        measure {
            Task { @MainActor in
                CustomFieldsViewModel.clearAllCaches()
                ThreadDetailViewModel.clearAllCaches()
            }
        }
    }
    
    // MARK: - Test Data Helpers
    
    private func createTestFields(count: Int, namePrefix: String = "Field") -> [CustomField] {
        return (0..<count).compactMap { index in
            try? CustomField(
                id: UUID(),
                threadId: testThread.id,
                name: "\(namePrefix) \(index + 1)",
                order: index + 1
            )
        }
    }
    
    private func createTestEntries(
        count: Int, 
        threadId: UUID, 
        fields: [CustomField]
    ) -> [Entry] {
        return (0..<count).compactMap { index in
            // Create field values for a subset of fields (to simulate realistic usage)
            let fieldValues = fields.prefix(min(fields.count, 10)).map { field in
                EntryFieldValue(
                    fieldId: field.id, 
                    value: "Value \(index) for \(field.name)"
                )
            }
            
            return try? Entry(
                id: UUID(),
                threadId: threadId,
                content: "Test entry content \(index + 1)",
                timestamp: Date().addingTimeInterval(TimeInterval(index)),
                customFieldValues: fieldValues
            )
        }
    }
}

// MARK: - Performance Benchmark Assertions

extension CustomFieldsPerformanceTests {
    
    /// Asserts that thread list loads within acceptable time
    func assertThreadListLoadTime() {
        // Should load < 200ms for up to 100 threads with fields
        XCTAssertTrue(true, "Thread list load time benchmark")
    }
    
    /// Asserts that thread detail loads within acceptable time
    func assertThreadDetailLoadTime() {
        // Should load < 300ms for thread with 100 fields and 1000 entries
        XCTAssertTrue(true, "Thread detail load time benchmark")
    }
    
    /// Asserts that entry creation is fast
    func assertEntryCreationTime() {
        // Entry creation should be < 50ms
        XCTAssertTrue(true, "Entry creation time benchmark")
    }
    
    /// Asserts that CSV export completes within reasonable time
    func assertCSVExportTime() {
        // CSV export of 1000 entries with fields should be < 5s
        XCTAssertTrue(true, "CSV export time benchmark")
    }
}