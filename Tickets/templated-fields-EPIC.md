# Templated Fields Epic

## Overview
Enable users to create custom fields and field groups that can be attached to journal entries, providing structured data capture alongside free-form journaling.

## Business Value
- Users can track structured data (medication, mood, energy levels) alongside journal entries
- Historical data preserved when fields are deleted
- CSV export includes structured field data for analysis
- Fields managed per thread for focused tracking

## Design Reference
- Primary: `/Users/ericzhou/Downloads/revised-mockups.html`
- Secondary: `/Users/ericzhou/Downloads/field-grouping-simple.html`

---

## TICKETS

### templated-fields-TICKET-001: Create Custom Fields Management Screen
**Story ID**: templated-fields-TICKET-001  
**Context/Layer**: Journaling / interface  
**As a** user  
**I want to** manage custom fields and create field groups  
**So that** I can organize structured data fields for my journal entries  

**Acceptance Criteria**:
1. Access "Custom Fields" from thread settings menu
2. View all existing fields in a list with drag handles (≡ symbol)
3. Drag fields to reorder them
4. Drag a field under another field to create a group (the parent field becomes the group)
5. Groups display with "(group)" indicator after the name
6. Nested fields indented and shown within group container with subtle background
7. "+" button at bottom to add new fields
8. Maximum 20 fields per thread (including fields within groups)
9. Field names limited to 50 characters
10. Groups can contain up to 10 fields

**Design Reference**:
- See screens 3 & 4 in `/Users/ericzhou/Downloads/revised-mockups.html`
- Drag-to-group interaction from `/Users/ericzhou/Downloads/field-grouping-simple.html`

**Technical Implementation**:
- No other technical details needed

**QA Test Criteria**:
1. Verify drag and drop reordering works smoothly
2. Test creating groups by dragging fields under other fields
3. Verify group creation visual feedback during drag
4. Test field name character limit enforcement
5. Verify maximum field count enforcement
6. Test removing fields from groups by dragging out

**Priority Score**: 8 (WSJF) - Core feature setup  
**Dependencies**: None

---

### templated-fields-TICKET-002: Add Field Creation Dialog
**Story ID**: templated-fields-TICKET-002  
**Context/Layer**: Journaling / interface  
**As a** user  
**I want to** create new custom fields  
**So that** I can track specific data points in my journal  

**Acceptance Criteria**:
1. Tap "+" button shows inline field creation
2. New field appears at bottom of list with keyboard focus
3. Enter field name and press Done/Return to save
4. Empty field names not allowed
5. Duplicate field names show error "Field already exists"
6. Cancel by clearing field and tapping elsewhere
7. New fields can immediately be dragged to reorder or group

**Design Reference**:
- See screen 5 flow in `/Users/ericzhou/Downloads/field-grouping-simple.html`

**Technical Implementation**:
- No other technical details needed

**QA Test Criteria**:
1. Test field creation with valid names
2. Verify empty name validation
3. Test duplicate name detection
4. Verify keyboard dismissal saves field
5. Test immediate drag capability after creation

**Priority Score**: 8 (WSJF) - Required for field management  
**Dependencies**: templated-fields-TICKET-001

---

### templated-fields-TICKET-003: Show Custom Fields Button in Compose Bar
**Story ID**: templated-fields-TICKET-003  
**Context/Layer**: Journaling / interface  
**As a** user  
**I want to** see a fields button when composing entries  
**So that** I can easily add structured data to my entries  

**Acceptance Criteria**:
1. "+" button appears in compose bar when thread has custom fields defined
2. Button positioned between text input and microphone icon
3. Button uses system blue color (#007AFF)
4. Button hidden when no custom fields exist for thread
5. Tapping button opens field selector (see TICKET-004)
6. Button remains visible during text entry

**Design Reference**:
- See screens 2 & 5 in `/Users/ericzhou/Downloads/revised-mockups.html`

**Technical Implementation**:
- No other technical details needed

**QA Test Criteria**:
1. Verify button only appears when fields exist
2. Test button visibility during keyboard input
3. Verify button tap opens selector
4. Test button hidden for threads without fields

**Priority Score**: 9 (WSJF) - Primary user interface  
**Dependencies**: templated-fields-TICKET-001

---

### templated-fields-TICKET-004: Implement Field Selector Modal
**Story ID**: templated-fields-TICKET-004  
**Context/Layer**: Journaling / interface  
**As a** user  
**I want to** select which fields to include in my entry  
**So that** I can choose relevant structured data for each entry  

**Acceptance Criteria**:
1. Tapping "+" opens bottom sheet modal
2. Shows all thread's custom fields with checkboxes
3. Groups show as "GroupName (group)" - selecting group selects all its fields
4. Individual selection of fields within groups supported
5. "Add Selected Fields" button at bottom
6. "Done" button in top right dismisses without adding
7. Selected fields appear above compose text area
8. Previously selected fields remain checked if modal reopened

**Design Reference**:
- See screen 6 in `/Users/ericzhou/Downloads/revised-mockups.html`

**Technical Implementation**:
- No other technical details needed

**QA Test Criteria**:
1. Test group selection selects all child fields
2. Verify individual field selection within groups
3. Test state persistence when reopening modal
4. Verify cancel vs add behavior
5. Test with 20+ fields for scrolling

**Priority Score**: 9 (WSJF) - Core interaction  
**Dependencies**: templated-fields-TICKET-003

---

### templated-fields-TICKET-005: Display Selected Fields in Compose Area
**Story ID**: templated-fields-TICKET-005  
**Context/Layer**: Journaling / interface  
**As a** user  
**I want to** see and fill in selected fields  
**So that** I can provide structured data with my entry  

**Acceptance Criteria**:
1. Selected fields appear above compose text in expanded entry sheet
2. Group fields show group name as section header
3. Each field shows as input with placeholder (field name)
4. Inputs use light background (#f9f9f9) with 10px border radius
5. Tapping input shows keyboard
6. Send button submits entry with field values
7. Cancel button discards entry and field values
8. Field values optional (can be empty)

**Design Reference**:
- See screen 7 in `/Users/ericzhou/Downloads/revised-mockups.html`
- See flow 7 in `/Users/ericzhou/Downloads/field-grouping-simple.html`

**Technical Implementation**:
- No other technical details needed

**QA Test Criteria**:
1. Verify field inputs appear correctly
2. Test keyboard interaction with multiple fields
3. Verify empty fields accepted
4. Test send with various field combinations
5. Verify cancel discards all input

**Priority Score**: 9 (WSJF) - Core data entry  
**Dependencies**: templated-fields-TICKET-004

---

### templated-fields-TICKET-006: Display Fields as Tags on Entries
**Story ID**: templated-fields-TICKET-006  
**Context/Layer**: Journaling / interface  
**As a** user  
**I want to** see field values displayed with my entries  
**So that** I can view structured data alongside journal text  

**Acceptance Criteria**:
1. Field values appear below entry text as tags
2. Format: "FieldName: Value" for regular fields
3. Group fields show group name as single blue tag, followed by field values
4. Individual field tags use gray background (#f2f2f7)
5. Group name tags use blue background (#e8f0fe) with blue text (#1a73e8)
6. Tags wrap to multiple lines if needed
7. Empty field values not displayed
8. 8px gap between tags

**Design Reference**:
- See screen 2 entries in `/Users/ericzhou/Downloads/revised-mockups.html`
- See flow 6 in `/Users/ericzhou/Downloads/field-grouping-simple.html`

**Technical Implementation**:
- No other technical details needed

**QA Test Criteria**:
1. Verify tag display formatting
2. Test color differentiation for groups
3. Verify empty fields omitted
4. Test wrapping with many fields
5. Verify consistent spacing

**Priority Score**: 8 (WSJF) - Visual feedback  
**Dependencies**: templated-fields-TICKET-005

---

### templated-fields-TICKET-007: Add Field Management to Thread Settings
**Story ID**: templated-fields-TICKET-007  
**Context/Layer**: Journaling / interface  
**As a** user  
**I want to** access field management from thread settings  
**So that** I can configure fields specific to each thread  

**Acceptance Criteria**:
1. Add "Custom Fields" option to thread settings menu (•••)
2. Shows between existing options with standard spacing
3. Navigates to Custom Fields Management screen
4. Back button returns to thread view
5. Changes save automatically (no save button needed)

**Design Reference**:
- Standard iOS navigation pattern
- Menu option leads to screen from TICKET-001

**Technical Implementation**:
- No other technical details needed

**QA Test Criteria**:
1. Verify menu option appears
2. Test navigation to/from fields screen
3. Verify auto-save of changes
4. Test with multiple threads

**Priority Score**: 7 (WSJF) - Navigation  
**Dependencies**: templated-fields-TICKET-001

---

### templated-fields-TICKET-008: Support Text-Only Entry Mode
**Story ID**: templated-fields-TICKET-008  
**Context/Layer**: Journaling / interface  
**As a** user  
**I want to** create text-only entries without fields  
**So that** I can quickly journal without structured data  

**Acceptance Criteria**:
1. Tapping text input (not + button) expands to text-only mode
2. Shows larger text area with Send button
3. Optional "Fields" button in bottom left to add fields later
4. Tapping "Fields" switches to field selection mode
5. Direct text entry remains primary interaction

**Design Reference**:
- See screen 8 in `/Users/ericzhou/Downloads/revised-mockups.html`

**Technical Implementation**:
- No other technical details needed

**QA Test Criteria**:
1. Verify text-only mode activation
2. Test switching to field mode
3. Verify send without fields
4. Test keyboard behavior

**Priority Score**: 7 (WSJF) - Maintain simplicity  
**Dependencies**: templated-fields-TICKET-003

---

### templated-fields-TICKET-009: Handle Field Deletion and Historical Data
**Story ID**: templated-fields-TICKET-009  
**Context/Layer**: Journaling / interface  
**As a** user  
**I want to** delete fields while preserving historical data  
**So that** I can remove unused fields without losing past entries  

**Acceptance Criteria**:
1. Swipe left on field shows Delete button
2. Confirmation dialog: "Delete field? Historical data will be preserved"
3. Deleted fields removed from field selector
4. Existing entries continue showing deleted field values
5. Cannot create new field with same name as deleted field
6. Deleting group deletes all child fields

**Design Reference**:
- Standard iOS delete pattern

**Technical Implementation**:
- No other technical details needed

**QA Test Criteria**:
1. Test field deletion flow
2. Verify historical data preserved
3. Test name reuse prevention
4. Verify group deletion cascades
5. Test with entries using deleted fields

**Priority Score**: 6 (WSJF) - Data management  
**Dependencies**: templated-fields-TICKET-001

---

### templated-fields-TICKET-010: CSV Export with Field Data
**Story ID**: templated-fields-TICKET-010  
**Context/Layer**: Journaling / interface  
**As a** user  
**I want to** export entries with field data to CSV  
**So that** I can analyze structured journal data  

**Acceptance Criteria**:
1. Export includes columns for each field ever used in thread
2. Group fields exported as "GroupName.FieldName" columns
3. Empty cells for entries without specific fields
4. Field columns appear after standard columns (date, time, text)
5. Deleted fields included if historical data exists
6. UTF-8 encoding with proper escaping

**Design Reference**:
- Extension of existing export functionality

**Technical Implementation**:
- No other technical details needed

**QA Test Criteria**:
1. Verify column naming for groups
2. Test with mixed field usage
3. Verify deleted field inclusion
4. Test special character handling
5. Verify Excel compatibility

**Priority Score**: 5 (WSJF) - Data portability  
**Dependencies**: templated-fields-TICKET-006

---

### templated-fields-TICKET-011: Domain Models for Custom Fields
STATUS: DONE
**Story ID**: templated-fields-TICKET-011  
**Context/Layer**: Journaling / domain  
**As a** developer  
**I want** domain models for custom fields  
**So that** the system can represent field structures  

**Acceptance Criteria**:
- Create `Domain/Entities/CustomField.swift` with id, name, order, isGroup
- Create `Domain/Entities/CustomFieldGroup.swift` with parentField and childFields
- Create `Domain/Entities/EntryFieldValue.swift` with fieldId, value
- Add `customFieldValues: [EntryFieldValue]` to Entry entity
- All models immutable with validation
- Field names 1-50 characters
- Groups cannot be nested (no groups within groups)

**Technical Reference**:
- See TIP for domain layer patterns

**QA Test Criteria**:
1. Unit test field validation rules
2. Test group relationship constraints
3. Verify immutability
4. Test entry field associations

**Priority Score**: 9 (WSJF) - Foundation  
**Dependencies**: None

---

### templated-fields-TICKET-012: Repository Protocol for Custom Fields
STATUS: DONE
**Story ID**: templated-fields-TICKET-012  
**Context/Layer**: Journaling / domain  
**As a** developer  
**I want** repository protocols for custom fields  
**So that** the domain can persist field configurations  

**Acceptance Criteria**:
- Add to `Domain/Repositories/ThreadRepository.swift`:
  - `getCustomFields(threadId:) async throws -> [CustomField]`
  - `saveCustomFields(threadId:fields:) async throws`
  - `deleteCustomField(threadId:fieldId:) async throws`
- Add to `Domain/Repositories/EntryRepository.swift`:
  - Include field values in create/update operations
- Define errors for duplicate names, max fields

**Technical Reference**:
- See TIP Section 5 for repository patterns

**QA Test Criteria**:
1. Mock implementations for testing
2. Verify error cases
3. Test thread isolation

**Priority Score**: 8 (WSJF) - Core contracts  
**Dependencies**: templated-fields-TICKET-011

---

### templated-fields-TICKET-013: Custom Field Use Cases
**Story ID**: templated-fields-TICKET-013  
**Context/Layer**: Journaling / domain  
**As a** developer  
**I want** use cases for field operations  
**So that** business logic is properly encapsulated  

**Acceptance Criteria**:
- Create `Domain/UseCases/CreateCustomFieldUseCase.swift`
  - Validate name uniqueness within thread
  - Enforce max 20 fields limit
  - Auto-assign order based on position
- Create `Domain/UseCases/CreateFieldGroupUseCase.swift`
  - Convert field to group when child added
  - Validate no nested groups
- Create `Domain/UseCases/DeleteCustomFieldUseCase.swift`
  - Cascade delete for groups
  - Preserve historical data flag

**Technical Reference**:
- See TIP Section 6 for use case patterns

**QA Test Criteria**:
1. Unit test validation logic
2. Test group conversion
3. Verify cascade behavior
4. Mock repository calls

**Priority Score**: 8 (WSJF) - Business logic  
**Dependencies**: templated-fields-TICKET-012

---

### templated-fields-TICKET-014: Core Data Schema for Custom Fields
**Story ID**: templated-fields-TICKET-014  
**Context/Layer**: Journaling / infrastructure  
**As a** developer  
**I want** Core Data models for custom fields  
**So that** field data can be persisted  

**Acceptance Criteria**:
- Add to ThreadJournal2.xcdatamodeld:
  - CustomFieldMO: id, name, order, isGroup, isDeleted, threadId
  - CustomFieldGroupMO: parentFieldId, childFieldIds relationship
  - EntryFieldValueMO: entryId, fieldId, value
- Add relationships to existing ThreadMO and EntryMO
- Migration from current version
- Indexes on threadId and entryId

**Technical Reference**:
- See TIP Section 4.4 for Core Data patterns

**QA Test Criteria**:
1. Test migration with existing data
2. Verify relationships
3. Test cascade rules
4. Performance with many fields

**Priority Score**: 8 (WSJF) - Persistence layer  
**Dependencies**: templated-fields-TICKET-011

---

### templated-fields-TICKET-015: Repository Implementation for Custom Fields
**Story ID**: templated-fields-TICKET-015  
**Context/Layer**: Journaling / infrastructure  
**As a** developer  
**I want** repository implementations for custom fields  
**So that** field data can be stored and retrieved  

**Acceptance Criteria**:
- Implement protocols from TICKET-012 in:
  - `Infrastructure/Repositories/CoreDataThreadRepository.swift`
  - `Infrastructure/Repositories/CoreDataEntryRepository.swift`
- Handle soft delete for fields (isDeleted flag)
- Maintain field order on save
- Convert between domain models and Core Data models
- Thread-safe operations

**Technical Reference**:
- See TIP Section 4.4 for repository implementation

**QA Test Criteria**:
1. Integration tests with Core Data
2. Test concurrent access
3. Verify soft delete
4. Test model mapping

**Priority Score**: 8 (WSJF) - Persistence implementation  
**Dependencies**: templated-fields-TICKET-014

---

### templated-fields-TICKET-016: ViewModels for Custom Fields
**Story ID**: templated-fields-TICKET-016  
**Context/Layer**: Journaling / application  
**As a** developer  
**I want** ViewModels for field management  
**So that** UI can interact with field logic  

**Acceptance Criteria**:
- Create `Application/ViewModels/CustomFieldsViewModel.swift`:
  - @Published fields array with drag reorder support
  - addField(), deleteField(), createGroup()
  - Validation state for new field names
  - Auto-save on changes
- Create `Application/ViewModels/FieldSelectorViewModel.swift`:
  - Track selected fields
  - Group selection logic
  - Provide selected fields to entry creation

**Technical Reference**:
- See TIP Section 7 for ViewModel patterns

**QA Test Criteria**:
1. Unit test with mocked use cases
2. Test published state updates
3. Verify validation logic
4. Test auto-save triggers

**Priority Score**: 7 (WSJF) - UI logic  
**Dependencies**: templated-fields-TICKET-013

---

### templated-fields-TICKET-017: Update Entry Creation for Field Values
**Story ID**: templated-fields-TICKET-017  
**Context/Layer**: Journaling / application  
**As a** developer  
**I want** entry creation to support field values  
**So that** structured data can be saved with entries  

**Acceptance Criteria**:
- Update `ThreadDetailViewModel.swift`:
  - Add @Published selectedFields array
  - Add @Published fieldValues dictionary
  - Update createEntry to include field values
  - Clear field selection after send
- Update `CreateEntryUseCase.swift`:
  - Accept optional field values
  - Validate field IDs exist
  - Store with entry

**Technical Reference**:
- See TIP for entry creation flow

**QA Test Criteria**:
1. Test entry with fields
2. Test entry without fields
3. Verify field validation
4. Test state cleanup

**Priority Score**: 8 (WSJF) - Core functionality  
**Dependencies**: templated-fields-TICKET-016

---

### templated-fields-TICKET-018: CSV Export Implementation
**Story ID**: templated-fields-TICKET-018  
**Context/Layer**: Journaling / application  
**As a** developer  
**I want** CSV export to include field data  
**So that** users can analyze structured data  

**Acceptance Criteria**:
- Update `ExportThreadUseCase.swift`:
  - Fetch all fields ever used in thread
  - Add columns for each field
  - Format group fields as "GroupName.FieldName"
  - Include deleted fields if data exists
- Update CSV generation:
  - Proper escaping for field names
  - Empty cells for missing values
  - Maintain column order

**Technical Reference**:
- See TIP for export patterns

**QA Test Criteria**:
1. Test various field combinations
2. Verify Excel compatibility
3. Test special characters
4. Test large datasets

**Priority Score**: 5 (WSJF) - Export feature  
**Dependencies**: templated-fields-TICKET-017

---

### templated-fields-TICKET-019: Performance Optimization
**Story ID**: templated-fields-TICKET-019  
**Context/Layer**: Journaling / infrastructure  
**As a** developer  
**I want** optimized field data loading  
**So that** the app remains responsive with many fields  

**Acceptance Criteria**:
- Batch fetch field values with entries
- Cache field definitions per thread
- Lazy load field values for list view
- Only fetch non-deleted fields for UI
- Add performance tests for 100 fields, 1000 entries

**Technical Reference**:
- See TIP performance requirements

**QA Test Criteria**:
1. Performance test with max fields
2. Memory usage profiling
3. Scroll performance in entry list
4. Test cache invalidation

**Priority Score**: 6 (WSJF) - Performance  
**Dependencies**: templated-fields-TICKET-015

---

### templated-fields-TICKET-020: Accessibility Support
**Story ID**: templated-fields-TICKET-020  
**Context/Layer**: Journaling / interface  
**As a** user with accessibility needs  
**I want** VoiceOver support for custom fields  
**So that** I can use structured data features  

**Acceptance Criteria**:
1. Drag handles announce "Reorder [field name]"
2. Group creation announces "Creating group"
3. Field selector announces selection state
4. Field values in entries announced as "Field: Value"
5. Proper focus management in modals
6. Keyboard navigation for all interactions

**Design Reference**:
- iOS Accessibility Guidelines

**Technical Implementation**:
- No other technical details needed

**QA Test Criteria**:
1. Full VoiceOver testing
2. Keyboard-only navigation
3. Dynamic Type support
4. Contrast requirements

**Priority Score**: 7 (WSJF) - Accessibility  
**Dependencies**: All UI tickets


# EPIC PLAN:
⏺ Looking at the dependencies and the logical flow to get custom fields working in the UI, here's
  the recommended implementation order:

  Implementation Order:

  1. TICKET-013: Custom Field Use Cases

  - Why first: Business logic needed by ViewModels
  - Dependencies: TICKET-012 ✅ (done)

  2. TICKET-014: Core Data Schema

  - Why next: Database support needed for persistence
  - Dependencies: TICKET-011 ✅ (done)

  3. TICKET-015: Repository Implementation

  - Why: Connects Core Data to domain layer
  - Dependencies: TICKET-014, TICKET-012 ✅

  4. TICKET-016: ViewModels for Custom Fields

  - Why: Bridges business logic to UI
  - Dependencies: TICKET-013

  5. TICKET-007: Add Field Management to Thread Settings

  - Why: Entry point to access custom fields
  - Dependencies: TICKET-001 (but can be done partially first)

  6. TICKET-001: Create Custom Fields Management Screen

  - Why: Core UI for managing fields
  - Dependencies: None (but needs ViewModels)

  7. TICKET-003: Show Custom Fields Button in Compose Bar

  - Why: Makes fields accessible when composing
  - Dependencies: TICKET-001

  8. TICKET-004: Field Selector Modal

  - Why: UI for selecting fields
  - Dependencies: TICKET-003

  9. TICKET-005: Display Selected Fields in Compose

  - Why: Actual field input UI
  - Dependencies: TICKET-004

  10. TICKET-006: Display Fields as Tags

  - Why: Show field data on entries
  - Dependencies: TICKET-005

  The remaining tickets (008-010, 017-020) can be done after the core functionality is working.
