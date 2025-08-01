//
//  CustomFieldsManagementView.swift
//  ThreadJournal2
//
//  View for managing custom fields in a thread
//

import SwiftUI

struct CustomFieldsManagementView: View {
    @ObservedObject var viewModel: CustomFieldsViewModel
    
    @State private var editMode: EditMode = .inactive
    @State private var showingAddField = false
    @State private var showingDeleteAlert = false
    @State private var fieldToDelete: CustomField?
    @State private var draggedField: CustomField?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if viewModel.fields.isEmpty && !viewModel.isLoading {
                emptyStateView
            } else {
                fieldListView
            }
        }
        .navigationTitle("Custom Fields")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
                    .disabled(viewModel.fields.isEmpty)
            }
            
            ToolbarItem(placement: .principal) {
                if !viewModel.fields.isEmpty {
                    Text("\(viewModel.fields.count) fields")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .environment(\.editMode, $editMode)
            .task {
                await viewModel.loadFields()
            }
            .alert("Delete Field?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    fieldToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let field = fieldToDelete {
                        Task {
                            await viewModel.deleteField(field)
                            fieldToDelete = nil
                        }
                    }
                }
            } message: {
                Text("Historical data will be preserved in existing entries.")
            }
            .alert("Error", isPresented: .constant(viewModel.error != nil)) {
                Button("OK") {
                    viewModel.error = nil
                }
            } message: {
                if let error = viewModel.error {
                    Text(error)
                }
            }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No custom fields yet")
                .font(.title3)
                .fontWeight(.medium)
            
            Text("Tap + to add your first field")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(alignment: .bottom) {
            addFieldButton
                .padding()
        }
    }
    
    private var fieldListView: some View {
        VStack(spacing: 0) {
            List {
                ForEach(viewModel.fields) { field in
                    fieldRow(for: field)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                        .onDrag {
                            self.draggedField = field
                            return NSItemProvider(object: field.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], delegate: FieldDropDelegate(
                            destinationField: field,
                            fields: viewModel.fields,
                            draggedField: $draggedField,
                            onReorder: { source, destination in
                                viewModel.moveFields(from: source, to: destination)
                            },
                            onCreateGroup: { parentId, childIds in
                                Task {
                                    await viewModel.createGroup(
                                        parentFieldId: parentId,
                                        childFieldIds: childIds
                                    )
                                }
                            }
                        ))
                }
                .onDelete { indexSet in
                    if let index = indexSet.first {
                        fieldToDelete = viewModel.fields[index]
                        showingDeleteAlert = true
                    }
                }
                .onMove { source, destination in
                    viewModel.moveFields(from: source, to: destination)
                }
                
                if showingAddField {
                    inlineAddFieldRow
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            
            if !showingAddField && viewModel.fields.count < 20 {
                addFieldButton
                    .padding()
            }
        }
    }
    
    private func fieldRow(for field: CustomField) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .accessibilityIdentifier("drag-handle-\(field.id)")
                .accessibilityLabel("Reorder \(field.name)")
            
            Text(field.name)
                .font(.body)
                .foregroundColor(.primary)
            
            if field.isGroup {
                Text("(group)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        .background(
            field.isGroup
                ? RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
                : nil
        )
    }
    
    private var inlineAddFieldRow: some View {
        HStack(spacing: 12) {
            TextField("Field name", text: $viewModel.newFieldName)
                .textFieldStyle(.plain)
                .font(.body)
                .submitLabel(.done)
                .onSubmit {
                    Task {
                        await viewModel.addField()
                        if viewModel.validationError == nil {
                            showingAddField = false
                        }
                    }
                }
                .onAppear {
                    // Focus the text field when it appears
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.becomeFirstResponder),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                    }
                }
            
            if !viewModel.newFieldName.isEmpty {
                Button("Cancel") {
                    viewModel.newFieldName = ""
                    viewModel.validationError = nil
                    showingAddField = false
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.accentColor, lineWidth: 2)
        )
        .overlay(alignment: .bottom) {
            if let error = viewModel.validationError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
                    .offset(y: 20)
            }
        }
    }
    
    private var addFieldButton: some View {
        Button(action: {
            showingAddField = true
            viewModel.newFieldName = ""
            viewModel.validationError = nil
        }) {
            HStack {
                Image(systemName: "plus")
                Text("Add Field")
            }
            .font(.body)
            .foregroundColor(.accentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
        }
        .disabled(viewModel.fields.count >= 20)
        .opacity(viewModel.fields.count >= 20 ? 0.5 : 1.0)
    }
}

// MARK: - Drop Delegate

struct FieldDropDelegate: DropDelegate {
    let destinationField: CustomField
    let fields: [CustomField]
    @Binding var draggedField: CustomField?
    let onReorder: (IndexSet, Int) -> Void
    let onCreateGroup: (UUID, [UUID]) -> Void
    
    func dropEntered(info: DropInfo) {
        guard let draggedField = draggedField,
              draggedField.id != destinationField.id else { return }
        
        // Visual feedback for potential group creation
        withAnimation(.easeInOut(duration: 0.2)) {
            // Update UI to show drop zone
        }
    }
    
    func dropExited(info: DropInfo) {
        // Remove visual feedback
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let draggedField = draggedField else { return false }
        
        // Determine if this is a reorder or group creation
        let draggedIndex = fields.firstIndex(where: { $0.id == draggedField.id })
        let destinationIndex = fields.firstIndex(where: { $0.id == destinationField.id })
        
        guard let fromIndex = draggedIndex,
              let toIndex = destinationIndex else { return false }
        
        // If dropping directly on a field (not between), create a group
        if !destinationField.isGroup && fromIndex != toIndex {
            // Convert destination field to group and add dragged field as child
            onCreateGroup(destinationField.id, [draggedField.id])
            return true
        }
        
        // Otherwise, just reorder
        onReorder(IndexSet(integer: fromIndex), toIndex > fromIndex ? toIndex + 1 : toIndex)
        return true
    }
}

// MARK: - Preview

#Preview {
    Text("CustomFieldsManagementView Preview")
}