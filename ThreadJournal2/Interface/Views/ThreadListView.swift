//
//  ThreadListView.swift
//  ThreadJournal2
//
//  Thread list UI implementation according to Design:v1.2/Screen/ThreadList
//

import SwiftUI
import UIKit

struct ThreadListView: View {
    @StateObject private var viewModel: ThreadListViewModel
    @State private var showingNewThreadSheet = false
    @State private var navigationPath = NavigationPath()
    
    // Dynamic Type support
    @ScaledMetric(relativeTo: .callout) private var titleSize: CGFloat = 16
    @ScaledMetric(relativeTo: .caption) private var metaSize: CGFloat = 12
    
    init(viewModel: ThreadListViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                // Background color
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Main content
                if viewModel.threadsWithMetadata.isEmpty && viewModel.loadingState == .loaded {
                    emptyStateView
                } else {
                    threadListContent
                }
                
                // Floating action button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingActionButton
                            .padding(.trailing, 24)
                            .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Threads")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            viewModel.loadThreads()
        }
        .sheet(isPresented: $showingNewThreadSheet) {
            let draftManager = InMemoryDraftManager()
            let createThreadUseCase = CreateThreadUseCase(repository: viewModel.repository)
            let createViewModel = CreateThreadViewModel(
                createThreadUseCase: createThreadUseCase,
                draftManager: draftManager
            )
            
            NewThreadView(viewModel: createViewModel) { createdThread in
                // Navigate to the created thread
                navigationPath.append(createdThread)
                // Reload threads to show the new one
                viewModel.loadThreads()
            }
        }
        .alert("Delete Thread", isPresented: $viewModel.showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                viewModel.cancelDelete()
            }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteThread()
                    // Haptic feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                }
            }
        } message: {
            if let thread = viewModel.threadToDelete {
                let entryCount = viewModel.threadsWithMetadata
                    .first(where: { $0.thread.id == thread.id })?.entryCount ?? 0
                Text("Delete '\(thread.title)'? This thread contains \(entryCount) \(entryCount == 1 ? "entry" : "entries").")
            }
        }
    }
    
    // MARK: - Subviews
    
    private var threadListContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.threadsWithMetadata) { threadWithMeta in
                    NavigationLink(value: threadWithMeta.thread) {
                        threadCard(for: threadWithMeta)
                    }
                    .buttonStyle(ThreadCardButtonStyle())
                }
            }
            .animation(.default, value: viewModel.threadsWithMetadata)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 100) // Space for FAB
        }
        .navigationDestination(for: Thread.self) { thread in
            let draftManager = InMemoryDraftManager()
            let addEntryUseCase = AddEntryUseCase(repository: viewModel.repository)
            let updateEntryUseCase = UpdateEntryUseCase(repository: viewModel.repository)
            let deleteEntryUseCase = DeleteEntryUseCase(repository: viewModel.repository)
            let csvExporter = CSVExporter()
            let exportThreadUseCase = ExportThreadUseCase(
                repository: viewModel.repository,
                exporter: csvExporter
            )
            
            ThreadDetailViewFixed(
                threadId: thread.id,
                repository: viewModel.repository,
                addEntryUseCase: addEntryUseCase,
                updateEntryUseCase: updateEntryUseCase,
                deleteEntryUseCase: deleteEntryUseCase,
                draftManager: draftManager,
                exportThreadUseCase: exportThreadUseCase
            )
        }
    }
    
    private func threadCard(for threadWithMeta: ThreadWithMetadata) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                // Thread title
                Text(threadWithMeta.thread.title)
                    .font(.system(size: titleSize, weight: .semibold, design: .default))
                    .foregroundColor(Color(.label))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Metadata
                HStack(spacing: 8) {
                    let count = threadWithMeta.entryCount
                    Text("\(count) \(count == 1 ? "entry" : "entries")")
                    
                    Text("•")
                        .foregroundColor(Color(.tertiaryLabel))
                    
                    Text(formatLastUpdated(threadWithMeta.thread.updatedAt))
                }
                .font(.system(size: metaSize, weight: .regular, design: .default))
                .foregroundColor(Color(.secondaryLabel))
            }
            
            // Ellipsis menu button
            Menu {
                Button(role: .destructive) {
                    viewModel.confirmDeleteThread(threadWithMeta.thread)
                } label: {
                    Label("Delete Thread", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(Color(.secondaryLabel))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .menuStyle(.automatic)
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Text("No threads yet")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(.label))
            
            Text("Tap + to create your first thread.")
                .font(.system(size: 16))
                .foregroundColor(Color(.secondaryLabel))
            
            Spacer()
        }
        .padding(.horizontal, 48)
    }
    
    private var floatingActionButton: some View {
        Button(action: {
            showingNewThreadSheet = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color(.label))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.15), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Helper Functions
    
    private func formatLastUpdated(_ date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)
        
        if let days = components.day, days > 0 {
            return "Updated \(days) \(days == 1 ? "day" : "days") ago"
        } else if let hours = components.hour, hours > 0 {
            return "Updated \(hours) \(hours == 1 ? "hour" : "hours") ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "Updated \(minutes) \(minutes == 1 ? "minute" : "minutes") ago"
        } else {
            return "Updated just now"
        }
    }
}

// MARK: - Button Style

struct ThreadCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    let persistenceController = PersistenceController.preview
    let repository = persistenceController.makeThreadRepository()
    let createThreadUseCase = CreateThreadUseCase(repository: repository)
    let deleteThreadUseCase = DeleteThreadUseCaseImpl(repository: repository)
    let viewModel = ThreadListViewModel(
        repository: repository,
        createThreadUseCase: createThreadUseCase,
        deleteThreadUseCase: deleteThreadUseCase
    )
    
    ThreadListView(viewModel: viewModel)
}