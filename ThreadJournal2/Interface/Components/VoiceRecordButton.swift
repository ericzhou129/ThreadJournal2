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
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {}) {
            HStack(spacing: 8) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .scaleEffect(isPressed ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.15), value: isPressed)
                
                Text("Tap to speak")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                LinearGradient(
                    colors: [
                        Color.accentColor,
                        Color.accentColor.opacity(0.8)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: Color.accentColor.opacity(0.3), radius: isPressed ? 2 : 6, x: 0, y: isPressed ? 1 : 3)
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) {
            // On release
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = false
            }
            action()
        } onPressingChanged: { pressing in
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                isPressed = pressing
            }
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