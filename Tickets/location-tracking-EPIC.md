# Location Tracking EPIC

## Epic Overview
Implement location tracking functionality for ThreadJournal that automatically adds location context to journal entries. The feature integrates with the existing Settings menu and provides privacy-first location services with all data stored locally on device.

## Key Design Decisions
- **Privacy-First Approach**: All location data stored locally, never transmitted to servers
- **Automatic Addition**: Location added transparently to new entries when enabled
- **City-Level Precision**: Display city/state only for privacy (not exact coordinates)
- **Settings Integration**: Location preferences integrated into existing Settings screen
- **Permission Respect**: Graceful handling when location services denied

## Design Reference
- Mock-up: `/Design/settings-configuration-mockup.html` (Location section integrated)

## Technical Architecture
- See TIP Section 7 for Location Services Implementation details
- Core Location framework for location services
- Local storage for location preferences and cached location data
- Domain-driven approach with clean separation of concerns

---

## TICKETS

### location-tracking-TICKET-001: Enable location tracking in settings
**Story ID**: location-tracking-TICKET-001  
**Context/Layer**: Location / interface  
**As a** user  
**I am able to** enable location tracking in my settings  
**So that** location can be automatically added to my journal entries  

**Acceptance Criteria**:
1. "Add Location to Entries" toggle visible in Settings > Location section
2. Toggle default state is OFF (disabled) for new users
3. Toggling ON requests location permission if not granted
4. When enabled, shows current location as "City, State" format
5. "Show Current Location" row displays actual location when toggle is ON
6. Footer text explains privacy (local storage, not shared)
7. Settings persist between app launches
- [Arch-Lint] SwiftUI view uses ViewModel for all logic
- [Coverage] UI test for toggle and permission flow
- [Doc] Component matches Design: settings-configuration-mockup.html

**Component Reference**:
- Design: `/Design/settings-configuration-mockup.html` (Location section)

**Technical Implementation**:
- Integrate into existing `Interface/Screens/SettingsScreen.swift`
- Add location toggle and current location display
- Use `@StateObject var viewModel: SettingsViewModel` (extend existing)
- Request location permission when toggle enabled

**QA Test Criteria**:
1. Verify location toggle appears in settings
2. Test permission request when toggling ON
3. Test current location display when enabled
4. Test toggle persistence across app launches
5. Test graceful handling when permission denied

**Priority Score**: 9 (WSJF) - Primary user interface  
**Dependencies**: settings-configuration-EPIC (entire epic must be completed first)

---

### location-tracking-TICKET-002: Create location entities and use cases  
**Story ID**: location-tracking-TICKET-002  
**Context/Layer**: Location / domain  
**As a** developer  
**I want** domain entities and use cases for location services  
**So that** the app can manage location data with clean architecture  

**Acceptance Criteria**:
1. Create `Domain/Entities/LocationData.swift` with city, state, coordinates properties
2. Create `Domain/Entities/LocationSettings.swift` for user preferences  
3. Create `Domain/UseCases/GetCurrentLocationUseCase.swift` protocol and implementation
4. Create `Domain/UseCases/UpdateLocationSettingsUseCase.swift` protocol and implementation
5. Create `Domain/Repositories/LocationRepository.swift` protocol
6. All entities are value types (structs)
7. No Core Location or UI imports in domain layer
- [Arch-Lint] Domain layer has no external dependencies
- [Coverage] 100% unit test coverage for use cases
- [Doc] Business rules documented

**Technical Implementation**:
- See TIP Section 7 for LocationData and LocationSettings structure
- Location repository protocol for abstraction
- Use cases handle business logic for location operations

**QA Test Criteria**:
1. Test LocationData contains required properties
2. Test GetCurrentLocationUseCase protocol behavior
3. Test UpdateLocationSettingsUseCase validation
4. Verify domain layer has no external imports
5. Test location settings are immutable value types

**Priority Score**: 8 (WSJF) - Foundation for location features  
**Dependencies**: settings-configuration-EPIC

---

### location-tracking-TICKET-003: Implement Core Location service
**Story ID**: location-tracking-TICKET-003  
**Context/Layer**: Location / infrastructure  
**As a** developer  
**I want** a Core Location service for location data  
**So that** the app can access device location services  

**Acceptance Criteria**:
1. Create `Infrastructure/Services/CoreLocationService.swift`
2. Implement LocationRepository protocol from TICKET-002
3. Handle location permissions (request, check status)
4. Get current location with timeout and accuracy settings
5. Convert coordinates to city/state using reverse geocoding
6. Cache last known location for quick access
7. Handle all Core Location error scenarios gracefully
- [Arch-Lint] Service has single responsibility  
- [Coverage] Unit tests with mocked CLLocationManager
- [Doc] Permission flows documented

**Technical Implementation**:
- See TIP Section 7 for CoreLocationService implementation
- Use CLLocationManager for location services
- Implement reverse geocoding for city/state display
- Handle permission states: notDetermined, denied, authorizedWhenInUse

**QA Test Criteria**:
1. Test location permission request flow
2. Test current location retrieval
3. Test reverse geocoding to city/state
4. Test error handling for denied permissions
5. Test caching of last known location
6. Test timeout handling for location requests

**Priority Score**: 8 (WSJF) - Core location functionality  
**Dependencies**: location-tracking-TICKET-002

---

### location-tracking-TICKET-004: Add location to entry creation
**Story ID**: location-tracking-TICKET-004  
**Context/Layer**: Journaling / application  
**As a** user  
**I want** location automatically added to new entries when enabled  
**So that** my journal entries have location context  

**Acceptance Criteria**:
1. Modify AddEntryUseCase to optionally include location
2. Check location settings before adding location to entry
3. Get current location when creating new entry (if enabled)
4. Store location as part of entry data (city/state format)
5. Handle location unavailable gracefully (entry still created)
6. Don't block entry creation if location takes too long
7. Location added only when settings toggle is enabled
- [Arch-Lint] Use case orchestrates location and entry logic
- [Coverage] Unit tests for location integration scenarios
- [Doc] Location addition flow documented

**Technical Implementation**:
- Modify existing `Domain/UseCases/AddEntryUseCase.swift`
- Inject GetCurrentLocationUseCase dependency
- Add optional location field to Entry entity
- Timeout location requests (5 seconds max)

**QA Test Criteria**:
1. Test entry creation with location enabled
2. Test entry creation with location disabled  
3. Test entry creation when location unavailable
4. Test entry creation when location permission denied
5. Test location timeout doesn't block entry creation

**Priority Score**: 9 (WSJF) - Core functionality integration  
**Dependencies**: location-tracking-TICKET-002, location-tracking-TICKET-003

---

### location-tracking-TICKET-005: Display location in entry views
**Story ID**: location-tracking-TICKET-005  
**Context/Layer**: Journaling / interface  
**As a** user  
**I am able to** see location information in my journal entries  
**So that** I can remember where I wrote each entry  

**Acceptance Criteria**:
1. Modify entry display components to show location when available
2. Display location as "📍 City, State" format below timestamp
3. Location text uses secondary label color and smaller font
4. Location only displayed if entry has location data
5. Location text follows Dynamic Type sizing
6. Tapping location shows no action (display only)
- [Arch-Lint] UI components remain pure presentation
- [Coverage] Snapshot tests for location display
- [Doc] Location display format documented

**Component Reference**:
- Modify existing entry display components
- Use 📍 emoji for location indicator
- Secondary text styling for location

**Technical Implementation**:
- Update `Interface/Components/EntryRowView.swift`
- Update `Interface/Components/EntryDetailView.swift`
- Add optional location display with proper styling
- Use system colors for consistent appearance

**QA Test Criteria**:
1. Test location display in entry list
2. Test location display in entry detail
3. Test entries without location show no location
4. Test Dynamic Type scaling for location text
5. Test location display with long city/state names

**Priority Score**: 8 (WSJF) - User-facing display feature  
**Dependencies**: location-tracking-TICKET-004

---

### location-tracking-TICKET-006: Update settings ViewModel for location
**Story ID**: location-tracking-TICKET-006  
**Context/Layer**: Location / application  
**As a** developer  
**I want** to extend SettingsViewModel with location functionality  
**So that** location settings integrate with existing settings architecture  

**Acceptance Criteria**:
1. Extend existing `Application/ViewModels/SettingsViewModel.swift` 
2. Add @Published properties for location settings and current location
3. Add methods to toggle location tracking and update current location
4. Load location settings on ViewModel initialization
5. Save location settings immediately on changes
6. Handle location permission requests through ViewModel
7. Update current location display when location changes
- [Arch-Lint] ViewModel only orchestrates use cases
- [Coverage] Unit tests with mocked location dependencies
- [Doc] Location state management documented

**Technical Implementation**:
- See TIP Section 7 for SettingsViewModel extension
- Inject location use cases into existing ViewModel
- Add location-specific @Published properties
- Integrate with existing settings persistence

**QA Test Criteria**:
1. Test location settings load on initialization
2. Test location toggle saves immediately
3. Test current location updates when changed
4. Test permission request handling
5. Test error handling for location failures

**Priority Score**: 8 (WSJF) - Required for settings integration  
**Dependencies**: location-tracking-TICKET-002, location-tracking-TICKET-003

---

### location-tracking-TICKET-007: Location permissions and error handling
**Story ID**: location-tracking-TICKET-007  
**Context/Layer**: Location / application  
**As a** developer  
**I want** proper error handling for location operations  
**So that** the app gracefully handles location permission and service issues  

**Acceptance Criteria**:
1. Handle location permission denied gracefully
2. Handle location services disabled on device
3. Handle location request timeouts
4. Show appropriate user-facing messages for location errors
5. Provide option to open Settings app for permission changes
6. Fall back gracefully when location unavailable
7. Log location errors for debugging (DEBUG only)
- [Arch-Lint] Errors handled at appropriate layers
- [Coverage] Error path unit tests
- [Doc] Location error scenarios documented

**Technical Implementation**:
- Create LocationError enum for typed errors
- Alert presentations in ViewModel for permission issues
- Graceful fallbacks for all location operations
- User-friendly error messages

**QA Test Criteria**:
1. Test permission denied flow
2. Test location services disabled scenario
3. Test location timeout handling
4. Test Settings app navigation option
5. Test app remains functional without location

**Priority Score**: 7 (WSJF) - Robustness requirement  
**Dependencies**: location-tracking-TICKET-001 through location-tracking-TICKET-006

---

## Success Criteria
1. Location toggle accessible in Settings screen
2. Location automatically added to entries when enabled
3. Location displayed in entry views as city/state
4. Location permissions handled gracefully
5. All location data stored locally (no network calls)
6. Settings persist between app launches

## Technical Notes
- See TIP Section 7 for detailed implementation guidance
- Core Location framework for location services
- UserDefaults for location settings storage
- 5-second timeout for location requests
- Privacy-first approach - city/state display only