# ThreadJournal Component Reference

## Component Catalog

### 1. Thread List Screen (`thread-list`)

#### ThreadListItem
```html
<div data-component="thread-list-item" 
     data-state="default|hover|pressed">
```

**Properties:**
- `title`: String (16pt, Semibold)
- `entryCount`: Number
- `lastUpdated`: RelativeTime
- `onTap`: () -> Navigation

**SwiftUI Implementation:**
```swift
struct ThreadListItem: View {
    let thread: Thread
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(thread.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.label)
            
            Text("\(thread.entries.count) entries • \(thread.lastUpdated.relative)")
                .font(.system(size: 12))
                .foregroundColor(.secondaryLabel)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.systemGray6))
        .cornerRadius(16)
    }
}
```

**States:**
- Default: Background #F8F8F8
- Hover: Background #F2F2F7
- Pressed: Background #F2F2F7 + translateY(-1px)

---

### 2. Thread Detail Screen (`thread-detail`)

#### ThreadEntry
```html
<div data-component="thread-entry"
     data-has-divider="true|false">
```

**Properties:**
- `timestamp`: Date
- `content`: String
- `isLast`: Boolean (controls divider)

**SwiftUI Implementation:**
```swift
struct ThreadEntry: View {
    let entry: Entry
    let isLast: Bool
    
    @ScaledMetric(relativeTo: .body) private var contentSize: CGFloat = 14
    @ScaledMetric(relativeTo: .caption2) private var timestampSize: CGFloat = 11
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.timestamp.formatted())
                .font(.system(size: timestampSize, weight: .medium))
                .foregroundColor(.secondaryLabel)
            
            Text(entry.content)
                .font(.system(size: contentSize))
                .foregroundColor(.label)
                .lineSpacing(contentSize * 0.6)
        }
        .padding(.bottom, 24)
        .overlay(alignment: .bottom) {
            if !isLast {
                Divider()
                    .background(Color(UIColor.separator))
                    .padding(.top, 24)
            }
        }
    }
}
```

---

### 3. Navigation Components

#### NavigationHeader
```html
<div data-component="nav-header"
     data-variant="simple|back|close">
```

**Variants:**
- `simple`: Title only (Thread List)
- `back`: Back button + Title (Thread Detail)
- `close`: X button + Title (New Thread)

**SwiftUI Implementation:**
```swift
struct NavigationHeader: View {
    enum Variant {
        case simple(title: String)
        case back(title: String, action: () -> Void)
        case close(action: () -> Void)
    }
    
    let variant: Variant
    
    var body: some View {
        HStack {
            switch variant {
            case .simple(let title):
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                
            case .back(let title, let action):
                Button(action: action) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20))
                        .foregroundColor(.accentColor)
                }
                .frame(width: 36, height: 36)
                
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                
            case .close(let action):
                Button(action: action) {
                    Image(systemName: "xmark")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .frame(width: 36, height: 36)
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }
}
```

---

### 4. Input Components

#### ComposeArea
```html
<div data-component="compose-area"
     data-state="empty|typing|focused">
```

**Properties:**
- `placeholder`: String
- `value`: String (binding)
- `onSend`: (String) -> Void
- `onExpand`: () -> Void
- `minHeight`: 44pt
- `maxHeight`: 50% of screen

#### ExpandButton
```html
<button data-component="expand-button">
```

**Properties:**
- `action`: Opens fullscreen compose mode
- `icon`: Expand arrow (↗️)
- `color`: #8E8E93 (default), #007AFF (active)
- `size`: 36×36pt
- `position`: Top right of compose area

**SwiftUI Implementation:**
```swift
struct ComposeArea: View {
    @Binding var text: String
    let placeholder: String
    let onSend: () -> Void
    let onExpand: () -> Void
    
    @ScaledMetric(relativeTo: .body) private var fontSize: CGFloat = 14
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextField(placeholder, text: $text, axis: .vertical)
                .font(.system(size: fontSize))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(22)
                .lineLimit(1...5)
                .focused($isFocused)
            
            Button(action: onExpand) {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 20))
                    .foregroundColor(.secondary)
                    .frame(width: 36, height: 36)
                    .background(Color.clear)
                    .clipShape(Circle())
            }
            
            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.primary)
                    .clipShape(Circle())
            }
            .disabled(text.isEmpty)
            .opacity(text.isEmpty ? 0.5 : 1)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(.regularMaterial)
    }
}
```

---

### 5. Action Components

#### FloatingActionButton
```html
<div data-component="fab"
     data-action="new-thread">
```

**Properties:**
- `icon`: "plus"
- `action`: () -> Void
- `size`: 56×56pt
- `position`: bottom-right, 24pt margins

**SwiftUI Implementation:**
```swift
struct FloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.primary)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        }
        .scaleEffect(1)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                // Scale animation handled by button style
            }
        }
    }
}
```

---

### 6. New Thread Components

#### ThreadTitleInput
```html
<div data-component="thread-title-input"
     data-state="empty|filled">
```

**Properties:**
- `placeholder`: "Name your thread..."
- `value`: String (binding)
- `fontSize`: 28pt (matches header)

**SwiftUI Implementation:**
```swift
struct ThreadTitleInput: View {
    @Binding var title: String
    
    var body: some View {
        TextField("Name your thread...", text: $title)
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(.label)
            .padding(.horizontal, 24)
            .padding(.top, 16)
    }
}
```

---

## Component States Reference

### Interactive States
| Component | Default | Hover | Active | Disabled |
|-----------|---------|-------|--------|----------|
| ThreadListItem | opacity: 1 | bg: #F2F2F7 | scale: 0.98 | opacity: 0.6 |
| FAB | scale: 1 | scale: 1.05 | scale: 0.95 | opacity: 0.5 |
| Send Button | opacity: 1 | scale: 1.05 | scale: 0.95 | opacity: 0.5 |
| Back Button | opacity: 1 | bg: #F2F2F7 | opacity: 0.7 | - |

### Focus States
- Text inputs: Blue border (#007AFF)
- Buttons: System focus ring
- List items: Outline with 2pt offset

---

### 7. Menu & Export Components

#### MenuButton (Three-dot menu)
```html
<button data-component="menu-button">
```

**Properties:**
- `icon`: Three vertical dots
- `position`: Top right of header
- `action`: Toggles dropdown menu

**SwiftUI Implementation:**
```swift
Button(action: { showMenu.toggle() }) {
    Image(systemName: "ellipsis")
        .font(.system(size: 20))
        .foregroundColor(.label)
        .frame(width: 36, height: 36)
}
```

#### ExportMenu
```html
<div data-component="export-menu">
```

**Menu Items:**
- Export as CSV

**CSV Export Properties:**
- `filename`: ThreadName_YYYYMMDD_HHMM.csv
- `columns`: ["Date & Time", "Entry Content"]
- `action`: Opens iOS share sheet

**SwiftUI Implementation:**
```swift
Menu {
    Button(action: exportToCSV) {
        Label("Export as CSV", systemImage: "arrow.down.doc")
    }
} label: {
    Image(systemName: "ellipsis")
}

func exportToCSV() {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd_HHmm"
    let timestamp = dateFormatter.string(from: Date())
    let filename = "\(thread.title)_\(timestamp).csv"
    
    // Generate CSV content
    var csvContent = "Date & Time,Entry Content\n"
    for entry in thread.entries {
        let entryDate = DateFormatter.localizedString(from: entry.timestamp, 
                                                     dateStyle: .medium, 
                                                     timeStyle: .short)
        let content = entry.content.replacingOccurrences(of: "\"", with: "\"\"")
        csvContent += "\"\(entryDate)\",\"\(content)\"\n"
    }
    
    // Show share sheet
    let activityVC = UIActivityViewController(
        activityItems: [csvContent, filename],
        applicationActivities: nil
    )
    present(activityVC, animated: true)
}
```

---

## Animation Specifications

### Standard Transitions
```swift
// List item interactions
.animation(.spring(response: 0.3, dampingFraction: 0.8))

// Navigation transitions
.transition(.asymmetric(
    insertion: .move(edge: .trailing),
    removal: .move(edge: .leading)
))

// FAB interactions
.animation(.interpolatingSpring(stiffness: 300, damping: 20))
```

### Timing Guidelines
- Micro-interactions: 0.2s
- Page transitions: 0.3s
- Keyboard appearance: Match system

---

## Responsive Behavior

### Keyboard Handling
```swift
.safeAreaInset(edge: .bottom) {
    ComposeArea(...)
}
.ignoresSafeArea(.keyboard, edges: .bottom)
```

### Scroll Behavior
- Bounce: Enabled
- Indicators: Hidden
- Keyboard dismiss: Interactive

### Orientation Support
- Portrait: Primary
- Landscape: Supported with layout adjustments
- iPad: Multi-column layout for thread list

---

## Accessibility Specifications

### VoiceOver Labels
```swift
ThreadListItem()
    .accessibilityLabel("\(thread.title), \(thread.entries.count) entries")
    .accessibilityHint("Double tap to open thread")
    
FloatingActionButton()
    .accessibilityLabel("New thread")
    .accessibilityHint("Double tap to create a new journal thread")
```

### Dynamic Type Support
All text components must use `@ScaledMetric` for proper scaling.

### Focus Management
```swift
@AccessibilityFocusState var isNewThreadFocused: Bool

ThreadTitleInput()
    .accessibilityFocused($isNewThreadFocused)
    .onAppear {
        isNewThreadFocused = true
    }
```

---

### 8. Entry Management Components

#### EntryContextMenu
```html
<div data-component="entry-context-menu"
     data-trigger="long-press">
```

**Properties:**
- `entry`: Entry
- `onEdit`: () -> Void
- `onDelete`: () -> Void

**SwiftUI Implementation:**
```swift
struct EntryView: View {
    let entry: Entry
    @ObservedObject var viewModel: ThreadDetailViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Entry content...
        }
        .contextMenu {
            Button(action: { 
                viewModel.startEditingEntry(entry) 
            }) {
                Label("Edit", systemImage: "pencil")
            }
            
            Button(role: .destructive, action: { 
                viewModel.confirmDeleteEntry(entry) 
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
```

**Interaction:**
- Trigger: Long press (0.5 seconds)
- Haptic feedback: Medium impact
- Menu position: Auto-positioned by iOS

---

#### EditMode
```html
<div data-component="edit-mode"
     data-state="editing">
```

**Properties:**
- `originalContent`: String
- `editedContent`: String (binding)
- `onSave`: () -> Void
- `onCancel`: () -> Void
- `autoHeight`: Bool (true) - TextEditor expands to fit content

**SwiftUI Implementation:**
```swift
struct EditModeView: View {
    @Binding var editingContent: String
    let originalContent: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel", action: onCancel)
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                Button("Save", action: onSave)
                    .foregroundColor(.accentColor)
                    .fontWeight(.semibold)
                    .disabled(editingContent == originalContent || editingContent.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            TextEditor(text: $editingContent)
                .font(.system(size: 17))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .fixedSize(horizontal: false, vertical: true)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
```

**States:**
- Save button disabled when content unchanged or empty
- TextEditor auto-focused on appear
- TextEditor height adjusts to content (no internal scrolling)
- Other entries dimmed (50% opacity)

---

#### DeleteConfirmation
```html
<div data-component="delete-confirmation"
     data-type="alert">
```

**Properties:**
- `entryToDelete`: Entry?
- `onConfirm`: () -> Void
- `onCancel`: () -> Void

**SwiftUI Implementation:**
```swift
.alert("Delete Entry?", isPresented: $viewModel.showDeleteConfirmation) {
    Button("Cancel", role: .cancel) {
        viewModel.entryToDelete = nil
    }
    
    Button("Delete", role: .destructive) {
        Task {
            await viewModel.deleteEntry()
        }
    }
} message: {
    Text("This entry will be removed from your journal.")
}
```

**Specifications:**
- Title: "Delete Entry?"
- Message: "This entry will be removed from your journal."
- Cancel button: Default style
- Delete button: Destructive (red)
- Default focus: Cancel button

---

## Component Versioning
- Component Version: 1.2
- Changes in v1.2:
  - Added EntryContextMenu for edit/delete functionality
  - Added EditMode component for inline editing
  - Added DeleteConfirmation alert component
- Changes in v1.1:
  - ComposeArea now includes send button in thread detail
  - Thread entries ordered chronologically (oldest to newest)
  - Auto-scroll behavior on thread load
  - Keyboard handling specifications added
- Breaking changes require version bump
- Non-breaking additions allowed within version

## Keyboard Behavior Reference
See `/Design/threadjournal-design-complete.html` Section 2 for visual keyboard interaction states