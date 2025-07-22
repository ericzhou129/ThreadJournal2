# ThreadJournal2

A Swift-based journaling application built with Clean Architecture and SwiftUI.

## Architecture Overview

This project follows Clean Architecture principles with MVVM pattern in the presentation layer. The architecture ensures separation of concerns, testability, and maintainability.

### Layer Structure

```
ThreadJournal2/
├── Domain/          # Core business logic and entities
├── Application/     # Use cases and application-specific business rules
├── Interface/       # UI layer (SwiftUI views, ViewModels)
└── Infrastructure/  # External services, data persistence
```

### Architecture Rules

1. **Domain Layer**
   - Contains entities, value objects, and domain services
   - No external dependencies
   - Pure Swift code only
   - Defines protocols for repositories and services

2. **Application Layer**
   - Contains use cases (interactors)
   - Orchestrates the flow of data
   - Imports Domain layer only
   - Implements application-specific business rules

3. **Interface Layer**
   - Contains SwiftUI views and ViewModels
   - Implements MVVM pattern
   - Can import Application and Domain layers
   - Handles all UI-related logic and state management

4. **Infrastructure Layer**
   - Contains implementations of repositories
   - Handles data persistence (Core Data, UserDefaults, etc.)
   - Manages external service integrations
   - Imports Domain layer only

### Dependency Flow

```
Interface ──┐
            ├──> Application ──> Domain
Infrastructure ─────────────────────┘
```

## Development Setup

### Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ deployment target
- SwiftLint (install via Homebrew: `brew install swiftlint`)

### Getting Started

1. Clone the repository
2. Open `ThreadJournal2.xcodeproj` in Xcode
3. Build and run the project

### Code Quality

This project uses SwiftLint to maintain code quality. Key rules:
- Maximum line length: 100 characters
- Maximum file length: 200 lines
- Maximum method length: 15 lines
- Maximum cyclomatic complexity: 5

Run SwiftLint:
```bash
swiftlint
```

## CI/CD

The project uses GitHub Actions for continuous integration. The CI pipeline:
- Runs SwiftLint checks
- Builds the project
- Runs unit and UI tests
- Generates code coverage reports

## Project Structure

```
ThreadJournal2/
├── .github/
│   └── workflows/
│       └── ci.yml           # CI pipeline configuration
├── ThreadJournal2/
│   ├── Domain/              # Business logic layer
│   ├── Application/         # Use cases layer
│   ├── Interface/           # UI layer
│   ├── Infrastructure/      # Data and external services
│   └── Assets.xcassets/     # Image and color assets
├── ThreadJournal2Tests/     # Unit tests
├── ThreadJournal2UITests/   # UI tests
├── .swiftlint.yml          # SwiftLint configuration
└── .gitignore              # Git ignore rules
```

## Contributing

1. Follow the Clean Architecture principles
2. Ensure all tests pass before submitting PR
3. Run SwiftLint and fix any warnings
4. Keep methods small and focused (max 15 lines)
5. Write unit tests for new functionality

## License

[Add your license information here]