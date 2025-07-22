# ThreadJournal Design Guidelines

## Overview
This document provides comprehensive design guidelines for implementing ThreadJournal. All Claude Code agents should follow these specifications to ensure consistent implementation across the codebase.

## Core Design Principles

### 1. Minimalist Zen Aesthetic
- **Clean and uncluttered**: Remove all unnecessary elements
- **Focus on content**: The journal entries are the hero
- **Subtle interactions**: No jarring animations or transitions
- **Breathing room**: Generous whitespace throughout

### 2. Local-First Philosophy
- No user profiles or authentication UI
- No social features or sharing mechanisms
- Focus on personal, private journaling

### 3. Thread-Based Mental Model
- Journals are organized as "threads of thought"
- Each thread is a continuous conversation with oneself
- Entries flow chronologically within threads

## Typography Specifications

### Dynamic Type Implementation
Use iOS Dynamic Type with a 14pt base size. All text should scale with user preferences.

```swift
// Base implementation
@ScaledMetric(relativeTo: .body) private var bodyFontSize: CGFloat = 14
@ScaledMetric(relativeTo: .caption1) private var timestampFontSize: CGFloat = 11
```

### Font Sizes (Default/Base)
| Element | Size | Weight | Line Height | iOS Text Style | Alignment |
|---------|------|--------|-------------|----------------|-----------|
| Thread Title (List) | 16pt | Semibold (600) | 1.5 | .callout + custom | Left |
| Thread Meta | 12pt | Regular (400) | 1.5 | .caption1 | Left |
| Header Title | 28pt | Bold (700) | 1.2 | .largeTitle | Left |
| Entry Content | 14pt | Regular (400) | 1.6 | Custom scaled | Left |
| Entry Timestamp | 11pt | Medium (500) | 1.5 | .caption2 | Left |
| Button Text | 15pt | Regular (400) | 1.4 | .subheadline | Center |
| Compose Input | 14pt | Regular (400) | 1.6 | Custom scaled | Left |

**Important**: All text content should be left-aligned except for buttons and centered UI elements.

### Font Family
```swift
.font(.system(size: fontSize, weight: .regular, design: .default))
```

## Color Palette

### Primary Colors
| Name | Hex | iOS System Color | Usage |
|------|-----|------------------|-------|
| Primary Text | #1C1C1E | .label | Main content text |
| Secondary Text | #8E8E93 | .secondaryLabel | Timestamps, meta |
| Tertiary Text | #C7C7CC | .tertiaryLabel | Placeholders |
| Background | #FAFAFA | .systemGroupedBackground | Main background |
| Surface | #FFFFFF | .systemBackground | Cards, screens |
| Border | #F2F2F7 | .separator | Dividers |
| Input Border | #E5E5EA | .opaqueSeparator | Form elements |
| Accent | #007AFF | .systemBlue | Interactive elements |
| Dark Surface | #1C1C1E | .label | Buttons, FAB |

### Color Implementation
```swift
// Always use semantic colors
Color(.label)
Color(.secondaryLabel)
Color(.systemBackground)
// Never use hard-coded hex values
```

## Spacing System

### Base Unit: 4pt
All spacing should be multiples of 4pt to maintain visual rhythm.

| Name | Value | Usage |
|------|-------|-------|
| xxs | 4pt | Inline spacing |
| xs | 8pt | Small gaps |
| sm | 12pt | Compact spacing |
| md | 16pt | Default spacing |
| lg | 24pt | Section spacing |
| xl | 32pt | Large sections |
| xxl | 48pt | Page margins |

### Standard Paddings
- Screen edges: 24pt
- Card padding: 20pt
- Compose area: 16pt horizontal, 20pt vertical
- Safe area bottom: 32pt

## Layout Specifications

### Screen Dimensions
- Design for iPhone 16 Pro (393×852pt)
- Ensure compatibility from iPhone SE (375×667pt) to iPad

### Component Heights
- Status bar: 44pt
- Navigation header: Variable (content + 32pt padding)
- Compose input (min): 44pt
- Touch targets (min): 44×44pt
- Floating Action Button: 56×56pt

### Border Radii
- Screen corners: 40pt (iPhone simulation)
- Cards/Buttons: 16-22pt
- Input fields: 22pt
- FAB: 28pt (circle)

## Navigation Pattern

### No Bottom Tab Bar
- Single floating "+" button for new threads
- Back navigation via header button
- No persistent navigation elements

### Screen Transitions
- Push/pop for navigation
- Subtle fade for modals
- No custom transitions

## Component Specifications

### Thread List Item
```
┌─────────────────────────────────┐
│ [Thread Title]           16pt SB │ <- 20pt padding
│ [Meta: X entries • time] 12pt R │ <- 4pt gap
└─────────────────────────────────┘
   └─ Background: #F8F8F8
   └─ Border Radius: 16pt
   └─ Margin Bottom: 16pt
```

### Thread Entry
```
[Timestamp] 11pt Medium, #8E8E93
   8pt gap ↓
[Entry Content] 14pt Regular, #1C1C1E
   24pt gap ↓
─────────────── 1pt border #F2F2F7
```

### Compose Area
```
┌─────────────────────────────────┐
│ ┌─────────────────┐ ┌─────────┐ │
│ │ Placeholder...  │ │  Send → │ │
│ └─────────────────┘ └─────────┘ │
└─────────────────────────────────┘
   └─ Background: white with blur
   └─ Border Top: 1pt #E5E5EA
   └─ Padding: 20pt sides, 32pt bottom
```

## States & Interactions

### Touch States
- Default: No effect
- Hover/Press: Subtle background change
- Active: Scale 0.95 with spring animation

### Colors by State
| Component | Default | Hover | Active | Disabled |
|-----------|---------|-------|--------|----------|
| Thread Card | #F8F8F8 | #F2F2F7 | #F2F2F7 + shadow | #FAFAFA |
| FAB | #1C1C1E | scale(1.05) | scale(0.95) | opacity(0.5) |
| Input | #F2F2F7 border | #007AFF border | #007AFF border | #F8F8F8 |

## Animations

### Timing
- Duration: 0.2s for micro-interactions
- Easing: Use iOS spring animations
- No delays unless necessary

### Types
```swift
// Recommended animations
.animation(.spring(response: 0.3, dampingFraction: 0.8))
.transition(.opacity.combined(with: .scale(scale: 0.95)))
```

## Accessibility Requirements

### Text
- Support Dynamic Type (11pt to 40pt range)
- Minimum contrast ratio: 4.5:1
- All text must be selectable

### Interaction
- All interactive elements: minimum 44×44pt
- Clear focus indicators
- VoiceOver labels for all UI elements

### Motion
- Respect "Reduce Motion" settings
- Provide static alternatives

## Platform-Specific Notes

### iOS/SwiftUI Implementation
1. Use system colors exclusively
2. Implement `@Environment(\.dynamicTypeSize)`
3. Use `.safeAreaInset()` for compose area
4. Implement keyboard avoidance
5. Support both portrait and landscape

### Safe Areas
- Respect safe area insets
- Compose area above home indicator
- Content scrolls under status bar

## File References

### Design Files
- Complete design system: `/Design/threadjournal-design-complete.html` (includes all screens, keyboard states, and typography)
- Interactive prototype: `/Design/version1.html`

### How to Reference in Code
```swift
// Component references match HTML data attributes
// Example: data-component="thread-entry"
struct ThreadEntry: View {
    // Implements design from version1.html thread-entry
}
```

## Version Control
- Design Version: 1.3
- Last Updated: 2025-07-18
- Changes in v1.3:
  - Added three-dot menu button to thread detail header
  - Added CSV export functionality with iOS share sheet
  - Export filename format: ThreadName_YYYYMMDD_HHMM.csv
- Changes in v1.2:
  - All text content now left-aligned (except buttons)
  - Added comprehensive keyboard entry states documentation
  - Fullscreen compose mode design
- Changes in v1.1:
  - Added send button to thread detail compose area
  - Reversed thread order (latest at bottom)
  - Auto-scroll to latest entry on load
  - Added keyboard state visualization
- Breaking changes will increment major version

---

**Important**: Always refer to the HTML prototypes in the Design folder for visual reference. When in doubt, match the prototype exactly.