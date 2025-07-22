# Architecture Tests

This directory contains automated tests to enforce Clean Architecture boundaries in the ThreadJournal2 project.

## Overview

The architecture tests ensure that the codebase follows Clean Architecture principles by verifying:

1. **Layer Independence**: Each layer only depends on allowed layers
2. **Import Restrictions**: Layers don't import forbidden frameworks
3. **Use Case Design**: Use cases follow the single public method pattern
4. **Code Organization**: Files are in the correct directories

## Test Files

### FileScanner.swift
Utility class that scans Swift files and analyzes their imports. Used by all architecture tests.

### ArchitectureTests.swift
Comprehensive tests for layer dependencies and import rules:
- Domain layer has no UI or persistence imports
- Application layer has no UI or persistence imports
- Interface layer has no persistence imports
- Infrastructure layer has no UI imports
- Use cases have single public execute() method

### ArchitectureViolationTests.swift
Additional tests for code organization and conventions:
- Naming conventions for use cases and repositories
- Dependency injection patterns
- Circular dependency detection
- Protocol conformance checks

### ArchitectureCITests.swift
CI-focused test that will fail the build on any architecture violation. This is the main test to run in CI pipelines.

## Architecture Rules

### Domain Layer
- ✅ Can import: Foundation only
- ❌ Cannot import: UIKit, SwiftUI, CoreData, Combine
- Contains: Entities, Repository protocols, Value objects

### Application Layer
- ✅ Can import: Foundation, Domain layer
- ❌ Cannot import: UIKit, SwiftUI, CoreData
- Contains: Use cases, Application services

### Interface Layer
- ✅ Can import: Foundation, SwiftUI, UIKit, Combine, Domain, Application
- ❌ Cannot import: CoreData
- Contains: Views, ViewModels, UI components

### Infrastructure Layer
- ✅ Can import: Foundation, CoreData, Combine, Domain
- ❌ Cannot import: UIKit, SwiftUI
- Contains: Repository implementations, External service adapters

## Running Tests

### In Xcode
1. Open the ThreadJournal2 project
2. Press `Cmd+U` to run all tests
3. Or navigate to Test Navigator and run specific architecture tests

### Command Line
```bash
# Run all tests
xcodebuild test -scheme ThreadJournal2 -destination 'platform=iOS Simulator,name=iPhone 15'

# Run only architecture tests
xcodebuild test -scheme ThreadJournal2 -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:ThreadJournal2Tests/ArchitectureCITests
```

### CI Integration
Add to your CI pipeline (e.g., GitHub Actions):

```yaml
- name: Run Architecture Tests
  run: |
    xcodebuild test \
      -scheme ThreadJournal2 \
      -destination 'platform=iOS Simulator,name=iPhone 15' \
      -only-testing:ThreadJournal2Tests/ArchitectureCITests \
      | xcpretty --test --color
```

## Adding New Architecture Rules

To add new architecture rules:

1. Add the check to the appropriate test file
2. Update `ArchitectureCITests.swift` if it's a critical rule
3. Document the rule in this README

## Fixing Violations

When architecture tests fail:

1. Read the error message to understand which rule was violated
2. Check the file mentioned in the error
3. Fix the import or move the file to the correct layer
4. Run tests again to verify the fix

## Examples

### ❌ Bad: Domain entity importing UIKit
```swift
// Domain/Entities/Thread.swift
import Foundation
import UIKit  // ❌ Domain layer cannot import UI frameworks

struct Thread {
    // ...
}
```

### ✅ Good: Domain entity with only Foundation
```swift
// Domain/Entities/Thread.swift
import Foundation

struct Thread {
    // ...
}
```

### ❌ Bad: Use case with multiple public methods
```swift
// Application/UseCases/CreateThreadUseCase.swift
public class CreateThreadUseCase {
    public func execute() { }     // ✅
    public func validate() { }    // ❌ Only execute() should be public
}
```

### ✅ Good: Use case with single public execute method
```swift
// Application/UseCases/CreateThreadUseCase.swift
public class CreateThreadUseCase {
    public func execute() { }     // ✅
    private func validate() { }   // ✅ Other methods are private
}
```