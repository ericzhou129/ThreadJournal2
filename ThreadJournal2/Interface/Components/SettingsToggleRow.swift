//
//  SettingsToggleRow.swift
//  ThreadJournal2
//
//  Created by Claude on 2025-08-06.
//

import SwiftUI

/// A reusable settings row component with a toggle switch.
/// Provides standard iOS settings appearance with consistent spacing and typography.
struct SettingsToggleRow: View {
    
    // MARK: - Properties
    
    let title: String
    @Binding var isOn: Bool
    let action: () async -> Void
    
    // MARK: - Initialization
    
    /// Creates a settings toggle row.
    /// - Parameters:
    ///   - title: The title text for the setting
    ///   - isOn: Binding to the toggle state
    ///   - action: Async action to perform when toggle changes
    init(title: String, isOn: Binding<Bool>, action: @escaping () async -> Void) {
        self.title = title
        self._isOn = isOn
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(Color(.label))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .onChange(of: isOn) { _ in
                    Task {
                        await action()
                    }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(Color(.systemBackground))
    }
}