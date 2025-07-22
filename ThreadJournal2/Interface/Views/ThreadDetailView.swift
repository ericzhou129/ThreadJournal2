//
//  ThreadDetailView.swift
//  ThreadJournal2
//
//  Thread detail UI implementation according to Design:v1.2/Screen/ThreadDetail
//

import SwiftUI
import UIKit

struct ThreadDetailView: View {
    @StateObject private var viewModel: ThreadDetailViewModel
    @State private var showingExportMenu = false
    @FocusState private var isComposeFieldFocused: Bool
    @State private var keyboardHeight: CGFloat = 0
    @State private var isExpanded = false
    @State private var textEditorHeight: CGFloat = 44
    
    // Dynamic Type support
    @ScaledMetric(relativeTo: .title3) private var titleSize: CGFloat = 20
    @ScaledMetric(relativeTo: .caption) private var timestampSize: CGFloat = 11
    @ScaledMetric(relativeTo: .body) private var contentSize: CGFloat = 14
    
    // Scroll to bottom support
    @Namespace private var bottomID
    
    private let threadId: UUID
    
    init(threadId: UUID, repository: ThreadRepository, addEntryUseCase: AddEntryUseCase, draftManager: DraftManager) {
        self.threadId = threadId
        
        let viewModel = ThreadDetailViewModel(
            repository: repository,
            addEntryUseCase: addEntryUseCase,
            draftManager: draftManager
        )
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Main content
                if viewModel.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Entries list
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                                    entryView(entry: entry, isLast: index == viewModel.entries.count - 1)
                                }
                                
                                // Invisible anchor for scrolling to bottom
                                Color.clear
                                    .frame(height: 1)
                                    .id(bottomID)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 16)
                            .padding(.bottom, keyboardHeight > 0 ? keyboardHeight + 100 : 100) // Space for compose area + keyboard
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onAppear {
                            // Auto-scroll to latest entry when thread opened
                            if viewModel.shouldScrollToLatest {
                                withAnimation {
                                    proxy.scrollTo(bottomID, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: viewModel.entries.count) { _, _ in
                            // Scroll to bottom when new entry added
                            withAnimation {
                                proxy.scrollTo(bottomID, anchor: .bottom)
                            }
                        }
                        .onChange(of: viewModel.shouldScrollToLatest) { _, shouldScroll in
                            if shouldScroll {
                                withAnimation {
                                    proxy.scrollTo(bottomID, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: isComposeFieldFocused) { _, isFocused in
                            // When typing begins, scroll to show latest entry above keyboard
                            if isFocused {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation {
                                        proxy.scrollTo(bottomID, anchor: .bottom)
                                    }
                                }
                            }
                        }
                        .onChange(of: viewModel.draftContent) { _, _ in
                            // Auto-scroll to bottom when user is typing
                            if isComposeFieldFocused {
                                withAnimation {
                                    proxy.scrollTo(bottomID, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
            
            // Compose area pinned at bottom
            VStack(spacing: 0) {
                Spacer()
                composeArea
                    .background(Color(.systemBackground))
                    .padding(.bottom, keyboardHeight)
            }
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
            setupKeyboardObservers()
        }
        .confirmationDialog("Export Options", isPresented: $showingExportMenu, titleVisibility: .visible) {
            Button("Export as CSV") {
                // Will be implemented in TICKET-015
                print("Export as CSV selected")
            }
            Button("Cancel", role: .cancel) {}
        }
        .fullScreenCover(isPresented: $isExpanded) {
            expandedComposeView
        }
    }
    
    // MARK: - Subviews
    
    private func entryView(entry: Entry, isLast: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Timestamp
            Text(formatTimestamp(entry.timestamp))
                .font(.system(size: timestampSize, weight: .medium))
                .foregroundColor(Color(.secondaryLabel))
            
            // Content
            Text(entry.content)
                .font(.system(size: contentSize))
                .foregroundColor(Color(.label))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Divider (except for last entry)
            if !isLast {
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 0.5)
                    .padding(.top, 16)
            }
        }
        .padding(.bottom, isLast ? 0 : 24)
    }
    
    private var composeArea: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Separator
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 0.5)
                
                // Compose input area
                HStack(alignment: .bottom, spacing: 8) {
                    // Text input
                    ZStack(alignment: .topLeading) {
                        if viewModel.draftContent.isEmpty {
                            Text("Add to journal...")
                                .font(.system(size: 17))
                                .foregroundColor(Color(.tertiaryLabel))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .allowsHitTesting(false)
                        }
                        
                        TextEditor(text: $viewModel.draftContent)
                            .font(.system(size: 17))
                            .foregroundColor(Color(.label))
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .focused($isComposeFieldFocused)
                            .frame(minHeight: 44, maxHeight: min(textEditorHeight, geometry.size.height * 0.5))
                            .onChange(of: viewModel.draftContent) { _, _ in
                                updateTextEditorHeight()
                            }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )
                    
                    // Expand button
                    Button(action: {
                        isExpanded = true
                    }) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(.label))
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(Color(.tertiarySystemGroupedBackground))
                            )
                    }
                    
                    // Send button
                    Button(action: {
                        Task {
                            await viewModel.addEntry()
                            // Entry field will be cleared automatically by viewModel
                            // Focus remains on the field for continuous entry
                            isComposeFieldFocused = true
                            // Reset text editor height after sending
                            textEditorHeight = 44
                        }
                    }) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(viewModel.canSendEntry ? Color(.label) : Color(.tertiaryLabel))
                            )
                    }
                    .disabled(!viewModel.canSendEntry)
                    .opacity(viewModel.canSendEntry ? 1.0 : 0.5)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .frame(height: calculateComposeAreaHeight(geometry: geometry))
        }
        .overlay(
            // Draft state indicator
            Group {
                if viewModel.isSavingDraft || viewModel.hasFailedSave {
                    HStack {
                        if viewModel.isSavingDraft {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text(viewModel.draftStateDescription)
                                .font(.system(size: 12))
                                .foregroundColor(Color(.secondaryLabel))
                        } else if viewModel.hasFailedSave {
                            Text(viewModel.draftStateDescription)
                                .font(.system(size: 12))
                                .foregroundColor(.red)
                            
                            Button("Retry") {
                                Task {
                                    await viewModel.retrySave()
                                }
                            }
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(.systemBlue))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                }
            },
            alignment: .bottom
        )
    }
    
    private var menuButton: some View {
        Menu {
            Button(action: {
                showingExportMenu = true
            }) {
                Label("Export as CSV", systemImage: "square.and.arrow.up")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(Color(.label))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
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
                    
                    // Expanded text editor
                    TextEditor(text: $viewModel.draftContent)
                        .font(.system(size: 17))
                        .foregroundColor(Color(.label))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    
                    // Bottom bar with send button
                    VStack(spacing: 0) {
                        Divider()
                        
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                Task {
                                    await viewModel.addEntry()
                                    isExpanded = false
                                    textEditorHeight = 44
                                }
                            }) {
                                HStack(spacing: 8) {
                                    Text("Send")
                                        .font(.system(size: 17, weight: .semibold))
                                    Image(systemName: "arrow.up")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(viewModel.canSendEntry ? Color(.label) : Color(.tertiaryLabel))
                                )
                            }
                            .disabled(!viewModel.canSendEntry)
                            .opacity(viewModel.canSendEntry ? 1.0 : 0.5)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .background(Color(.secondarySystemBackground))
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
        return formatter.string(from: date)
    }
    
    private func calculateComposeAreaHeight(geometry: GeometryProxy) -> CGFloat {
        // Fixed height to prevent overlap with content
        return 90
    }
    
    private func updateTextEditorHeight() {
        // Calculate the required height based on text content
        let font = UIFont.systemFont(ofSize: 17)
        let width = UIScreen.main.bounds.width - 100 // Approximate width accounting for padding
        
        let textStorage = NSTextStorage(string: viewModel.draftContent)
        let textContainer = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
        let layoutManager = NSLayoutManager()
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textStorage.addAttribute(.font, value: font, range: NSRange(location: 0, length: textStorage.length))
        
        textContainer.lineFragmentPadding = 0
        layoutManager.ensureLayout(for: textContainer)
        
        let usedRect = layoutManager.usedRect(for: textContainer)
        let calculatedHeight = usedRect.height + 20 // Add padding
        
        // Update height with minimum and maximum constraints
        withAnimation(.easeInOut(duration: 0.2)) {
            textEditorHeight = max(44, min(calculatedHeight, UIScreen.main.bounds.height * 0.5))
        }
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                withAnimation(.easeOut(duration: 0.25)) {
                    keyboardHeight = keyboardFrame.height
                }
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            withAnimation(.easeOut(duration: 0.25)) {
                keyboardHeight = 0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        let persistenceController = PersistenceController.preview
        let repository = persistenceController.makeThreadRepository()
        let addEntryUseCase = AddEntryUseCase(repository: repository)
        let draftManager = InMemoryDraftManager()
        
        // Create sample thread
        let sampleThread = try! Thread(
            id: UUID(),
            title: "My First Thread",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        ThreadDetailView(
            threadId: sampleThread.id,
            repository: repository,
            addEntryUseCase: addEntryUseCase,
            draftManager: draftManager
        )
    }
}