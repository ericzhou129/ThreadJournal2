//
//  SettingsStepperRow.swift
//  ThreadJournal2
//
//  Created by Claude on 2025-08-06.
//

import SwiftUI

/// A reusable settings row component with a stepper for numeric values.
/// Provides standard iOS settings appearance with custom stepper controls.
struct SettingsStepperRow: View {
    
    // MARK: - Properties
    
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let format: String
    let onChange: (Int) async -> Void
    
    // MARK: - Initialization
    
    /// Creates a settings stepper row.
    /// - Parameters:
    ///   - title: The title text for the setting
    ///   - value: Binding to the numeric value
    ///   - range: The allowed range for the value
    ///   - step: The increment/decrement step size
    ///   - format: String format for displaying the value (e.g., "%d%%")
    ///   - onChange: Async action to perform when value changes
    init(
        title: String,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        step: Int,
        format: String,
        onChange: @escaping (Int) async -> Void
    ) {
        self.title = title
        self._value = value
        self.range = range
        self.step = step
        self.format = format
        self.onChange = onChange
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17))
                .foregroundColor(Color(.label))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                Button(action: decrementValue) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(value > range.lowerBound ? Color.accentColor : Color(.quaternaryLabel))
                }
                .disabled(value <= range.lowerBound)
                
                Text(String(format: format, value))
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(Color(.label))
                    .frame(minWidth: 50)
                
                Button(action: incrementValue) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(value < range.upperBound ? Color.accentColor : Color(.quaternaryLabel))
                }
                .disabled(value >= range.upperBound)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 11)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Private Methods
    
    private func incrementValue() {
        let newValue = min(value + step, range.upperBound)
        if newValue != value {
            value = newValue
            Task {
                await onChange(newValue)
            }
        }
    }
    
    private func decrementValue() {
        let newValue = max(value - step, range.lowerBound)
        if newValue != value {
            value = newValue
            Task {
                await onChange(newValue)
            }
        }
    }
}