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
    private let createFieldUseCase: CreateCustomFieldUseCase
    private let createGroupUseCase: CreateFieldGroupUseCase
    private let deleteFieldUseCase: DeleteCustomFieldUseCase
    
    private var cancellables = Set<AnyCancellable>()
    private var autoSaveTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init(
        threadId: UUID,
        threadRepository: ThreadRepository,
        createFieldUseCase: CreateCustomFieldUseCase,
        createGroupUseCase: CreateFieldGroupUseCase,
        deleteFieldUseCase: DeleteCustomFieldUseCase
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
    
    /// Loads custom fields for the thread
    func loadFields() async {
        isLoading = true
        error = nil
        
        do {
            fields = try await threadRepository.fetchCustomFields(
                for: threadId,
                includeDeleted: false
            )
        } catch {
            self.error = "Failed to load fields: \(error.localizedDescription)"
        }
        
        isLoading = false
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
            newFieldName = ""
            validationError = nil
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
    }
}