//
//  FieldSelectorSheet.swift
//  ThreadJournal2
//
//  Sheet for selecting custom fields when composing an entry
//

import SwiftUI

struct FieldSelectorSheet: View {
    let threadId: UUID
    let repository: ThreadRepository
    @Binding var selectedFieldIds: Set<UUID>
    let onDismiss: () -> Void
    
    @StateObject private var viewModel: FieldSelectorViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(
        threadId: UUID,
        repository: ThreadRepository,
        selectedFieldIds: Binding<Set<UUID>>,
        onDismiss: @escaping () -> Void
    ) {
        self.threadId = threadId
        self.repository = repository
        self._selectedFieldIds = selectedFieldIds
        self.onDismiss = onDismiss
        
        let vm = FieldSelectorViewModel(
            threadId: threadId,
            threadRepository: repository
        )
        self._viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.selectableFields.isEmpty {
                    emptyStateView
                } else {
                    fieldListView
                }
            }
            .navigationTitle("Select Fields")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedFieldIds = viewModel.selectedFieldIds
                        onDismiss()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .task {
            await viewModel.loadFields()
            viewModel.restoreSelection(fieldIds: selectedFieldIds)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tag.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No fields available")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Add custom fields in thread settings")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var fieldListView: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(viewModel.selectableFields) { selectableField in
                    fieldRow(for: selectableField)
                    
                    if selectableField.field.isGroup && !selectableField.childFields.isEmpty {
                        ForEach(selectableField.childFields) { childField in
                            fieldRow(for: childField)
                                .padding(.leading, 32)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func fieldRow(for selectableField: SelectableField) -> some View {
        Button(action: {
            viewModel.toggleField(selectableField.id)
        }) {
            HStack {
                Image(systemName: selectableField.isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(selectableField.isSelected ? .accentColor : .secondary)
                
                Text(selectableField.field.name)
                    .font(.body)
                    .foregroundColor(.primary)
                
                if selectableField.field.isGroup {
                    Text("(group)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    Text("FieldSelectorSheet Preview")
}