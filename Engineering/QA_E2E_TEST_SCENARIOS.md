# QA End-to-End Test Scenarios

## Custom Fields Feature Test Suite

### Scenario 1: Basic Field Creation and Usage
```gherkin
Feature: Custom Fields Basic Flow
  As a user
  I want to create and use custom fields
  So that I can track structured data with my journal entries

  Scenario: Create field and use it in an entry
    Given I have a thread named "Test Thread"
    When I navigate to thread settings menu
    And I tap "Custom Fields"
    And I tap the "+" button
    And I enter "Mood" as the field name
    And I save the field
    Then I should see "Mood" in the fields list
    
    When I go back to the thread view
    Then I should see a "+" button in the compose area
    
    When I tap the "+" button in compose area
    Then I should see "Mood" as a selectable field
    
    When I select "Mood"
    And I tap "Done"
    Then I should IMMEDIATELY see a "Mood" input field in the compose area
    And the input should be ABOVE the text compose field
    
    When I type "Happy" in the Mood field
    And I type "Today was a good day" in the main text field
    And I tap the send button
    Then I should see a new entry with:
      - Text: "Today was a good day"
      - Tag: "Mood: Happy"
    
    When I force quit the app
    And I reopen the app
    And I navigate to "Test Thread"
    Then I should still see the entry with "Mood: Happy" tag
```

### Scenario 2: Multiple Fields
```gherkin
  Scenario: Use multiple fields in one entry
    Given I have created fields: "Energy", "Sleep Hours", "Exercise"
    When I tap the "+" button in compose area
    And I select all three fields
    And I tap "Done"
    Then I should see THREE input fields in the compose area:
      - Energy: [input field]
      - Sleep Hours: [input field]
      - Exercise: [input field]
    
    When I fill in:
      | Field       | Value    |
      | Energy      | High     |
      | Sleep Hours | 8        |
      | Exercise    | Running  |
    And I type "Felt great today" in the main field
    And I send the entry
    Then the entry should display with tags:
      - "Energy: High"
      - "Sleep Hours: 8"
      - "Exercise: Running"
```

### Scenario 3: Field Persistence Verification
```gherkin
  Scenario: Verify no mock data exists
    When I check the source code for the entry display
    Then I should NOT find:
      - Any hardcoded field values
      - Mock field arrays
      - Test data
      - Placeholder values
    
    When I examine the data flow
    Then I should verify:
      - User input → ViewModel state
      - ViewModel state → Use case parameters
      - Use case → Repository call
      - Repository → Core Data save
      - Core Data → Entry fetch includes field values
```

## Anti-Pattern Checks

### Check 1: No Mock Data
```swift
// ❌ FAIL if found:
let mockFields = [
  EntryFieldValue(fieldId: UUID(), value: "Medication taken"),
  EntryFieldValue(fieldId: UUID(), value: "Dose: 10mg")
]

// ❌ FAIL if found:
entry.customFieldValues = [
  // Hardcoded test data
]

// ✅ PASS only if:
entry.customFieldValues = fieldValues // Where fieldValues comes from user input
```

### Check 2: Data Actually Persists
```swift
// Test sequence:
1. Create entry with field values
2. Verify entry.customFieldValues.count > 0
3. Get entry ID
4. Force terminate app
5. Fetch entry by ID
6. Verify entry.customFieldValues equals original values
```

### Check 3: UI Shows Real Data
```swift
// ❌ FAIL if:
Text("Medication: Taken") // Hardcoded

// ✅ PASS if:
Text("\(field.name): \(fieldValue.value)") // Dynamic from data
```

## Critical Verification Points

### 1. Inline Display Requirement
- **Expected**: Fields appear IN the compose area immediately after selection
- **NOT Acceptable**: Fields only in expanded/modal view
- **Test**: After selecting fields, compose area should show input fields without any additional taps

### 2. Data Flow Completeness
Check each step:
```
UI Input → ViewModel → UseCase → Repository → CoreData → UI Display
```
If ANY step is missing = FAIL

### 3. No Temporary Implementation
- No "TODO" comments in implementation
- No mock data "for testing"
- No hardcoded values "to show it working"

## QA Agent Commands

### Manual Test Execution
```bash
# Run specific scenario
/qa test-scenario custom-fields-basic-flow

# Check for mock data
/qa scan-for-mocks ThreadDetailView

# Verify persistence
/qa test-persistence Entry.customFieldValues

# Full feature test
/qa test-feature custom-fields --e2e
```

### Automated Checks
```python
def verify_no_mocks(file_path):
    forbidden_patterns = [
        r'Mock.*Field',
        r'EntryFieldValue\(.*UUID\(\).*".*"\)',  # Hardcoded field values
        r'customFieldValues\s*=\s*\[.*\]',       # Hardcoded arrays
        r'// TODO.*field',
        r'placeholder|dummy|test.*[Dd]ata'
    ]
    
    for pattern in forbidden_patterns:
        if re.search(pattern, file_content):
            return False, f"Found forbidden pattern: {pattern}"
    
    return True, "No mock data found"
```

## Success Criteria

A ticket is ONLY complete when:
1. ✅ All E2E scenarios pass
2. ✅ No mock/hardcoded data exists
3. ✅ Data persists across app restarts
4. ✅ All acceptance criteria met as USER would expect
5. ✅ Feature works without developer intervention

## Example Failed QA Report

```markdown
TICKET-005 & TICKET-006 QA FAILED
==================================

❌ E2E Test Failed:
- Step: "Field inputs should appear in compose area"
- Expected: Inline field inputs visible after selection
- Actual: Fields only appear in expanded modal view

❌ Mock Data Detected:
- File: ThreadDetailView.swift
- Line: 423
- Found: Hardcoded EntryFieldValue array

❌ Persistence Test Failed:
- Created entry with field "TestField: TestValue"
- After app restart: Field values are nil

❌ Integration Gap:
- CoreDataThreadRepository.mapManagedObjectToEntry()
- Missing: Field value loading from Core Data

RECOMMENDATION: Return to development
- Implement inline field display
- Remove all mock data
- Complete Core Data integration
- Re-run all E2E tests
```

This would have caught exactly the issues we experienced!