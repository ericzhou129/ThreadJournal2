# ThreadJournal Ticket Template & Design Reference Guide

## How to Write Tickets That Reference Designs

### Ticket Template

```markdown
## Ticket: [Feature Name]

### Design References
- Complete Design System: `/Design/threadjournal-design-complete.html`
- Design Guidelines: `/Design/DESIGN_GUIDELINES.md`
- Component Specs: `/Design/COMPONENT_REFERENCE.md`
- Implementation Checklist: `/Design/IMPLEMENTATION_CHECKLIST.md`

### Specific Components
This ticket implements the following components from `COMPONENT_REFERENCE.md`:
- [ ] ThreadListItem (Section 1)
- [ ] ComposeArea (Section 4)
- [ ] FloatingActionButton (Section 5)

### Acceptance Criteria
1. Matches visual design in version1.html exactly
2. Implements Dynamic Type with 14pt base (see DESIGN_GUIDELINES.md#typography)
3. Uses iOS semantic colors only (see DESIGN_GUIDELINES.md#colors)
4. All components pass IMPLEMENTATION_CHECKLIST.md verification

### Technical Notes
- Reference data attributes in HTML: `data-component="thread-list-item"`
- Follow SwiftUI examples in COMPONENT_REFERENCE.md
- Maintain design version compatibility (currently v1.0)
```

## Example Tickets

### Example 1: Thread List Implementation

```markdown
## Ticket: Implement Thread List Screen

### Design References
- Visual Design: `/Design/version1.html` (Thread List Screen)
- Guidelines: `/Design/DESIGN_GUIDELINES.md#layout-specifications`
- Components: `/Design/COMPONENT_REFERENCE.md#1-thread-list-screen`

### Implementation Requirements
1. Create ThreadListView following the HTML structure with data-component="thread-list"
2. Implement ThreadListItem component:
   - 16pt Semibold title (Dynamic Type scaled)
   - 12pt Regular metadata
   - #F8F8F8 background with 16pt corner radius
   - 20pt internal padding
3. Add FloatingActionButton:
   - Position: bottom-right, 24pt margins
   - Size: 56×56pt
   - Reference: `data-component="fab"`

### Verification
Run through `/Design/IMPLEMENTATION_CHECKLIST.md#thread-list` section
```

### Example 2: Dynamic Type Update

```markdown
## Ticket: Update Text Sizing to Dynamic Type

### Design References
- Typography Spec: `/Design/DESIGN_GUIDELINES.md#typography-specifications`
- Demo: `/Design/dynamic-type-demo.html`

### Changes Required
1. Replace all fixed font sizes with @ScaledMetric
2. Base sizes:
   - Body text: 14pt (not 17pt)
   - Timestamps: 11pt
   - Thread titles: 16pt
3. Test with iOS Accessibility settings

### Code Pattern
```swift
@ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 14
```
```

## Best Practices for Design References

### 1. Always Reference Multiple Documents
```markdown
### Design References
- Visual: `/Design/version1.html`
- Specs: `/Design/DESIGN_GUIDELINES.md`
- Components: `/Design/COMPONENT_REFERENCE.md`
```

### 2. Link to Specific Sections
```markdown
- Color implementation: `/Design/DESIGN_GUIDELINES.md#color-palette`
- Thread entry component: `/Design/COMPONENT_REFERENCE.md#threadentry`
```

### 3. Reference Data Attributes
```markdown
The HTML prototype uses `data-component="thread-list-item"` to mark this component.
Implement the matching SwiftUI view.
```

### 4. Include Visual Markers
```markdown
### Visual Reference
- Background color: systemGray6 (#F8F8F8)
- Corner radius: 16pt
- See version1.html lines with `data-component="thread-list-item"`
```

## Handling Design Changes During Development

### Strategy 1: Version Your Design Docs
```markdown
## Design Version Tracking
- Current Version: 1.0
- Last Updated: 2025-07-18
- Breaking Changes: Will increment to 2.0
```

### Strategy 2: Use Component IDs
```markdown
## Component: thread-entry-v1
If design changes, create thread-entry-v2 while maintaining v1 for compatibility
```

### Strategy 3: Design Change Log
Create `/Design/CHANGELOG.md`:
```markdown
## Design Changes

### 2025-07-19
- Updated base font size from 17pt to 14pt
- Affected components: All text elements
- Migration: Update @ScaledMetric base values
```

### Strategy 4: Ticket Metadata
```markdown
## Ticket: Feature Name
**Design Version**: 1.0
**Last Verified**: 2025-07-18

If designs change after this date, reverify implementation.
```

## Quick Reference Snippets

### For Claude Code Agents

```markdown
IMPORTANT: This app follows specific design guidelines located in /Design/:
1. Read DESIGN_GUIDELINES.md for principles and specifications
2. Check COMPONENT_REFERENCE.md for exact component implementations
3. Open version1.html in browser to see visual design
4. Verify implementation with IMPLEMENTATION_CHECKLIST.md

Key specs:
- Base text: 14pt with Dynamic Type
- Colors: iOS semantic only (no hex)
- No bottom navigation
- Minimalist zen aesthetic
```

### For Ticket Descriptions

```markdown
This implementation must match the design system in /Design/.
Key files:
- version1.html: Visual prototype with data-* attributes
- DESIGN_GUIDELINES.md: Core specifications
- COMPONENT_REFERENCE.md: SwiftUI implementations

Non-negotiable requirements:
- 14pt Dynamic Type base (not 17pt)
- Semantic colors only
- Exact spacing per guidelines
```

## Maintaining Consistency

### 1. Single Source of Truth
- `/Design/` folder contains all design specifications
- HTML prototypes are the visual reference
- Markdown docs provide implementation details

### 2. Regular Sync Points
- Design review before implementation
- Mid-sprint design verification
- Final QA against prototypes

### 3. Clear Communication
- Reference specific line numbers or sections
- Use component names from data attributes
- Link to exact specifications

This approach ensures that no matter how many Claude Code agents work on the project, they all implement the same design consistently.