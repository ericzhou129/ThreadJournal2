# Core Data Thread Repository

This directory contains the Core Data implementation of the `ThreadRepository` protocol for persisting threads and entries.

## Files

### CoreDataThreadRepository.swift
The main repository implementation that:
- Implements all CRUD operations from the `ThreadRepository` protocol
- Handles Core Data context management and concurrency
- Includes retry logic (3 attempts) for transient failures
- Maps between Core Data managed objects and domain entities
- Provides proper error handling with `PersistenceError` and `ValidationError`

### PersistenceController.swift
Manages the Core Data stack:
- Provides singleton access to the persistent container
- Creates repository instances
- Includes preview instance for SwiftUI previews with sample data
- Supports in-memory store for testing

### CoreDataThreadRepositoryExample.swift
Demonstrates usage patterns:
- Creating threads and entries
- Fetching and displaying data
- Updating existing threads
- Error handling examples
- Deletion with cascade

### CoreDataThreadRepositoryTests.swift
Comprehensive test suite using in-memory Core Data:
- Tests all CRUD operations
- Validates error handling
- Tests cascade deletion
- Verifies sorting and relationships

## Key Features

### Error Handling
The repository implements comprehensive error handling:
- **PersistenceError.saveFailed**: Thrown when save operations fail after retries
- **PersistenceError.fetchFailed**: Thrown when fetch operations fail
- **PersistenceError.notFound**: Thrown when updating/deleting non-existent resources
- **ValidationError.emptyTitle**: Thrown for empty thread titles
- **ValidationError.emptyContent**: Thrown for empty entry content

### Retry Logic
Save operations automatically retry up to 3 times with exponential backoff:
- 1st retry: 0.1 seconds delay
- 2nd retry: 0.2 seconds delay
- 3rd retry: 0.4 seconds delay

Validation errors and not-found errors are not retried.

### Concurrency
All operations are properly synchronized using Core Data's `perform` and async/await:
- Thread-safe access to managed object context
- Proper context rollback on errors
- Automatic merging of changes from parent context

### Data Mapping
The repository handles mapping between:
- Core Data `NSManagedObject` instances
- Domain entities (`Thread` and `Entry`)

This separation ensures the domain layer remains independent of Core Data.

## Usage

```swift
// Get repository instance
let repository = PersistenceController.shared.makeThreadRepository()

// Create a thread
let thread = try Thread(title: "My Journal")
try await repository.create(thread: thread)

// Add an entry
let entry = try Entry(threadId: thread.id, content: "Today's thoughts...")
try await repository.addEntry(entry, to: thread.id)

// Fetch all threads
let threads = try await repository.fetchAll()

// Delete a thread (cascades to entries)
try await repository.delete(threadId: thread.id)
```

## Testing

The repository can be tested with an in-memory Core Data stack:

```swift
let container = NSPersistentContainer(name: "ThreadDataModel")
let description = NSPersistentStoreDescription()
description.type = NSInMemoryStoreType
container.persistentStoreDescriptions = [description]

let repository = CoreDataThreadRepository(persistentContainer: container)
```

This allows for fast, isolated tests without touching the file system.