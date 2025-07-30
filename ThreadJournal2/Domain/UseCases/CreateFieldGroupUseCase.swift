//
//  CreateFieldGroupUseCase.swift
//  ThreadJournal2
//
//  Use case for creating field groups
//

import Foundation

/// Protocol defining the create field group use case
protocol CreateFieldGroupUseCaseProtocol {
    func execute(
        parentFieldId: UUID,
        childFieldIds: [UUID]
    ) async throws -> CustomFieldGroup
}

/// Use case for creating or updating a field group
final class CreateFieldGroupUseCase: CreateFieldGroupUseCaseProtocol {
    private let threadRepository: ThreadRepository
    
    init(threadRepository: ThreadRepository) {
        self.threadRepository = threadRepository
    }
    
    func execute(
        parentFieldId: UUID,
        childFieldIds: [UUID]
    ) async throws -> CustomFieldGroup {
        // Fetch all fields to validate the group
        guard let parentField = try await fetchField(id: parentFieldId) else {
            throw PersistenceError.notFound(id: parentFieldId)
        }
        
        // Convert parent field to group if needed
        var updatedParentField = parentField
        if !parentField.isGroup {
            updatedParentField = try CustomField(
                id: parentField.id,
                threadId: parentField.threadId,
                name: parentField.name,
                order: parentField.order,
                isGroup: true
            )
            try await threadRepository.updateCustomField(updatedParentField)
        }
        
        // Fetch child fields
        let childFields = try await fetchFields(ids: childFieldIds, threadId: parentField.threadId)
        
        // Validate no nested groups
        if childFields.contains(where: { $0.isGroup }) {
            throw ValidationError.nestedGroupsNotAllowed
        }
        
        // Create the group relationship
        let group = try CustomFieldGroup(
            parentField: updatedParentField,
            childFields: childFields
        )
        
        // Save the group relationship
        try await threadRepository.createFieldGroup(
            parentFieldId: parentFieldId,
            childFieldIds: childFieldIds
        )
        
        return group
    }
    
    private func fetchField(id: UUID) async throws -> CustomField? {
        // This is a workaround since we don't have a direct fetch by ID
        // In a real implementation, we'd add this to the repository
        let allThreads = try await threadRepository.fetchAll()
        
        for thread in allThreads {
            let fields = try await threadRepository.fetchCustomFields(
                for: thread.id,
                includeDeleted: false
            )
            if let field = fields.first(where: { $0.id == id }) {
                return field
            }
        }
        
        return nil
    }
    
    private func fetchFields(ids: [UUID], threadId: UUID) async throws -> [CustomField] {
        let allFields = try await threadRepository.fetchCustomFields(
            for: threadId,
            includeDeleted: false
        )
        
        return ids.compactMap { id in
            allFields.first(where: { $0.id == id })
        }
    }
}