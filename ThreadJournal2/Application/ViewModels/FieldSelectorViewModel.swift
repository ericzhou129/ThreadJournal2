//
//  FieldSelectorViewModel.swift
//  ThreadJournal2
//
//  ViewModel for selecting custom fields when creating an entry
//

import Foundation
import Combine

/// Model representing a selectable field in the UI
struct SelectableField: Identifiable {
    let field: CustomField
    var isSelected: Bool
    var childFields: [SelectableField] = []
    
    var id: UUID { field.id }
}

/// ViewModel for field selection when composing entries
@MainActor
final class FieldSelectorViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var selectableFields: [SelectableField] = []
    @Published private(set) var selectedFieldIds: Set<UUID> = []
    @Published var isLoading = false
    @Published var error: String?
    
    // MARK: - Computed Properties
    
    /// Returns the selected custom fields
    var selectedFields: [CustomField] {
        selectableFields
            .flatMap { field -> [CustomField] in
                var result: [CustomField] = []
                if selectedFieldIds.contains(field.id) {
                    result.append(field.field)
                }
                // Add child fields if selected
                result.append(contentsOf: field.childFields
                    .filter { selectedFieldIds.contains($0.id) }
                    .map { $0.field }
                )
                return result
            }
    }
    
    /// Returns true if any fields are selected
    var hasSelectedFields: Bool {
        !selectedFieldIds.isEmpty
    }
    
    // MARK: - Private Properties
    
    private let threadId: UUID
    private let threadRepository: ThreadRepository
    private var fieldGroups: [UUID: [CustomField]] = [:] // Parent ID to child fields
    
    // MARK: - Initialization
    
    init(threadId: UUID, threadRepository: ThreadRepository) {
        self.threadId = threadId
        self.threadRepository = threadRepository
    }
    
    // MARK: - Public Methods
    
    /// Loads available fields for selection
    func loadFields() async {
        isLoading = true
        error = nil
        
        do {
            let allFields = try await threadRepository.fetchCustomFields(
                for: threadId,
                includeDeleted: false
            )
            
            // Build parent-child relationships
            buildFieldHierarchy(from: allFields)
            
        } catch {
            self.error = "Failed to load fields: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    /// Toggles selection state for a field
    func toggleField(_ fieldId: UUID) {
        guard let fieldIndex = findFieldIndex(fieldId) else { return }
        
        let field = getField(at: fieldIndex)
        
        if field.field.isGroup {
            // Toggle group and all its children
            toggleGroup(fieldId)
        } else {
            // Toggle individual field
            if selectedFieldIds.contains(fieldId) {
                selectedFieldIds.remove(fieldId)
            } else {
                selectedFieldIds.insert(fieldId)
            }
            updateSelectableField(fieldId, isSelected: selectedFieldIds.contains(fieldId))
        }
    }
    
    /// Selects all fields in a group
    func selectGroup(_ groupId: UUID) {
        guard let groupIndex = selectableFields.firstIndex(where: { $0.id == groupId }),
              selectableFields[groupIndex].field.isGroup else { return }
        
        // Select the group
        selectedFieldIds.insert(groupId)
        selectableFields[groupIndex].isSelected = true
        
        // Select all child fields
        for childField in selectableFields[groupIndex].childFields {
            selectedFieldIds.insert(childField.id)
            if let childIndex = selectableFields[groupIndex].childFields.firstIndex(where: { $0.id == childField.id }) {
                selectableFields[groupIndex].childFields[childIndex].isSelected = true
            }
        }
    }
    
    /// Clears all selections
    func clearSelection() {
        selectedFieldIds.removeAll()
        
        // Update all selectable fields
        for i in 0..<selectableFields.count {
            selectableFields[i].isSelected = false
            for j in 0..<selectableFields[i].childFields.count {
                selectableFields[i].childFields[j].isSelected = false
            }
        }
    }
    
    /// Restores selection state from previously selected field IDs
    func restoreSelection(fieldIds: Set<UUID>) {
        clearSelection()
        
        for fieldId in fieldIds {
            if findFieldIndex(fieldId) != nil {
                selectedFieldIds.insert(fieldId)
                updateSelectableField(fieldId, isSelected: true)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func buildFieldHierarchy(from fields: [CustomField]) {
        // First pass: identify parent-child relationships
        // In a real implementation, this would use the actual parent-child data
        // For now, we'll create a flat structure with groups at the top level
        
        var rootFields: [SelectableField] = []
        var childFieldsMap: [UUID: [CustomField]] = [:]
        
        // For this implementation, we'll treat all non-group fields as root fields
        // and group fields as containers
        for field in fields {
            if field.isGroup {
                rootFields.append(SelectableField(
                    field: field,
                    isSelected: selectedFieldIds.contains(field.id),
                    childFields: []
                ))
            }
        }
        
        // Add non-group fields
        for field in fields where !field.isGroup {
            rootFields.append(SelectableField(
                field: field,
                isSelected: selectedFieldIds.contains(field.id),
                childFields: []
            ))
        }
        
        // Sort by order
        rootFields.sort { $0.field.order < $1.field.order }
        
        selectableFields = rootFields
    }
    
    private func findFieldIndex(_ fieldId: UUID) -> (parent: Int, child: Int?)? {
        for (parentIndex, field) in selectableFields.enumerated() {
            if field.id == fieldId {
                return (parentIndex, nil)
            }
            
            for (childIndex, childField) in field.childFields.enumerated() {
                if childField.id == fieldId {
                    return (parentIndex, childIndex)
                }
            }
        }
        return nil
    }
    
    private func getField(at index: (parent: Int, child: Int?)) -> SelectableField {
        if let childIndex = index.child {
            return selectableFields[index.parent].childFields[childIndex]
        } else {
            return selectableFields[index.parent]
        }
    }
    
    private func updateSelectableField(_ fieldId: UUID, isSelected: Bool) {
        guard let index = findFieldIndex(fieldId) else { return }
        
        if let childIndex = index.child {
            selectableFields[index.parent].childFields[childIndex].isSelected = isSelected
        } else {
            selectableFields[index.parent].isSelected = isSelected
        }
    }
    
    private func toggleGroup(_ groupId: UUID) {
        guard let groupIndex = selectableFields.firstIndex(where: { $0.id == groupId }) else { return }
        
        let group = selectableFields[groupIndex]
        let newSelectionState = !group.isSelected
        
        // Toggle group selection
        if newSelectionState {
            selectedFieldIds.insert(groupId)
        } else {
            selectedFieldIds.remove(groupId)
        }
        selectableFields[groupIndex].isSelected = newSelectionState
        
        // Toggle all child fields
        for i in 0..<selectableFields[groupIndex].childFields.count {
            let childId = selectableFields[groupIndex].childFields[i].id
            if newSelectionState {
                selectedFieldIds.insert(childId)
            } else {
                selectedFieldIds.remove(childId)
            }
            selectableFields[groupIndex].childFields[i].isSelected = newSelectionState
        }
    }
}