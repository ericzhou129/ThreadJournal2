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
    @State private var showingFieldSelector = false
    @State private var selectedFieldIds: Set<UUID> = []
    @State private var availableFields: [CustomField] = []
    @State private var fieldValues: [UUID: String] = [:]
    
    // Voice recording states
    @State private var isRecording = false
    @State private var transcriptionPreview = ""
    @State private var partialTranscription = ""
    @State private var textSizePercentage: Int = 100
    @FocusState private var isComposeFieldFocused: Bool
    
    @ScaledMetric(relativeTo: .subheadline) private var timestampSize = 11
    @ScaledMetric(relativeTo: .body) private var baseContentSize = 14
    
    private let bottomID = "bottom"
    
    // Dependencies for custom fields
    private let repository: ThreadRepository
    private let createFieldUseCase: CreateCustomFieldUseCase
    private let createGroupUseCase: CreateFieldGroupUseCase
    private let deleteFieldUseCase: DeleteCustomFieldUseCase
    private let getSettingsUseCase: GetSettingsUseCase
    
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
        exportThreadUseCase: ExportThreadUseCase,
        createFieldUseCase: CreateCustomFieldUseCase,
        createGroupUseCase: CreateFieldGroupUseCase,
        deleteFieldUseCase: DeleteCustomFieldUseCase,
        getSettingsUseCase: GetSettingsUseCase
    ) {
        self.threadId = threadId
        self.repository = repository
        self.createFieldUseCase = createFieldUseCase
        self.createGroupUseCase = createGroupUseCase
        self.deleteFieldUseCase = deleteFieldUseCase
        self.getSettingsUseCase = getSettingsUseCase
        
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
            UnToldTheme.shared.background
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
                await loadAvailableFields()
                await loadSettings()
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
        .sheet(isPresented: $showingFieldSelector) {
            FieldSelectorSheet(
                threadId: threadId,
                repository: repository,
                selectedFieldIds: $selectedFieldIds,
                onDismiss: {
                    showingFieldSelector = false
                }
            )
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
                .foregroundColor(UnToldTheme.shared.tertiaryText)
            
            Text("No entries yet")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(UnToldTheme.shared.secondaryText)
            
            Text("Start journaling by typing below")
                .font(.system(size: 16))
                .foregroundColor(UnToldTheme.shared.tertiaryText)
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
                
                VStack(alignment: .leading, spacing: 8) {
                    // Show selected field inputs inline
                    if !selectedFieldIds.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(selectedFieldIds), id: \.self) { fieldId in
                                if let field = availableFields.first(where: { $0.id == fieldId }) {
                                    HStack {
                                        Text("\(field.name):")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        TextField(field.name, text: Binding(
                                            get: { fieldValues[fieldId] ?? "" },
                                            set: { fieldValues[fieldId] = $0 }
                                        ))
                                        .font(.system(size: 14))
                                        .textFieldStyle(.roundedBorder)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemGray6))
                        )
                    }
                    
                    if isRecording {
                        recordingUIView
                    } else {
                        HStack(alignment: .bottom, spacing: 12) {
                            composeTextField
                            if !availableFields.isEmpty {
                                customFieldsButton
                            }
                            expandButton
                            sendButton
                        }
                        
                        // Voice button below the text field
                        VoiceRecordButton {
                            startRecording()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(.regularMaterial)
        }
    }
    
    private var composeTextField: some View {
        TextField("Add to journal...", text: $viewModel.draftContent, axis: .vertical)
            .font(.system(size: 17))
            .foregroundColor(Color(.label))
            .focused($isComposeFieldFocused)
            .lineLimit(1...10) // Min 1 line, max 10 lines (200px / 20px per line)
            .textFieldStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
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
    
    private var customFieldsButton: some View {
        Button(action: {
            showingFieldSelector = true
        }) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(selectedFieldIds.isEmpty ? Color(.label) : Color.accentColor)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color(.systemGray5)))
                .overlay(
                    selectedFieldIds.isEmpty ? nil :
                    Text("\(selectedFieldIds.count)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 16, height: 16)
                        .background(Circle().fill(Color.accentColor))
                        .offset(x: 12, y: -12)
                )
        }
    }
    
    private var sendButton: some View {
        Button(action: {
            Task {
                // Convert field values to EntryFieldValue array
                let entryFieldValues = fieldValues.compactMap { (fieldId, value) -> EntryFieldValue? in
                    guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                        return nil // Skip empty values
                    }
                    return EntryFieldValue(fieldId: fieldId, value: value)
                }
                
                await viewModel.addEntry(fieldValues: entryFieldValues)
                // Clear field values and selection after sending
                fieldValues.removeAll()
                selectedFieldIds.removeAll()
                isComposeFieldFocused = true
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
                        .foregroundColor(UnToldTheme.shared.secondaryText)
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
                            .foregroundColor(UnToldTheme.shared.secondaryText)
                    }
                }
                
                // Content
                Text(entry.content)
                    .font(.system(size: baseContentSize * CGFloat(textSizePercentage) / 100))
                    .foregroundColor(Color(.label))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                
                // Field tags - displays custom field values as tags
                fieldTagsView(for: entry)
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
                    .foregroundColor(UnToldTheme.shared.secondaryText)
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
    }
    
    private func editModeView(entry: Entry, isLast: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Timestamp remains visible above edit box
            Text(formatTimestamp(entry.timestamp))
                .font(.system(size: timestampSize, weight: .medium))
                .foregroundColor(UnToldTheme.shared.secondaryText)
                .padding(.vertical, 2)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(timestampBackgroundColor)
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 1.5, x: 0, y: 1)
                )
            
            // Edit text field - no internal scrolling, expands to fit content
            TextField("", text: $viewModel.editedContent, axis: .vertical)
                .font(.system(size: baseContentSize * CGFloat(textSizePercentage) / 100))
                .foregroundColor(Color(.label))
                .textFieldStyle(.plain)
                .lineLimit(3...20) // Min 3 lines for editing, max 20 lines
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
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
            
        }
        .padding(.bottom, isLast ? 0 : 24)
    }
    
    private var menuButton: some View {
        Menu {
            if let threadId = viewModel.thread?.id {
                NavigationLink {
                    CustomFieldsManagementView(
                        viewModel: CustomFieldsViewModel(
                            threadId: threadId,
                            threadRepository: repository,
                            createFieldUseCase: createFieldUseCase,
                            createGroupUseCase: createGroupUseCase,
                            deleteFieldUseCase: deleteFieldUseCase
                        )
                    )
                } label: {
                    Label("Custom Fields", systemImage: "list.bullet.rectangle")
                }
            }
            
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
    
    
    
    private var expandedComposeView: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Navigation bar
                    HStack {
                        Button("Cancel") {
                            // Clear field values and selection
                            fieldValues.removeAll()
                            selectedFieldIds.removeAll()
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
                    
                    // Selected fields inputs (if any)
                    if !selectedFieldIds.isEmpty {
                        selectedFieldsInputView
                    }
                    
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
                                    // Convert field values to EntryFieldValue array
                                    let entryFieldValues = fieldValues.compactMap { (fieldId, value) -> EntryFieldValue? in
                                        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                                            return nil // Skip empty values
                                        }
                                        return EntryFieldValue(fieldId: fieldId, value: value)
                                    }
                                    
                                    await viewModel.addEntry(fieldValues: entryFieldValues)
                                    // Clear field values and selection after sending
                                    fieldValues.removeAll()
                                    selectedFieldIds.removeAll()
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

// MARK: - Helper Methods

extension ThreadDetailViewFixed {
    private func loadAvailableFields() async {
        do {
            availableFields = try await repository.fetchCustomFields(
                for: threadId,
                includeDeleted: false
            )
        } catch {
            print("Failed to load custom fields: \(error)")
        }
    }
    
    private func loadSettings() async {
        do {
            let settings = try await getSettingsUseCase.execute()
            await MainActor.run {
                textSizePercentage = settings.textSizePercentage
            }
        } catch {
            print("Failed to load settings: \(error)")
        }
    }
    
    private var selectedFieldsInputView: some View {
        let selectedFields = availableFields.filter { selectedFieldIds.contains($0.id) }
        let groupedFields = Dictionary(grouping: selectedFields) { field in
            field.isGroup ? field.id : nil
        }
        
        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Individual fields (not in groups)
                ForEach(groupedFields[nil] ?? []) { field in
                    fieldInputRow(for: field)
                }
                
                // Group fields
                ForEach(groupedFields.keys.compactMap { $0 }, id: \.self) { groupId in
                    if let groupField = selectedFields.first(where: { $0.id == groupId }) {
                        VStack(alignment: .leading, spacing: 8) {
                            // Group header
                            Text(groupField.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                                .padding(.top, 8)
                            
                            // Group fields
                            ForEach(groupedFields[groupId] ?? []) { field in
                                if field.id != groupId { // Don't show the group field itself as input
                                    fieldInputRow(for: field)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .frame(maxHeight: 200) // Limit height so text editor is still visible
    }
    
    private func fieldInputRow(for field: CustomField) -> some View {
        TextField(field.name, text: Binding(
            get: { fieldValues[field.id] ?? "" },
            set: { fieldValues[field.id] = $0 }
        ))
        .font(.system(size: 16))
        .foregroundColor(.primary)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(red: 0.976, green: 0.976, blue: 0.976)) // #f9f9f9
        )
    }
    
    private func fieldTagsView(for entry: Entry) -> some View {
        // Don't show anything if no field values
        guard !entry.customFieldValues.isEmpty else {
            return AnyView(EmptyView())
        }
        
        // Get field names for display
        let fieldNameMap = Dictionary(uniqueKeysWithValues: availableFields.map { ($0.id, $0) })
        
        // Group fields by their group (if any)
        let groupedFields = Dictionary(grouping: entry.customFieldValues) { fieldValue in
            let field = fieldNameMap[fieldValue.fieldId]
            return field?.isGroup == true ? fieldValue.fieldId : nil
        }
        
        return AnyView(
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], 
                     alignment: .leading, spacing: 8) {
                
                // Individual fields (not in groups)
                ForEach(groupedFields[nil] ?? [], id: \.fieldId) { fieldValue in
                    if let field = fieldNameMap[fieldValue.fieldId],
                       !fieldValue.value.isEmpty {
                        // Regular field tag - gray background
                        Text("\(field.name): \(fieldValue.value)")
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.949, green: 0.949, blue: 0.969)) // #f2f2f7
                            )
                    }
                }
                
                // Group fields
                ForEach(groupedFields.keys.compactMap { $0 }, id: \.self) { groupId in
                    if let groupField = fieldNameMap[groupId] {
                        // Group tag - blue background
                        Text(groupField.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(red: 0.102, green: 0.451, blue: 0.910)) // #1a73e8
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.910, green: 0.941, blue: 0.996)) // #e8f0fe
                            )
                        
                        // Group field values
                        ForEach(groupedFields[groupId] ?? [], id: \.fieldId) { fieldValue in
                            if let field = fieldNameMap[fieldValue.fieldId],
                               !fieldValue.value.isEmpty,
                               field.id != groupId { // Don't show the group field itself
                                Text("\(field.name): \(fieldValue.value)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color(red: 0.949, green: 0.949, blue: 0.969)) // #f2f2f7
                                    )
                            }
                        }
                    }
                }
            }
            .padding(.top, 8)
        )
    }
    
    // MARK: - Voice Recording Views
    
    private var recordingUIView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Live transcription preview
            VStack(alignment: .leading, spacing: 4) {
                Text("Live transcription")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if !transcriptionPreview.isEmpty {
                            Text(transcriptionPreview)
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if !partialTranscription.isEmpty {
                            Text(partialTranscription)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if transcriptionPreview.isEmpty && partialTranscription.isEmpty {
                            Text("Listening...")
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(minHeight: 60, maxHeight: 120)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
            
            // Waveform with stop buttons
            WaveformVisualizer(
                onStopAndEdit: {
                    stopRecordingAndEdit()
                },
                onStopAndSave: {
                    stopRecordingAndSave()
                }
            )
        }
    }
    
    // MARK: - Voice Recording Actions
    
    private func startRecording() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isRecording = true
            transcriptionPreview = ""
            partialTranscription = ""
        }
        
        // Mock transcription updates for demonstration
        startMockTranscription()
    }
    
    private func stopRecordingAndEdit() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isRecording = false
            
            // Fill the compose field with the transcribed text
            let fullTranscription = transcriptionPreview + partialTranscription
            if !fullTranscription.isEmpty {
                viewModel.draftContent = fullTranscription.trimmingCharacters(in: .whitespacesAndNewlines)
                isComposeFieldFocused = true
            }
            
            // Clear transcription
            transcriptionPreview = ""
            partialTranscription = ""
        }
    }
    
    private func stopRecordingAndSave() {
        let fullTranscription = transcriptionPreview + partialTranscription
        
        withAnimation(.easeInOut(duration: 0.3)) {
            isRecording = false
            transcriptionPreview = ""
            partialTranscription = ""
        }
        
        // Save directly as entry if there's content
        if !fullTranscription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Task {
                // Temporarily set draft content for the save operation
                let originalDraftContent = viewModel.draftContent
                viewModel.draftContent = fullTranscription.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Add the entry
                await viewModel.addEntry(fieldValues: [])
                
                // Restore original draft content (should be empty after successful save)
                if viewModel.draftContent.isEmpty {
                    viewModel.draftContent = originalDraftContent
                }
            }
        }
    }
    
    private func startMockTranscription() {
        // Mock progressive transcription for UI demonstration
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if isRecording {
                transcriptionPreview = "Had a really productive day today."
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if isRecording {
                transcriptionPreview += " Managed to implement the voice entry feature"
                partialTranscription = " and it's working better than expected..."
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.5) {
            if isRecording {
                transcriptionPreview += " and it's working better than expected"
                partialTranscription = ". The simplicity really makes a difference."
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
            if isRecording {
                transcriptionPreview += ". The simplicity really makes a difference"
                partialTranscription = " for the user experience."
            }
        }
    }
}