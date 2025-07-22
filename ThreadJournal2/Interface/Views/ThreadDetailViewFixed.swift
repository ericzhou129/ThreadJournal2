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
    
    @ScaledMetric(relativeTo: .subheadline) private var timestampSize = 11
    @ScaledMetric(relativeTo: .body) private var contentSize = 14
    
    private let bottomID = "bottom"
    
    init(
        threadId: UUID,
        repository: ThreadRepository,
        addEntryUseCase: AddEntryUseCase,
        draftManager: DraftManager,
        exportThreadUseCase: ExportThreadUseCase
    ) {
        self.threadId = threadId
        let viewModel = ThreadDetailViewModel(
            repository: repository,
            addEntryUseCase: addEntryUseCase,
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
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if viewModel.entries.isEmpty && !viewModel.isLoading {
                            // Empty state
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
                        } else {
                            ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                                entryView(entry: entry, isLast: index == viewModel.entries.count - 1)
                            }
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
            
            // Compose area overlay at bottom
            VStack(spacing: 0) {
                Spacer()
                
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(alignment: .bottom, spacing: 12) {
                        // Text input field
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
                                .onChange(of: viewModel.draftContent) { _, _ in
                                    updateTextEditorHeight()
                                }
                                .onAppear {
                                    updateTextEditorHeight()
                                }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemGray6))
                        )
                        
                        // Expand button
                        Button(action: {
                            isExpanded = true
                        }) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(.label))
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color(.systemGray5)))
                        }
                            
                        // Send button
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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(.regularMaterial)
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
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .overlay(
                        ProgressView("Exporting...")
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                    )
            }
        }
    }
    
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
        // Simple height calculation without UIKit
        let baseHeight: CGFloat = 44
        let lineHeight: CGFloat = 22
        let maxLines = 10
        
        // Count approximate lines based on character count
        let charactersPerLine = 40
        let lineCount = max(1, (viewModel.draftContent.count / charactersPerLine) + 1)
        let calculatedLines = min(lineCount, maxLines)
        
        // Calculate height
        let newHeight = baseHeight + (CGFloat(calculatedLines - 1) * lineHeight)
        
        // Update height with animation
        withAnimation(.easeInOut(duration: 0.15)) {
            textEditorHeight = max(baseHeight, min(newHeight, 220))
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