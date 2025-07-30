//
//  DeleteCustomFieldUseCase.swift
//  ThreadJournal2
//
//  Use case for deleting custom fields
//

import Foundation

/// Protocol defining the delete custom field use case
protocol DeleteCustomFieldUseCaseProtocol {
    func execute(
        fieldId: UUID,
        preserveHistoricalData: Bool
    ) async throws
}

/// Use case for deleting a custom field
final class DeleteCustomFieldUseCase: DeleteCustomFieldUseCaseProtocol {
    private let threadRepository: ThreadRepository
    
    init(threadRepository: ThreadRepository) {
        self.threadRepository = threadRepository
    }
    
    func execute(
        fieldId: UUID,
        preserveHistoricalData: Bool
    ) async throws {
        // For now, we always preserve historical data by soft deleting
        // This matches the requirement that historical data should be preserved
        if preserveHistoricalData {
            try await threadRepository.softDeleteCustomField(fieldId: fieldId)
        } else {
            // In the future, we might support hard delete
            // For now, still soft delete
            try await threadRepository.softDeleteCustomField(fieldId: fieldId)
        }
        
        // Note: Cascade deletion for groups is handled by the repository
        // If this field is a group, its children will also be soft deleted
    }
}