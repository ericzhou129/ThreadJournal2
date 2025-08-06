//
//  SettingsLinkRow.swift
//  ThreadJournal2
//
//  Created by Claude on 2025-08-06.
//

import SwiftUI

/// A reusable settings row component that acts as a navigation link or button.
/// Provides standard iOS settings appearance with optional detail text and chevron.
struct SettingsLinkRow: View {
    
    // MARK: - Properties
    
    let title: String
    let detail: String?
    let action: () -> Void
    
    // MARK: - Initialization
    
    /// Creates a settings link row.
    /// - Parameters:
    ///   - title: The main title text for the row
    ///   - detail: Optional detail text shown on the right side
    ///   - action: Action to perform when the row is tapped
    init(title: String, detail: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.detail = detail
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 17))
                    .foregroundColor(Color(.label))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if let detail = detail, !detail.isEmpty {
                    Text(detail)
                        .font(.system(size: 17))
                        .foregroundColor(Color(.secondaryLabel))
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(Color(.systemBackground))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

/// A specialized settings link row for displaying static information.
/// Shows title, detail, and no chevron - not interactive.
struct SettingsInfoRow: View {
    
    // MARK: - Properties
    
    let title: String
    let detail: String
    
    // MARK: - Initialization
    
    /// Creates a settings info row.
    /// - Parameters:
    ///   - title: The title text for the row
    ///   - detail: The detail text shown on the right side
    init(title: String, detail: String) {
        self.title = title
        self.detail = detail
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(Color(.label))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(detail)
                .font(.system(size: 17))
                .foregroundColor(Color(.secondaryLabel))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(Color(.systemBackground))
    }
}