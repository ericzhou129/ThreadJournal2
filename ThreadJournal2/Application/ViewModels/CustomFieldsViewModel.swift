//
//  CustomFieldsViewModel.swift
//  ThreadJournal2
//
//  ViewModel for managing custom fields in a thread
//

import Foundation
import Combine

/// ViewModel for managing custom fields with drag reorder and group support
@MainActor
final class CustomFieldsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var fields: [CustomField] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var newFieldName = ""
    @Published var validationError: String?
    
    // MARK: - Private Properties
    
    private let threadId: UUID
    private let threadRepository: ThreadRepository
    private let createFieldUseCase: CreateCustomFieldUseCaseProtocol
    private let createGroupUseCase: CreateFieldGroupUseCaseProtocol
    private let deleteFieldUseCase: DeleteCustomFieldUseCaseProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private var autoSaveTask: Task<Void, Never>?
    
    // MARK: - Caching Properties
    
    /// Cache for field definitions to avoid repeated database calls
    private static var fieldCache: [UUID: [CustomField]] = [:]
    private static var cacheTimestamps: [UUID: Date] = [:]
    private static let cacheTimeToLive: TimeInterval = 300 // 5 minutes
    
    /// Cached field definitions for this thread
    @Published private(set) var cachedFields: [CustomField] = []
    
    /// Flag indicating if cache is being refreshed
    @Published private(set) var isCacheRefreshing = false
    
    // MARK: - Initialization
    
    init(
        threadId: UUID,
        threadRepository: ThreadRepository,
        createFieldUseCase: CreateCustomFieldUseCaseProtocol,
        createGroupUseCase: CreateFieldGroupUseCaseProtocol,
        deleteFieldUseCase: DeleteCustomFieldUseCaseProtocol
    ) {
        self.threadId = threadId
        self.threadRepository = threadRepository
        self.createFieldUseCase = createFieldUseCase
        self.createGroupUseCase = createGroupUseCase
        self.deleteFieldUseCase = deleteFieldUseCase
        
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Validate new field name as user types
        $newFieldName
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] name in
                self?.validateFieldName(name)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Loads custom fields for the thread with caching optimization
    func loadFields() async {
        // First check cache
        if let cachedResult = getCachedFields() {
            fields = cachedResult
            cachedFields = cachedResult
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            let fetchedFields = try await threadRepository.fetchCustomFields(
                for: threadId,
                includeDeleted: false
            )
            
            fields = fetchedFields
            cachedFields = fetchedFields
            
            // Update cache
            updateCache(with: fetchedFields)
            
        } catch {
            self.error = "Failed to load fields: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Forces a cache refresh from the database
    func refreshFields() async {
        isCacheRefreshing = true
        invalidateCache()
        await loadFields()
        isCacheRefreshing = false
    }
    
    /// Adds a new custom field
    func addField() async {
        let name = newFieldName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !name.isEmpty else {
            validationError = "Field name cannot be empty"
            return
        }
        
        guard validationError == nil else { return }
        
        isLoading = true
        error = nil
        
        do {
            let newOrder = fields.isEmpty ? 1 : (fields.map { $0.order }.max() ?? 0) + 1
            let field = try await createFieldUseCase.execute(
                threadId: threadId,
                name: name,
                order: newOrder
            )
            
            fields.append(field)
            cachedFields.append(field)
            newFieldName = ""
            validationError = nil
            
            // Update cache with new field
            updateCache(with: fields)
        } catch {
            if let fieldError = error as? CustomFieldError {
                switch fieldError {
                case .duplicateFieldName:
                    validationError = "A field with this name already exists"
                case .maxFieldsExceeded:
                    self.error = "Maximum number of fields (20) reached"
                default:
                    self.error = "Failed to add field: \(error.localizedDescription)"
                }
            } else {
                self.error = "Failed to add field: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    /// Deletes a custom field
    func deleteField(_ field: CustomField) async {
        error = nil
        
        do {
            try await deleteFieldUseCase.execute(
                fieldId: field.id,
                preserveHistoricalData: true
            )
            
            fields.removeAll { $0.id == field.id }
            cachedFields.removeAll { $0.id == field.id }
            
            // Update cache after removal
            updateCache(with: fields)
            
            // If it was a group, also remove child fields
            if field.isGroup {
                // In a real app, we'd track parent-child relationships
                // For now, the UI will handle this
            }
        } catch {
            self.error = "Failed to delete field: \(error.localizedDescription)"
        }
    }
    
    /// Creates a group from selected fields
    func createGroup(parentFieldId: UUID, childFieldIds: [UUID]) async {
        error = nil
        
        do {
            _ = try await createGroupUseCase.execute(
                parentFieldId: parentFieldId,
                childFieldIds: childFieldIds
            )
            
            // Update the parent field to be a group
            if let index = fields.firstIndex(where: { $0.id == parentFieldId }) {
                let parentField = fields[index]
                let updatedField = try CustomField(
                    id: parentField.id,
                    threadId: parentField.threadId,
                    name: parentField.name,
                    order: parentField.order,
                    isGroup: true
                )
                fields[index] = updatedField
            }
            
            // Auto-save after group creation
            scheduleAutoSave()
        } catch {
            self.error = "Failed to create group: \(error.localizedDescription)"
        }
    }
    
    /// Reorders fields after drag and drop
    func moveFields(from source: IndexSet, to destination: Int) {
        fields.move(fromOffsets: source, toOffset: destination)
        
        // Update order values
        for (index, field) in fields.enumerated() {
            if field.order != index + 1 {
                // Create updated field with new order
                if let updatedField = try? CustomField(
                    id: field.id,
                    threadId: field.threadId,
                    name: field.name,
                    order: index + 1,
                    isGroup: field.isGroup
                ) {
                    fields[index] = updatedField
                }
            }
        }
        
        // Schedule auto-save after reorder
        scheduleAutoSave()
    }
    
    // MARK: - Private Methods
    
    private func validateFieldName(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            validationError = nil
            return
        }
        
        // Check for duplicate names (case-insensitive)
        let isDuplicate = fields.contains { field in
            field.name.lowercased() == trimmedName.lowercased()
        }
        
        validationError = isDuplicate ? "A field with this name already exists" : nil
    }
    
    private func scheduleAutoSave() {
        // Cancel any existing auto-save task
        autoSaveTask?.cancel()
        
        // Schedule new auto-save after 1 second
        autoSaveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            guard !Task.isCancelled else { return }
            
            await self?.saveFieldOrder()
        }
    }
    
    private func saveFieldOrder() async {
        // Save updated field order to repository
        for field in fields {
            do {
                try await threadRepository.updateCustomField(field)
            } catch {
                // Log error but don't show to user for auto-save
                print("Failed to auto-save field order: \(error)")
            }
        }
        
        // Update cache after reordering
        updateCache(with: fields)
    }
    
    // MARK: - Cache Management
    
    /// Gets cached fields if they exist and are still valid
    private func getCachedFields() -> [CustomField]? {
        guard let cachedFields = Self.fieldCache[threadId],
              let cacheTime = Self.cacheTimestamps[threadId] else {
            return nil
        }
        
        // Check if cache is still valid
        let timeElapsed = Date().timeIntervalSince(cacheTime)
        if timeElapsed > Self.cacheTimeToLive {
            invalidateCache()
            return nil
        }
        
        return cachedFields
    }
    
    /// Updates the cache with new field data
    private func updateCache(with fields: [CustomField]) {
        Self.fieldCache[threadId] = fields
        Self.cacheTimestamps[threadId] = Date()
    }
    
    /// Invalidates the cache for this thread
    private func invalidateCache() {
        Self.fieldCache.removeValue(forKey: threadId)
        Self.cacheTimestamps.removeValue(forKey: threadId)
    }
    
    /// Clears all cached data (useful for memory warnings)
    static func clearAllCaches() {
        fieldCache.removeAll()
        cacheTimestamps.removeAll()
    }
    
    /// Removes expired cache entries
    static func cleanupExpiredCaches() {
        let currentTime = Date()
        let expiredKeys = cacheTimestamps.compactMap { (key, timestamp) in
            currentTime.timeIntervalSince(timestamp) > cacheTimeToLive ? key : nil
        }
        
        for key in expiredKeys {
            fieldCache.removeValue(forKey: key)
            cacheTimestamps.removeValue(forKey: key)
        }
    }
}