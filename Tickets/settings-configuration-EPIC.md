# Settings & Configuration EPIC

## Epic Overview
Implement a settings screen for ThreadJournal that provides essential app configuration options. The focus is on privacy-first biometric authentication (Face ID/Touch ID) that requires authentication every time the app opens with no grace period, along with display preferences and app information.

## Key Design Decisions
- **Strict Biometric Authentication**: No grace period - authentication required EVERY time the app opens or returns from background
- **No iCloud Sync**: Deferred to future release, keeping the app fully local-first
- **Simplified Settings**: Only essential settings included - biometric auth, text size, and about section

## Design Reference
- Mock-up: `/Design/settings-configuration-mockup.html`

## Technical Architecture
- See TIP Section 6.2 for Settings & Configuration Implementation details
- Biometric authentication integrated at app lifecycle level
- Settings stored in UserDefaults with structured UserSettings entity

---

## TICKETS

### settings-config-TICKET-001: Create Settings Domain Layer
**Story ID**: settings-config-TICKET-001  
**Context/Layer**: Settings / domain  
**As a** developer  
**I want** domain entities and use cases for settings  
**So that** the app can manage user preferences with clean architecture  

**Acceptance Criteria**:
1. Create `Domain/Entities/UserSettings.swift` with biometricAuthEnabled and textSizePercentage properties
2. Create `Domain/UseCases/UpdateSettingsUseCase.swift` protocol and implementation
3. Create `Domain/UseCases/GetSettingsUseCase.swift` protocol and implementation
4. Create `Domain/Repositories/SettingsRepository.swift` protocol
5. All entities are value types (structs)
6. No UI or infrastructure imports in domain layer
- [Arch-Lint] Domain layer has no external dependencies
- [Coverage] 100% unit test coverage for use cases
- [Doc] Business rules documented

**Technical Implementation**:
- See TIP Section 6.2 for UserSettings entity structure
- Text size range: 80-150% with 10% increments
- Settings repository protocol for persistence abstraction

**QA Test Criteria**:
1. Test UpdateSettingsUseCase validates text size range (80-150)
2. Test GetSettingsUseCase returns default values when no settings exist
3. Verify domain layer has no UI/Infrastructure imports
4. Test settings are immutable value types

**Priority Score**: 8 (WSJF) - Foundation for all settings features  
**Dependencies**: None

---

### settings-config-TICKET-002: Implement Settings Repository
**Story ID**: settings-config-TICKET-002  
**Context/Layer**: Settings / infrastructure  
**As a** developer  
**I want** a UserDefaults-based settings repository  
**So that** user preferences persist between app launches  

**Acceptance Criteria**:
1. Create `Infrastructure/Persistence/UserDefaultsSettingsRepository.swift`
2. Implement SettingsRepository protocol from TICKET-001
3. Store settings as Codable JSON in UserDefaults
4. Provide default values when no settings exist
5. Handle UserDefaults read/write errors gracefully
- [Arch-Lint] Repository contains no business logic
- [Coverage] Unit tests with mocked UserDefaults
- [Doc] Error handling documented

**Technical Implementation**:
```swift
final class UserDefaultsSettingsRepository: SettingsRepository {
    private let defaults = UserDefaults.standard
    private let key = "ThreadJournal.UserSettings"
    
    func get() async throws -> UserSettings {
        // Decode from UserDefaults or return defaults
    }
    
    func save(_ settings: UserSettings) async throws {
        // Encode and save to UserDefaults
    }
}
```

**QA Test Criteria**:
1. Test settings persist across repository instances
2. Test default values returned when no settings exist
3. Test error handling for corrupted data
4. Verify thread-safe access to UserDefaults

**Priority Score**: 8 (WSJF) - Required for settings persistence  
**Dependencies**: settings-config-TICKET-001

---

### settings-config-TICKET-003: Biometric Authentication Service
**Story ID**: settings-config-TICKET-003  
**Context/Layer**: Settings / infrastructure  
**As a** developer  
**I want** a biometric authentication service  
**So that** the app can protect user privacy with Face ID/Touch ID  

**Acceptance Criteria**:
1. Create `Infrastructure/Security/BiometricAuthService.swift`
2. Implement authentication with LocalAuthentication framework
3. NO grace period - always require fresh authentication
4. Check biometric availability before attempting authentication
5. Provide clear error messages for different failure scenarios
6. Support both Face ID and Touch ID based on device
- [Arch-Lint] Service has single responsibility
- [Coverage] Unit tests with mocked LAContext
- [Doc] Error cases documented

**Technical Implementation**:
- See TIP Section 6.2 for BiometricAuthService implementation
- Use LAContext for biometric evaluation
- Keychain integration for storing biometric preference
- Async/await API with proper error handling

**QA Test Criteria**:
1. Test authentication success/failure paths
2. Test biometric availability detection
3. Test error handling for different LAError types
4. Verify no grace period - authentication always required
5. Test on devices with Face ID and Touch ID

**Priority Score**: 9 (WSJF) - Critical privacy feature  
**Dependencies**: None

---

### settings-config-TICKET-004: Settings Screen UI
**Story ID**: settings-config-TICKET-004  
**Context/Layer**: Settings / interface  
**As a** user  
**I am able to** access and configure app settings  
**So that** I can customize my journal experience and protect my privacy  

**Acceptance Criteria**:
1. Settings screen accessible from gear icon in thread list navigation bar
2. Security section with "Require Face ID" toggle (on by default if available)
3. Display section with text size stepper (80-150%, 10% increments)
4. About section with Privacy Policy link, Support email, and Version info
5. Navigation bar with centered "Settings" title and "Done" button
6. Privacy notice explaining no grace period for biometric auth
- [Arch-Lint] SwiftUI view uses ViewModel for all logic
- [Coverage] UI test for navigation and interactions
- [Doc] Component matches Design: settings-configuration-mockup.html

**Component Reference**:
- Design: `/Design/settings-configuration-mockup.html`
- Security note UI with yellow background (#FFF3CD)
- Standard iOS settings layout with sections

**Technical Implementation**:
- Create `Interface/Screens/SettingsScreen.swift`
- Use `@StateObject var viewModel: SettingsViewModel`
- Navigation from ThreadListScreen toolbar
- Sheet presentation with "Done" button to dismiss

**QA Test Criteria**:
1. Verify settings screen opens from thread list
2. Test Face ID toggle enables/disables correctly
3. Test text size stepper within 80-150% range
4. Test Privacy Policy navigation
5. Verify "Done" button dismisses screen
6. Test Dynamic Type support

**Priority Score**: 9 (WSJF) - Primary user interface  
**Dependencies**: settings-config-TICKET-005

---

### settings-config-TICKET-005: Settings ViewModel
**Story ID**: settings-config-TICKET-005  
**Context/Layer**: Settings / application  
**As a** developer  
**I want** a ViewModel to manage settings state  
**So that** the UI remains decoupled from business logic  

**Acceptance Criteria**:
1. Create `Application/ViewModels/SettingsViewModel.swift`
2. Published properties for all settings values and UI state
3. Methods to toggle biometric auth and update text size
4. Load current settings on initialization
5. Save settings immediately on any change
6. Check biometric availability before enabling
- [Arch-Lint] ViewModel only orchestrates use cases
- [Coverage] Unit tests with mocked dependencies
- [Doc] Published properties documented

**Technical Implementation**:
- See TIP Section 6.2 for SettingsViewModel structure
- Inject UpdateSettingsUseCase and GetSettingsUseCase
- Inject BiometricAuthService for availability check
- @Published properties for reactive UI updates

**QA Test Criteria**:
1. Test settings load on initialization
2. Test biometric toggle saves immediately
3. Test text size changes save immediately
4. Test biometric availability check
5. Verify proper error handling

**Priority Score**: 8 (WSJF) - Required for UI functionality  
**Dependencies**: settings-config-TICKET-001, settings-config-TICKET-002, settings-config-TICKET-003

---

### settings-config-TICKET-006: App Lifecycle Authentication
**Story ID**: settings-config-TICKET-006  
**Context/Layer**: Settings / interface  
**As a** user  
**I must** authenticate with Face ID/Touch ID every time I open the app  
**So that** my journal entries remain private even if someone picks up my device  

**Acceptance Criteria**:
1. Modify `ThreadJournalApp.swift` to check authentication on launch
2. Show authentication screen if biometric is enabled
3. Require authentication when app returns from background (no grace period)
4. Lock immediately when app goes to background
5. Show retry option if authentication fails
6. Skip authentication if biometric is disabled in settings
- [Arch-Lint] App lifecycle properly managed
- [Coverage] Integration tests for app states
- [Doc] Authentication flow documented

**Technical Implementation**:
- See TIP Section 6.2 for App Lifecycle Integration
- Use ScenePhase to detect app state changes
- Create AuthenticationRequiredView for locked state
- Integrate BiometricAuthService at app level

**QA Test Criteria**:
1. Test app requires auth on fresh launch
2. Test app requires auth when returning from background
3. Test immediate lock when backgrounding
4. Test retry flow on auth failure
5. Test skip auth when biometric disabled
6. No grace period - verify immediate auth requirement

**Priority Score**: 10 (WSJF) - Critical privacy protection  
**Dependencies**: settings-config-TICKET-003, settings-config-TICKET-005

---

### settings-config-TICKET-007: Settings UI Components
**Story ID**: settings-config-TICKET-007  
**Context/Layer**: Settings / interface  
**As a** developer  
**I want** reusable settings UI components  
**So that** the settings screen has consistent, iOS-native appearance  

**Acceptance Criteria**:
1. Create `Interface/Components/SettingsToggleRow.swift` for toggle settings
2. Create `Interface/Components/SettingsStepperRow.swift` for numeric settings
3. Create `Interface/Components/SettingsLinkRow.swift` for navigation rows
4. Standard iOS settings appearance with proper spacing
5. Support for section headers and footers
6. Async action support for toggle changes
- [Arch-Lint] Components are pure presentation
- [Coverage] Snapshot tests for components
- [Doc] Component API documented

**Technical Implementation**:
- See TIP Section 6.2 for component implementations
- Reusable row components with consistent styling
- Support for async actions on value changes
- Standard iOS insets and typography

**QA Test Criteria**:
1. Test toggle row appearance and interaction
2. Test stepper row with min/max limits
3. Test link row navigation
4. Verify consistent spacing/styling
5. Test with Dynamic Type

**Priority Score**: 7 (WSJF) - Supports main settings UI  
**Dependencies**: None

---

### settings-config-TICKET-008: Privacy Policy View
**Story ID**: settings-config-TICKET-008  
**Context/Layer**: Settings / interface  
**As a** user  
**I am able to** read the privacy policy  
**So that** I understand how my data is handled  

**Acceptance Criteria**:
1. Create `Interface/Screens/PrivacyPolicyView.swift`
2. Display privacy policy content from settings
3. Navigation from Settings > About > Privacy Policy
4. Include sections: data collection, storage, security, contact
5. Emphasize local-only storage and biometric protection
6. Scrollable content with proper formatting
- [Arch-Lint] View contains only presentation logic
- [Coverage] UI test for navigation
- [Doc] Privacy policy content accurate

**Technical Implementation**:
- Static SwiftUI view with formatted text
- NavigationLink from settings screen
- Markdown or structured text content
- Emphasize no cloud storage, strict biometric auth

**QA Test Criteria**:
1. Test navigation from settings
2. Verify all sections present
3. Test scrolling for long content
4. Verify back navigation works
5. Test text remains readable

**Priority Score**: 6 (WSJF) - Required for app store  
**Dependencies**: settings-config-TICKET-004

---

### settings-config-TICKET-009: Text Size Integration
**Story ID**: settings-config-TICKET-009  
**Context/Layer**: Settings / interface  
**As a** user  
**I want** my chosen text size to apply to journal entries  
**So that** I can read my journal comfortably  

**Acceptance Criteria**:
1. Modify entry display components to respect text size setting
2. Apply percentage scaling to entry content text only
3. Keep timestamps and UI elements at standard size
4. Update immediately when setting changes
5. Persist text size across app launches
6. Default to 100% for new users
- [Arch-Lint] Text size applied at presentation layer
- [Coverage] Visual regression tests
- [Doc] Integration points documented

**Technical Implementation**:
- Inject settings into ThreadDetailViewModel
- Apply scaling to content font size
- Use @ScaledMetric for proper scaling
- EnvironmentObject for settings propagation

**QA Test Criteria**:
1. Test 80% makes text smaller
2. Test 150% makes text larger
3. Test immediate update on change
4. Test persistence across launches
5. Verify only content text scales

**Priority Score**: 7 (WSJF) - Accessibility feature  
**Dependencies**: settings-config-TICKET-001, settings-config-TICKET-005

---

### settings-config-TICKET-010: Settings Error Handling
**Story ID**: settings-config-TICKET-010  
**Context/Layer**: Settings / application  
**As a** developer  
**I want** proper error handling for settings operations  
**So that** the app gracefully handles edge cases  

**Acceptance Criteria**:
1. Handle biometric not available on device
2. Handle user declining biometric permission
3. Handle settings storage failures
4. Show appropriate user-facing error messages
5. Fall back to defaults on read errors
6. Log errors for debugging (DEBUG only)
- [Arch-Lint] Errors handled at appropriate layers
- [Coverage] Error path unit tests
- [Doc] Error scenarios documented

**Technical Implementation**:
- Create SettingsError enum for typed errors
- Alert presentations in ViewModel
- Graceful fallbacks for all operations
- User-friendly error messages

**QA Test Criteria**:
1. Test biometric unavailable device
2. Test permission denial flow
3. Test corrupted settings recovery
4. Verify user sees clear messages
5. Test app remains functional

**Priority Score**: 7 (WSJF) - Robustness requirement  
**Dependencies**: settings-config-TICKET-001 through settings-config-TICKET-009

---

## Success Criteria
1. Settings screen accessible from thread list
2. Biometric authentication works with NO grace period
3. Text size preference applies to journal entries
4. Settings persist between app launches
5. Privacy policy viewable
6. All error cases handled gracefully

## Technical Notes
- See TIP Section 6.2 for detailed implementation guidance
- UserDefaults for settings storage (no Core Data needed)
- LocalAuthentication framework for biometric auth
- Settings should load quickly (< 50ms)
- No network calls or external dependencies