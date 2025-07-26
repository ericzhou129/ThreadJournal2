//
//  ThreadDetailViewFixed.swift
//  ThreadJournal2
//
//  A fixed version of ThreadDetailView with proper layout
//

import SwiftUI

struct ThreadDetailViewFixed: View {
    let threadId: UUID
    @StateObject private var viewModel: ThreadDetailViewModel
    
    @State private var isExpanded = false
    @State private var showingExportMenu = false
    @State private var showingShareSheet = false
    @FocusState private var isComposeFieldFocused: Bool
    @State private var textEditorHeight: CGFloat = 44
    @State private var heightUpdateTimer: Timer?
    
    @ScaledMetric(relativeTo: .subheadline) private var timestampSize = 11
    @ScaledMetric(relativeTo: .body) private var contentSize = 14
    
    private let bottomID = "bottom"
    
    // Timestamp background color that adapts to light/dark mode
    @Environment(\.colorScheme) private var colorScheme
    private var timestampBackgroundColor: Color {
        colorScheme == .dark
            ? Color(red: 0.15, green: 0.25, blue: 0.40) // Darker blue for dark mode
            : Color(red: 0.91, green: 0.95, blue: 1.0)  // #E8F3FF for light mode
    }
    
    init(
        threadId: UUID,
        repository: ThreadRepository,
        addEntryUseCase: AddEntryUseCase,
        updateEntryUseCase: UpdateEntryUseCase,
        deleteEntryUseCase: DeleteEntryUseCase,
        draftManager: DraftManager,
        exportThreadUseCase: ExportThreadUseCase
    ) {
        self.threadId = threadId
        let viewModel = ThreadDetailViewModel(
            repository: repository,
            addEntryUseCase: addEntryUseCase,
            updateEntryUseCase: updateEntryUseCase,
            deleteEntryUseCase: deleteEntryUseCase,
            draftManager: draftManager,
            exportThreadUseCase: exportThreadUseCase
        )
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            // Entries list
            entriesListView
            
            // Compose area overlay at bottom
            composeAreaView
        }
        .navigationTitle(viewModel.thread?.title ?? "")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                menuButton
            }
        }
        .onAppear {
            Task {
                await viewModel.loadThread(id: threadId)
            }
        }
        .onDisappear {
            // Clean up timer to prevent memory leaks
            heightUpdateTimer?.invalidate()
            heightUpdateTimer = nil
        }
        .fullScreenCover(isPresented: $isExpanded) {
            expandedComposeView
        }
        .sheet(isPresented: $showingShareSheet) {
            if let fileURL = viewModel.exportedFileURL {
                ShareSheet(activityItems: [fileURL])
            }
        }
        .alert("Export Failed", isPresented: .constant(viewModel.exportError != nil)) {
            Button("OK") {
                viewModel.exportError = nil
            }
        } message: {
            if let error = viewModel.exportError {
                Text(error)
            }
        }
        .onChange(of: viewModel.exportedFileURL) { _, newValue in
            if newValue != nil {
                showingShareSheet = true
            }
        }
        .overlay {
            if viewModel.isExporting {
                exportingOverlay
            }
        }
        .alert("Delete Entry?", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelDeleteEntry()
            }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.executeDeleteEntry()
                }
            }
        } message: {
            Text("This entry will be removed from your journal.")
        }
    }
    
    private var entriesListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if viewModel.entries.isEmpty && !viewModel.isLoading {
                        emptyStateView
                    } else {
                        entriesContentView
                    }
                    
                    // Bottom spacer for compose area
                    Color.clear
                        .frame(height: 1)
                        .id(bottomID)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 120) // Space for compose area
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: viewModel.entries.count) { _, _ in
                withAnimation {
                    proxy.scrollTo(bottomID, anchor: .bottom)
                }
            }
            .onChange(of: isComposeFieldFocused) { _, isFocused in
                if isFocused {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation {
                            proxy.scrollTo(bottomID, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "text.bubble")
                .font(.system(size: 48))
                .foregroundColor(Color(.tertiaryLabel))
            
            Text("No entries yet")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(.secondaryLabel))
            
            Text("Start journaling by typing below")
                .font(.system(size: 16))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
    
    private var entriesContentView: some View {
        ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
            if viewModel.editingEntry?.id == entry.id {
                // Edit mode UI
                editModeView(entry: entry, isLast: index == viewModel.entries.count - 1)
            } else {
                // Normal entry view
                entryView(entry: entry, isLast: index == viewModel.entries.count - 1)
                    .opacity(viewModel.editingEntry != nil ? 0.5 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: viewModel.editingEntry)
            }
        }
    }
    
    private var composeAreaView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 0) {
                Divider()
                
                HStack(alignment: .bottom, spacing: 12) {
                    composeTextField
                    expandButton
                    sendButton
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(.regularMaterial)
        }
    }
    
    private var composeTextField: some View {
        ZStack(alignment: .topLeading) {
            if viewModel.draftContent.isEmpty {
                Text("Add to journal...")
                    .font(.system(size: 17))
                    .foregroundColor(Color(.placeholderText))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 11)
                    .allowsHitTesting(false)
            }
            
            TextEditor(text: $viewModel.draftContent)
                .font(.system(size: 17))
                .foregroundColor(Color(.label))
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .focused($isComposeFieldFocused)
                .frame(height: textEditorHeight)
                .frame(maxHeight: 220)
                .onChange(of: viewModel.draftContent) { _, _ in
                    // Cancel previous timer
                    heightUpdateTimer?.invalidate()
                    
                    // Debounce height updates to prevent lag
                    heightUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { _ in
                        updateTextEditorHeight()
                    }
                }
                .onAppear {
                    updateTextEditorHeight()
                }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
        )
    }
    
    private var expandButton: some View {
        Button(action: {
            isExpanded = true
        }) {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color(.label))
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color(.systemGray5)))
        }
    }
    
    private var sendButton: some View {
        Button(action: {
            Task {
                await viewModel.addEntry()
                isComposeFieldFocused = true
                textEditorHeight = 44 // Reset height after sending
            }
        }) {
            Image(systemName: "arrow.up")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(viewModel.canSendEntry ? Color.accentColor : Color(.systemGray3))
                )
        }
        .disabled(!viewModel.canSendEntry)
    }
    
    private var exportingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()
            .overlay(
                ProgressView("Exporting...")
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(10)
            )
    }
    
    private func entryView(entry: Entry, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Entry content
            VStack(alignment: .leading, spacing: 8) {
                // Timestamp with edited indicator
                HStack(spacing: 4) {
                    Text(formatTimestamp(entry.timestamp))
                        .font(.system(size: timestampSize, weight: .medium))
                        .foregroundColor(Color(.secondaryLabel))
                        .padding(.vertical, 2)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(timestampBackgroundColor)
                                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 1.5, x: 0, y: 1)
                        )
                    
                    if viewModel.editedEntryIds.contains(entry.id) {
                        Text("(edited)")
                            .font(.system(size: timestampSize, weight: .medium))
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
                
                // Content
                Text(entry.content)
                    .font(.system(size: contentSize))
                    .foregroundColor(Color(.label))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Menu button
            Menu {
                Button {
                    viewModel.startEditingEntry(entry)
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                    viewModel.confirmDeleteEntry(entry)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(Color(.secondaryLabel))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .simultaneousGesture(
                TapGesture().onEnded { _ in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            )
        }
        .padding(.bottom, isLast ? 0 : 24)
        .overlay(alignment: .bottom) {
            if !isLast {
                Divider()
                    .padding(.top, 40)
            }
        }
    }
    
    private func editModeView(entry: Entry, isLast: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Timestamp remains visible above edit box
            Text(formatTimestamp(entry.timestamp))
                .font(.system(size: timestampSize, weight: .medium))
                .foregroundColor(Color(.secondaryLabel))
                .padding(.vertical, 2)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(timestampBackgroundColor)
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 1.5, x: 0, y: 1)
                )
            
            // Edit text field - no internal scrolling, expands to fit content
            TextEditor(text: $viewModel.editedContent)
                .font(.system(size: contentSize))
                .foregroundColor(Color(.label))
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .scrollDisabled(true)
                .frame(minHeight: 60) // Minimum height to match the screenshot
                .fixedSize(horizontal: false, vertical: true) // Allow vertical expansion
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.accentColor, lineWidth: 2)
            )
            .focused($isComposeFieldFocused, equals: true)
            .onChange(of: viewModel.isEditFieldFocused) { _, shouldFocus in
                isComposeFieldFocused = shouldFocus
            }
            
            // Save/Cancel buttons below edit box, right-aligned
            HStack {
                Spacer()
                
                Button("Cancel") {
                    viewModel.cancelEditing()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.accentColor)
                
                Button("Save") {
                    Task {
                        await viewModel.saveEditedEntry()
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.accentColor)
                .disabled(viewModel.editedContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                         viewModel.editedContent == entry.content)
            }
            
            // Divider (except for last entry)
            if !isLast {
                Divider()
                    .padding(.top, 16)
            }
        }
        .padding(.bottom, isLast ? 0 : 24)
    }
    
    private var menuButton: some View {
        Menu {
            Button(action: {
                Task {
                    await viewModel.exportToCSV()
                }
            }) {
                Label("Export as CSV", systemImage: "square.and.arrow.up")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color(.label))
                .frame(width: 44, height: 44)
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
    
    private func updateTextEditorHeight() {
        // Simplified height calculation to prevent NaN errors and improve performance
        let baseHeight: CGFloat = 44
        let lineHeight: CGFloat = 22
        let maxHeight: CGFloat = 220
        
        // Guard against empty content
        guard !viewModel.draftContent.isEmpty else {
            textEditorHeight = baseHeight
            return
        }
        
        // Count newlines (much simpler approach)
        let newlineCount = viewModel.draftContent.filter { $0.isNewline }.count
        
        // Estimate total lines including wrapped text
        // Approximate: ~40 characters per line on iPhone
        let estimatedWrappedLines = viewModel.draftContent.count / 40
        let totalLines = max(1, newlineCount + estimatedWrappedLines)
        
        // Calculate new height with bounds checking
        let calculatedHeight = baseHeight + CGFloat(min(totalLines - 1, 9)) * lineHeight
        let newHeight = max(baseHeight, min(calculatedHeight, maxHeight))
        
        // Only animate if the height actually changes significantly (prevents micro-animations)
        if abs(textEditorHeight - newHeight) > 5 {
            withAnimation(.easeInOut(duration: 0.1)) {
                textEditorHeight = newHeight
            }
        } else {
            textEditorHeight = newHeight
        }
    }
    
    
    private var expandedComposeView: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Navigation bar
                    HStack {
                        Button("Cancel") {
                            isExpanded = false
                        }
                        .font(.system(size: 17))
                        .foregroundColor(Color(.label))
                        
                        Spacer()
                        
                        Text("Compose")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(Color(.label))
                        
                        Spacer()
                        
                        Button("Done") {
                            isExpanded = false
                        }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(Color(.systemBlue))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    
                    Divider()
                    
                    // Text editor
                    TextEditor(text: $viewModel.draftContent)
                        .font(.system(size: 17))
                        .foregroundColor(Color(.label))
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                    
                    // Send button at bottom
                    VStack {
                        Divider()
                        
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                Task {
                                    await viewModel.addEntry()
                                    isExpanded = false
                                }
                            }) {
                                Label("Send", systemImage: "arrow.up.circle.fill")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(
                                        Capsule()
                                            .fill(viewModel.canSendEntry ? Color(.systemBlue) : Color(.tertiaryLabel))
                                    )
                            }
                            .disabled(!viewModel.canSendEntry)
                            .opacity(viewModel.canSendEntry ? 1.0 : 0.5)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Color(.systemBackground))
                }
            }
        }
    }
}