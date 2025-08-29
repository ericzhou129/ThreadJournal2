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

## Voice Entry

ThreadJournal includes an advanced voice-to-text feature that enables users to create journal entries through speech recognition. The feature is designed with privacy and performance in mind.

### Key Features
- **Complete privacy**: All transcription happens on-device using bundled Core ML models
- **Zero configuration**: No model downloads or setup required - ready to use immediately
- **Real-time transcription**: See your words appear as you speak with live partial results
- **Multilingual support**: Supports 99+ languages with automatic language detection
- **Intelligent processing**: Stop & Edit for revision, Stop & Save for immediate entry creation
- **Safety features**: 5-minute maximum recording length with automatic stop

### Usage
1. Open any thread in ThreadJournal
2. Tap the microphone button below the compose area
3. Grant microphone permission when prompted (first time only)
4. Tap and hold to speak, or tap once to start/stop recording
5. Choose "Stop & Edit" to review and modify the transcription
6. Choose "Stop & Save" to create the entry immediately

### System Requirements
- iOS 17.0 or later
- iPhone 12 or newer recommended for optimal performance
- Approximately 39MB additional app size for bundled speech models

### Privacy
All voice processing occurs entirely on your device. No audio data is ever transmitted to external servers, ensuring complete privacy of your journal entries.

## Performance

ThreadJournal is designed to handle large datasets efficiently:

- **Thread List**: Loads 100 threads in < 200ms
- **Thread Detail**: Opens threads with 1000 entries in < 300ms  
- **Entry Creation**: Adds new entries in < 50ms
- **Voice Transcription**: First partial results in < 1 second on supported devices
- **CSV Export**: Exports 1000 entries in < 3 seconds
- **Memory Usage**: Stays under 150MB with 100 threads and 15,000 entries

See [Performance Benchmarks](ThreadJournal2Tests/Performance/PERFORMANCE_BENCHMARKS.md) for detailed metrics and testing methodology.

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
│   ├── Architecture/        # Architecture compliance tests
│   └── Performance/         # Performance benchmark tests
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