//
//  CreateCustomFieldUseCase.swift
//  ThreadJournal2
//
//  Use case for creating custom fields with validation
//

import Foundation

/// Protocol defining the create custom field use case
protocol CreateCustomFieldUseCaseProtocol {
    func execute(
        threadId: UUID,
        name: String,
        order: Int
    ) async throws -> CustomField
}

/// Use case for creating a new custom field
final class CreateCustomFieldUseCase: CreateCustomFieldUseCaseProtocol {
    private let threadRepository: ThreadRepository
    private let maxFieldsPerThread = 20
    
    init(threadRepository: ThreadRepository) {
        self.threadRepository = threadRepository
    }
    
    func execute(
        threadId: UUID,
        name: String,
        order: Int
    ) async throws -> CustomField {
        // Fetch existing fields to validate
        let existingFields = try await threadRepository.fetchCustomFields(
            for: threadId,
            includeDeleted: false
        )
        
        // Validate field count limit
        guard existingFields.count < maxFieldsPerThread else {
            throw CustomFieldError.maxFieldsExceeded
        }
        
        // Validate name uniqueness within thread
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let nameExists = existingFields.contains { field in
            field.name.lowercased() == trimmedName.lowercased()
        }
        
        guard !nameExists else {
            throw CustomFieldError.duplicateFieldName
        }
        
        // Create the field
        let field = try CustomField(
            threadId: threadId,
            name: trimmedName,
            order: order
        )
        
        // Save to repository
        try await threadRepository.createCustomField(field)
        
        return field
    }
}

/// Errors specific to custom field operations
enum CustomFieldError: LocalizedError {
    case maxFieldsExceeded
    case duplicateFieldName
    case invalidGroupConfiguration
    
    var errorDescription: String? {
        switch self {
        case .maxFieldsExceeded:
            return "Maximum of 20 fields allowed per thread"
        case .duplicateFieldName:
            return "A field with this name already exists"
        case .invalidGroupConfiguration:
            return "Invalid group configuration"
        }
    }
}