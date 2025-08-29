//
//  VoiceRecordButton.swift
//  ThreadJournal2
//
//  Voice recording button component with full-width design
//

import SwiftUI
import UIKit

struct VoiceRecordButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Tap to speak")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.accentColor)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                // Scale animation handled by SwiftUI button press
            }
            action()
        }
    }
}

#Preview {
    VStack {
        VoiceRecordButton {
            print("Voice recording started")
        }
        .padding()
        
        // Show different states
        VoiceRecordButton {
            // Empty action for preview
        }
        .padding()
        .disabled(true)
    }
    .background(Color(UIColor.systemGroupedBackground))
}