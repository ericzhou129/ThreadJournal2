# ThreadJournal Implementation Checklist

Use this checklist to verify your implementation matches the design specifications.

## Pre-Implementation Setup

- [ ] Read `DESIGN_GUIDELINES.md` completely
- [ ] Review `COMPONENT_REFERENCE.md` for specific components
- [ ] Open `version1.html` in browser for visual reference
- [ ] Set up iOS simulator at iPhone 16 Pro resolution (393×852pt)

## Typography Implementation

### Dynamic Type Setup
- [ ] Implement `@ScaledMetric` for all text sizes
- [ ] Base font size set to 14pt (not 17pt)
- [ ] Timestamp size set to 11pt
- [ ] All text scales with system text size settings

### Font Specifications
- [ ] Using SF Pro Text (system font)
- [ ] Font weights match spec (Regular, Medium, Semibold, Bold)
- [ ] Line heights implemented (1.6 for body, 1.5 for meta)
- [ ] Letter spacing on headers (-0.5pt for main title)

## Color Implementation

### System Colors
- [ ] Using iOS semantic colors (never hex values)
- [ ] `.label` for primary text (#1C1C1E)
- [ ] `.secondaryLabel` for timestamps (#8E8E93)
- [ ] `.systemBackground` for surfaces
- [ ] `.separator` for dividers
- [ ] Dark mode automatically supported

### Component Colors
- [ ] Thread cards use `.systemGray6` (#F8F8F8)
- [ ] Compose input background `.systemGray6`
- [ ] FAB uses `.label` (black) not `.systemBlue`
- [ ] Send button matches FAB color

## Layout & Spacing

### Screen Layout
- [ ] 24pt padding on screen edges
- [ ] Status bar height respected (44pt)
- [ ] No bottom tab bar implemented
- [ ] Safe area insets handled properly

### Component Spacing
- [ ] Thread list items: 16pt gap between
- [ ] Thread entries: 24pt bottom padding
- [ ] Entry content: 8pt below timestamp
- [ ] Compose area: 20pt horizontal padding

### Touch Targets
- [ ] All buttons minimum 44×44pt
- [ ] FAB is 56×56pt
- [ ] Send button is 44×44pt
- [ ] Back/close buttons 36×36pt with larger hit area

## Navigation

### Screen Transitions
- [ ] Push/pop navigation (not modal)
- [ ] No custom transition animations
- [ ] Back button shows chevron.left icon
- [ ] Close button (X) for new thread only

### Floating Action Button
- [ ] Positioned bottom-right with 24pt margins
- [ ] Shows + icon (28pt size)
- [ ] Subtle shadow (black 20% opacity)
- [ ] Scale animation on tap

## Components

### Thread List
- [ ] Cards have 16pt corner radius
- [ ] 20pt internal padding
- [ ] Title is 16pt Semibold
- [ ] Meta text is 12pt Regular
- [ ] Hover state changes background

### Thread Detail
- [ ] Entries separated by 1pt divider
- [ ] Last entry has no divider
- [ ] Timestamps above content
- [ ] Content wraps naturally
- [ ] Scrollable with hidden indicators

### Compose Area
- [ ] Sticky to bottom of screen
- [ ] Blurred background effect
- [ ] Input expands vertically (max 5 lines)
- [ ] Send button disabled when empty
- [ ] Keyboard avoidance implemented

### New Thread
- [ ] Title input at top (no "New Thread" header)
- [ ] 28pt font for title input
- [ ] Placeholder: "Name your thread..."
- [ ] Same compose area as thread detail

## Interactions & Animations

### Touch Feedback
- [ ] List items scale to 0.98 on press
- [ ] FAB scales to 1.05 on hover, 0.95 on press
- [ ] Spring animations (0.3s response time)
- [ ] No delay on interactions

### Keyboard Behavior
- [ ] Compose area moves with keyboard
- [ ] Content scrolls to show new entries
- [ ] Dismiss on scroll (interactive)
- [ ] Return key adds line break (not send)

## Accessibility

### VoiceOver
- [ ] All elements have accessibility labels
- [ ] Hints provided for actions
- [ ] Proper element grouping
- [ ] Focus management on screen changes

### Dynamic Type
- [ ] Text scales from ~11pt to ~40pt
- [ ] Layout adjusts for larger text
- [ ] No text truncation at large sizes
- [ ] Minimum contrast ratios met

## Performance

### Optimization
- [ ] List virtualization for many threads
- [ ] Smooth scrolling (60fps)
- [ ] No unnecessary re-renders
- [ ] Efficient state management

## Error States

### Empty States
- [ ] Helpful message when no threads
- [ ] Clear CTA to create first thread
- [ ] Consistent with overall design

### Input Validation
- [ ] Thread title required before first entry
- [ ] No error messages (inline prevention)
- [ ] Graceful handling of long text

## Final Verification

### Visual Comparison
- [ ] Side-by-side with version1.html
- [ ] Colors match exactly
- [ ] Spacing is identical
- [ ] Animations feel natural

### Cross-Device Testing
- [ ] iPhone SE (smallest)
- [ ] iPhone 16 Pro (target)
- [ ] iPhone 16 Pro Max (largest)
- [ ] iPad (if supported)

### User Flow Testing
- [ ] Create new thread flow
- [ ] Add entries to thread
- [ ] Navigate between screens
- [ ] All interactions feel smooth

## Sign-Off

- [ ] Design lead approval
- [ ] Code review completed
- [ ] Accessibility audit passed
- [ ] Performance benchmarks met

---

**Note**: Any deviations from the design must be documented with rationale and approved before implementation.