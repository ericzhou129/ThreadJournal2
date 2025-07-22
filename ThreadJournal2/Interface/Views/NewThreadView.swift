//
//  NewThreadView.swift
//  ThreadJournal2
//
//  New thread creation UI according to Design:v1.2/Screen/NewThread
//

import SwiftUI

struct NewThreadView: View {
    @StateObject private var viewModel: CreateThreadViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    // Dynamic Type support
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var bodySize: CGFloat = 17
    
    // Navigation callback
    private let onThreadCreated: (Thread) -> Void
    
    private enum Field: Hashable {
        case title
        case firstEntry
    }
    
    init(viewModel: CreateThreadViewModel, onThreadCreated: @escaping (Thread) -> Void) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.onThreadCreated = onThreadCreated
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with X button
                    headerView
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Thread title input
                            threadTitleInput
                            
                            // Optional first entry
                            firstEntrySection
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .padding(.bottom, 100)
                    }
                    
                    // Create button at bottom
                    createButtonSection
                }
            }
            .alert("Error", isPresented: .constant(viewModel.hasError)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .onChange(of: viewModel.createdThread) { _, newThread in
                if let thread = newThread {
                    // Dismiss and navigate to thread detail
                    dismiss()
                    onThreadCreated(thread)
                }
            }
            .onAppear {
                // Focus on title field when view appears
                focusedField = .title
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerView: some View {
        HStack {
            // X button to cancel
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(Color(.label))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            
            Spacer()
            
            Text("New Thread")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(.label))
            
            Spacer()
            
            // Placeholder for symmetry
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5),
            alignment: .bottom
        )
    }
    
    private var threadTitleInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Name your thread...", text: $viewModel.threadTitle)
                .font(.system(size: titleSize, weight: .bold, design: .default))
                .foregroundColor(Color(.label))
                .focused($focusedField, equals: .title)
                .onChange(of: viewModel.threadTitle) { _, _ in
                    viewModel.onTitleChange()
                }
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .firstEntry
                }
            
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 1)
        }
    }
    
    private var firstEntrySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("First Entry (Optional)")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(.secondaryLabel))
            
            ZStack(alignment: .topLeading) {
                if viewModel.firstEntryContent.isEmpty {
                    Text("Start writing your first entry...")
                        .font(.system(size: bodySize))
                        .foregroundColor(Color(.tertiaryLabel))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }
                
                TextEditor(text: $viewModel.firstEntryContent)
                    .font(.system(size: bodySize))
                    .foregroundColor(Color(.label))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .focused($focusedField, equals: .firstEntry)
                    .onChange(of: viewModel.firstEntryContent) { _, _ in
                        viewModel.onFirstEntryChange()
                    }
                    .frame(minHeight: 120)
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
    }
    
    private var createButtonSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 0.5)
            
            HStack {
                Spacer()
                
                Button(action: {
                    Task {
                        await viewModel.createThread()
                    }
                }) {
                    HStack(spacing: 8) {
                        if viewModel.isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Text("Create")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(width: 100, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(viewModel.isCreateButtonEnabled ? Color(.label) : Color(.tertiaryLabel))
                    )
                }
                .disabled(!viewModel.isCreateButtonEnabled)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - Preview

#Preview {
    let persistenceController = PersistenceController.preview
    let repository = persistenceController.makeThreadRepository()
    let createThreadUseCase = CreateThreadUseCase(repository: repository)
    let draftManager = InMemoryDraftManager()
    let viewModel = CreateThreadViewModel(
        createThreadUseCase: createThreadUseCase,
        draftManager: draftManager
    )
    
    return NewThreadView(viewModel: viewModel) { thread in
        print("Created thread: \(thread.title)")
    }
}