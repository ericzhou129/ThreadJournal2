# Ticket Verification Agent Specification

## Purpose
Prevent ticket misimplementation by automatically verifying that implemented code matches ticket requirements.

## Core Capabilities

### 1. Ticket Analysis
- Parse ticket requirements from markdown
- Extract:
  - Story ID and layer (e.g., "interface", "domain")
  - Acceptance criteria
  - QA test criteria
  - Design references
  - Dependencies

### 2. Implementation Verification
- Analyze git commits claiming to implement a ticket
- Check:
  - Files modified match expected layer
  - Acceptance criteria keywords appear in code
  - Required UI elements exist (for interface tickets)
  - Required tests exist

### 3. Compliance Reporting
Generate report showing:
```
TICKET-003 Verification Report
==============================
Expected Layer: interface
Actual Layer: domain ❌

Acceptance Criteria:
1. "+" button appears in compose bar ❌ (No UI code found)
2. Button positioned between text input and microphone ❌
3. Button uses system blue color ❌
4. Button hidden when no fields exist ❌

Files Expected: Views/ComposeBar.swift or similar
Files Found: Domain/Entities/Thread.swift ❌

VERDICT: FAILED - Wrong layer, no UI implementation
```

## Implementation Approach

### Slash Command: `/verify-ticket TICKET-XXX`

The agent would:
1. Read ticket from `Tickets/*.md`
2. Find commits mentioning ticket ID
3. Analyze changed files
4. Match against acceptance criteria
5. Generate compliance report

### Example Usage

```bash
/verify-ticket TICKET-003

# Output:
Analyzing TICKET-003: Show Custom Fields Button in Compose Bar...

❌ VERIFICATION FAILED

Issues Found:
- Expected work in 'interface' layer, but found changes in 'domain' layer
- No UI components created (expected button in compose bar)
- Acceptance criteria not met:
  * No "+" button implementation found
  * No compose bar modifications
  * No field visibility logic

Recommendation: This ticket should not be marked as complete.
```

## Automated Checks

### Pre-Commit Hook
```python
# .git/hooks/pre-commit
def verify_ticket_in_commit_message(message):
    ticket_id = extract_ticket_id(message)
    if ticket_id:
        verification = verify_ticket(ticket_id)
        if not verification.passed:
            print(f"WARNING: {ticket_id} verification failed!")
            print(verification.report)
            return prompt_user("Continue anyway? [y/N]")
```

### PR Template
```markdown
## Ticket Verification Checklist
- [ ] Ran `/verify-ticket TICKET-XXX`
- [ ] All acceptance criteria verified
- [ ] Work is in correct architectural layer
- [ ] QA criteria tested
- [ ] Verification report attached below

<details>
<summary>Verification Report</summary>

[Paste /verify-ticket output here]

</details>
```

## Architecture Layer Rules

### Domain Layer Detection
- Files in `Domain/` directory
- No UI imports (SwiftUI, UIKit)
- Entity/UseCase/Repository patterns

### Interface Layer Detection  
- Files in `Interface/` directory
- SwiftUI imports
- View/ViewModel patterns
- UI element creation (Button, TextField, etc.)

### Acceptance Criteria Matching
Use NLP/keyword matching:
- "button appears" → Look for `Button(` in code
- "positioned between X and Y" → Look for HStack/layout code
- "uses system blue" → Look for `.accentColor` or `Color.blue`

## Benefits

1. **Catches misinterpretation early** - Before PR is merged
2. **Enforces architecture** - Ensures correct layer implementation  
3. **Validates completeness** - All criteria must be met
4. **Creates audit trail** - Verification reports in PR history
5. **Teaches best practices** - Clear feedback on what's missing

## Future Enhancements

1. **Visual verification** - Screenshot analysis for UI tickets
2. **Test coverage verification** - Ensure tests cover acceptance criteria
3. **Dependency validation** - Check that dependent tickets are complete
4. **Auto-generate test cases** - From acceptance criteria
5. **Integration with project board** - Auto-update ticket status

## Implementation Priority

1. **Phase 1**: Basic text analysis and layer verification
2. **Phase 2**: Acceptance criteria keyword matching
3. **Phase 3**: Visual/screenshot verification
4. **Phase 4**: Full automation with PR integration