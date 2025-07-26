# Feature Request Process

A concise guide for properly intaking and implementing feature requests in ThreadJournal2.

## 5-Step Process

### 1. Exchange with User
**Goal:** Understand the actual need, not just the surface request

- Ask clarifying questions about the problem they're trying to solve
- Understand the context and frequency of the issue
- Identify if this aligns with the app's zen/minimal philosophy
- Consider alternative solutions that might be simpler
- Document the core need in plain language

### 2. Design
**Goal:** Visualize the solution before any code is written

- Create HTML mockups or sketches showing the proposed change
- Show before/after comparisons when modifying existing features
- Include multiple variations if applicable
- Consider edge cases (long text, different screen sizes, etc.)
- Ensure consistency with existing design patterns
- Reference: Use `Design:v1.2` component naming convention

### 3. Write Ticket (Requirements Only)
**Goal:** Document what needs to be built without implementation details

- Create ticket in `Tickets/Tickets.md` following existing format
- Include:
  - Clear problem statement
  - User story (As a... I want... So that...)
  - Design references (link to mockups)
  - Acceptance criteria (user-facing requirements)
  - QA test criteria
- Exclude technical implementation details at this stage

### 4. Update Technical Implementation Plan
**Goal:** Figure out how to build it properly

- Review `Engineering/Technical-Implementation-Plan.md`
- Identify which layers need modification (Domain, Application, Interface, Infrastructure)
- Consider architectural impacts
- Update relevant sections with new technical approach
- Ensure Clean Architecture principles are maintained
- Plan for testability and performance

### 5. Revise Ticket with Technical Details
**Goal:** Complete ticket is ready for implementation

- Add technical implementation section to the ticket
- Reference specific sections from Technical Implementation Plan
- Include:
  - Affected files and components
  - New use cases or entities needed
  - Testing approach (unit, integration, performance)
  - Dependencies on other tickets
- Assign to appropriate sprint based on priority

## Example: Blue Circle Timestamp Feature

1. **Exchange:** User wants timestamps to be more visible
2. **Design:** Created `blue-circle-timestamp-mockup.html` showing subtle blue background
3. **Initial Ticket:** "As a user, I want timestamps to stand out more so I can quickly scan when entries were made"
4. **Tech Plan Update:** Updated UI Components section with new timestamp styling approach
5. **Final Ticket:** Added implementation details for `ThreadDetailView` timestamp modifier

## Quick Checklist

- [ ] Understood the real problem
- [ ] Created visual design/mockup
- [ ] Wrote user-focused ticket
- [ ] Updated technical plans
- [ ] Added implementation details to ticket

## Important Notes

- Never skip the design phase - visuals prevent misunderstandings
- Keep the user's actual need in focus throughout
- Maintain app's zen/minimal aesthetic in all features
- Test criteria should be user-facing, not technical
- Reference existing patterns before creating new ones