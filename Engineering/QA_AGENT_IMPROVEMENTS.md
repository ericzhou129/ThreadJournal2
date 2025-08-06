# QA Agent Improvements

## Problem Statement
The current QA agent failed to catch that custom fields functionality wasn't actually working because it:
1. Only verified that code files existed
2. Didn't test actual user flows end-to-end
3. Didn't verify data persistence
4. Accepted mock data as valid implementation

## Root Cause Analysis

### What Went Wrong
1. **Surface-level verification**: QA only checked if UI components existed, not if they functioned
2. **No integration testing**: Didn't verify that field values actually save to database
3. **Incomplete acceptance criteria verification**: Tickets said "fields appear in expanded view" but user expected inline display
4. **Mock data acceptance**: TICKET-006 was "implemented" with hardcoded mock field values

### Specific Failures
- TICKET-005: Field inputs only appeared in expanded view, not inline
- TICKET-006: Field tags were mocked, not reading from actual entry data
- Core Data persistence wasn't implemented for field values
- No end-to-end testing of the complete flow

## Proposed Improvements

### 1. Functional Testing Requirements
The QA agent MUST:
```markdown
## Functional Verification
- [ ] Run the app in simulator
- [ ] Execute the complete user flow
- [ ] Verify data persists after app restart
- [ ] Confirm no mock/hardcoded data exists
```

### 2. End-to-End Test Scenarios
For each ticket, create specific test scenarios:

```markdown
## E2E Test: Custom Fields (TICKET-003 through TICKET-006)
1. Navigate to thread settings
2. Create a custom field named "TestField"
3. Return to thread view
4. Verify "+" button appears in compose area
5. Tap "+" button
6. Select "TestField" 
7. Verify field input appears IMMEDIATELY in compose area (not just expanded)
8. Enter value "TestValue"
9. Send entry
10. Verify entry displays with "TestField: TestValue" tag
11. Force quit app
12. Reopen app
13. Verify field value still displays on entry
```

### 3. Anti-Pattern Detection
QA agent should automatically flag:
- Any file containing: `mock`, `Mock`, `hardcoded`, `placeholder`, `TODO`, `FIXME`
- Field values created without user input
- UI elements that don't connect to real data
- Missing persistence layer connections

### 4. Data Flow Verification
For features involving data persistence:
```markdown
## Data Flow Checklist
- [ ] UI captures user input
- [ ] ViewModel receives and processes input
- [ ] Use case executes with real data
- [ ] Repository saves to persistence layer
- [ ] Data loads correctly on next app launch
- [ ] No data exists that user didn't create
```

### 5. Acceptance Criteria Clarification
Before implementation, QA agent should:
```markdown
## Pre-Implementation Questions
1. Where exactly should UI elements appear?
   - "In compose area" - inline or only in expanded view?
2. When should features be visible?
   - "After selection" - immediately or after some action?
3. What constitutes "working"?
   - Just displaying or full CRUD operations?
```

### 6. Implementation Verification Commands
New QA commands to add:

```bash
# Check for mock data
/qa check-mocks TICKET-XXX

# Verify data persistence
/qa test-persistence TICKET-XXX

# Run full E2E scenario
/qa run-e2e TICKET-XXX

# Validate no hardcoded values
/qa check-hardcoded TICKET-XXX
```

### 7. Enhanced Verification Report
```markdown
TICKET-006 QA Verification Report
=================================
✅ Code Structure
- Files exist in correct layers
- Architecture rules followed

❌ Functional Testing
- Field values are hardcoded MockField entries
- No connection to actual entry data
- Values don't persist after app restart

❌ Data Flow
- UI → ViewModel: ✅ Working
- ViewModel → UseCase: ✅ Working  
- UseCase → Repository: ❌ Not implemented
- Repository → CoreData: ❌ Not implemented

❌ E2E Scenario
- Step 9/13 failed: Entry doesn't show real field values
- Step 12/13 failed: Data doesn't persist

VERDICT: FAILED - Feature appears to work but has no real implementation
```

### 8. Continuous Verification
After EACH code change:
1. Re-run E2E tests
2. Verify no regressions
3. Check data persistence
4. Ensure no mock data introduced

### 9. User Expectation Alignment
QA should verify against user expectations, not just ticket text:
```markdown
## User Expectation Checklist
- [ ] Would a real user find this intuitive?
- [ ] Does it work like similar features in other apps?
- [ ] Is the feature discoverable?
- [ ] Does it provide immediate feedback?
```

### 10. Implementation Guidelines for QA Agent

The QA agent should:
1. **Never accept mock data** - Flag any hardcoded values immediately
2. **Test full lifecycle** - Create, Read, Update, Delete operations
3. **Verify persistence** - Data must survive app restart
4. **Check integration** - All layers must be connected
5. **Validate UX** - Features must be immediately visible/usable
6. **Ensure completeness** - Partial implementations are failures

## Example QA Agent Usage

```typescript
class ImprovedQAAgent {
  async verifyTicket(ticketId: string): Promise<VerificationResult> {
    // 1. Parse ticket requirements
    const ticket = await this.parseTicket(ticketId);
    
    // 2. Check for anti-patterns
    const mockDataFound = await this.scanForMockData();
    if (mockDataFound) {
      return this.fail("Mock data detected - not a real implementation");
    }
    
    // 3. Run E2E scenarios
    const e2eResult = await this.runE2EScenarios(ticket);
    if (!e2eResult.passed) {
      return this.fail(`E2E failed at step ${e2eResult.failedStep}`);
    }
    
    // 4. Verify data persistence
    const persistenceResult = await this.verifyPersistence();
    if (!persistenceResult.passed) {
      return this.fail("Data doesn't persist after app restart");
    }
    
    // 5. Check all layers connected
    const integrationResult = await this.verifyIntegration();
    if (!integrationResult.allLayersConnected) {
      return this.fail(`Missing connection: ${integrationResult.missingLink}`);
    }
    
    return this.pass("All verifications passed");
  }
}
```

## Conclusion

The key improvement is shifting from **structural verification** (does the code exist?) to **functional verification** (does it actually work?). The QA agent must act like a real user and verify the complete experience, not just check that files were created.