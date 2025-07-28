//
//  Thread.swift
//  ThreadJournal2
//
//  Domain entity representing a journal thread
//

import Foundation

/// A continuous conversation/journal on a specific topic
struct Thread: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let createdAt: Date
    let updatedAt: Date
    let deletedAt: Date?
    
    /// Creates a new Thread with validation
    /// - Parameters:
    ///   - id: Unique identifier for the thread
    ///   - title: The title of the thread (cannot be empty)
    ///   - createdAt: Creation timestamp
    ///   - updatedAt: Last update timestamp
    ///   - deletedAt: Deletion timestamp for soft delete (nil if not deleted)
    /// - Throws: ValidationError if title is empty
    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        deletedAt: Date? = nil
    ) throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyTitle
        }
        
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.deletedAt = deletedAt
    }
    
    /// Indicates whether this thread has been soft deleted
    var isDeleted: Bool {
        deletedAt != nil
    }
}

/// Validation errors for domain entities
enum ValidationError: Error, LocalizedError {
    case emptyTitle
    case emptyContent
    
    var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Thread title cannot be empty"
        case .emptyContent:
            return "Entry content cannot be empty"
        }
    }
}