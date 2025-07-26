# Design Reference Guide

## How to Use Design References in Tickets

### Quick Reference Format

All design elements use this format: `Design:v1.2/ComponentName`

### Interactive Reference System

**threadjournal-design-complete.html** - Complete design system with all screens and states
   - **Numbered badges** (1, 2, 3...) on each component
   - **Reference legend** on the right side
   - **Click** any badge or legend item to copy reference code
   - All screens, keyboard states, and typography examples in one place

**version1.html** - Interactive prototype
   - Working navigation between screens
   - Links to complete design system

### Complete Reference List

#### Page References
```
Design:v1.2/Screen/ThreadList
Design:v1.2/Screen/ThreadDetail  
Design:v1.2/Screen/NewThread
Design:v1.2/Page/KeyboardStates
Design:v1.2/Page/KeyboardEntryStates
```

#### Component References
```
Design:v1.2/ThreadList
Design:v1.2/ThreadListItem
Design:v1.2/ThreadEntry
Design:v1.2/ComposeArea
Design:v1.2/ComposeInput
Design:v1.2/SendButton
Design:v1.2/FAB
Design:v1.2/ThreadTitleInput
Design:v1.2/MenuButton
Design:v1.2/ExportMenu
Design:v1.2/EntryContextMenu
Design:v1.2/EntryMenuButton
Design:v1.2/EditMode
Design:v1.2/DeleteConfirmation
Design:v1.2/SwipeEntry (deprecated - use EntryMenuButton)
Design:v1.2/SwipeActions (deprecated - use EntryMenuButton)
```

### Example Ticket Usage

```markdown
## Ticket: Implement Thread Entry Component

### Design Reference
Component: `Design:v1.2/ThreadEntry`
Location: `/Design/version1.html#thread-entry`

### Implementation Requirements
Build the thread entry component as shown in the design reference.

Key specifications:
- Font size: 14pt with Dynamic Type
- Timestamp: 11pt, color #8E8E93
- Left-aligned text
- 24pt bottom padding
- Divider between entries (except last)
```

### Referencing Multiple Components

```markdown
## Ticket: Build Thread Detail Screen

### Design References
- Screen: `Design:v1.2/Screen/ThreadDetail`
- Components:
  - `Design:v1.2/ThreadEntry`
  - `Design:v1.2/ComposeArea`
  - `Design:v1.2/SendButton`

See `/Design/version1.html` - click components for exact specs.
```

### Keyboard States Reference

```markdown
## Ticket: Implement Keyboard Behavior

### Design References
- Default State: `Design:v1.2/Page/KeyboardStates`
- Entry States: `Design:v1.2/Page/KeyboardEntryStates`

### Specific Requirements
- 2-3 line default height
- Expand up to 50% screen
- Auto-scroll to latest entry
- See `/Design/keyboard-entry-states.html` for all states
```

### Best Practices

1. **Always include version number** (v1.2) for tracking
2. **Reference specific components** not just pages
3. **Link to HTML file** for visual reference
4. **Use data-component attributes** to find elements

### Finding References Quickly

1. Open any design HTML file
2. Look for the blue reference guide banner (version1.html)
3. Or check the reference panel on the right (other files)
4. Click components to get their exact reference code

### Version Tracking

Current design version: **v1.2**

When designs change:
- Version will increment (e.g., v1.3)
- Old references remain valid
- Check DESIGN_GUIDELINES.md for changelog

### Component Mapping

| Visual Element | Reference Code | HTML Attribute |
|----------------|----------------|----------------|
| Thread list container | `Design:v1.2/ThreadList` | `data-component="thread-list"` |
| Individual thread card | `Design:v1.2/ThreadListItem` | `data-component="thread-list-item"` |
| Journal entry | `Design:v1.2/ThreadEntry` | `data-component="thread-entry"` |
| Entry menu button | `Design:v1.2/EntryMenuButton` | `data-component="entry-menu-button"` |
| Text input area | `Design:v1.2/ComposeArea` | `data-component="compose-area"` |
| Send button | `Design:v1.2/SendButton` | `data-component="send-button"` |
| + button | `Design:v1.2/FAB` | `data-component="fab"` |
| Menu button | `Design:v1.2/MenuButton` | `data-component="menu-button"` |
| Export menu | `Design:v1.2/ExportMenu` | `data-component="export-menu"` |
| Entry context menu | `Design:v1.2/EntryContextMenu` | `data-component="entry-context-menu"` |
| Edit mode | `Design:v1.2/EditMode` | `data-component="edit-mode"` |
| Delete confirmation | `Design:v1.2/DeleteConfirmation` | `data-component="delete-confirmation"` |
| Swipeable entry (deprecated) | `Design:v1.2/SwipeEntry` | `data-component="swipe-entry"` |
| Swipe actions (deprecated) | `Design:v1.2/SwipeActions` | `data-component="swipe-actions"` |

### Quick Copy Templates

For thread list implementation:
```
Design:v1.2/Screen/ThreadList
Design:v1.2/ThreadListItem
Design:v1.2/FAB
```

For thread detail implementation:
```
Design:v1.2/Screen/ThreadDetail
Design:v1.2/ThreadEntry
Design:v1.2/ComposeArea
Design:v1.2/SendButton
```

For keyboard handling:
```
Design:v1.2/Page/KeyboardStates
Design:v1.2/Page/KeyboardEntryStates
Design:v1.2/ComposeArea
```

For entry actions:
```
Design:v1.2/EntryMenuButton
Design:v1.2/EntryContextMenu
Design:v1.2/EditMode
Design:v1.2/DeleteConfirmation
```

For swipe actions (deprecated):
```
Design:v1.2/SwipeEntry
Design:v1.2/SwipeActions
Design:v1.2/EntryContextMenu
Design:v1.2/EditMode
Design:v1.2/DeleteConfirmation
```