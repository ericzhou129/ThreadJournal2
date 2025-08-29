//
//  WaveformVisualizer.swift
//  ThreadJournal2
//
//  Minimal waveform visualization component for voice recording
//

import SwiftUI
import UIKit

struct WaveformVisualizer: View {
    @State private var animationPhase = 0.0
    let onStopAndEdit: () -> Void
    let onStopAndSave: () -> Void
    
    let barCount = 10
    let baseBars = [12, 20, 16, 24, 18, 22, 14, 20, 16, 18]
    
    var body: some View {
        HStack(spacing: 0) {
            // Waveform bars
            HStack(spacing: 2) {
                ForEach(0..<barCount, id: \.self) { index in
                    waveformBar(at: index)
                }
            }
            .frame(maxWidth: .infinity)
            
            // Stop buttons
            HStack(spacing: 4) {
                // Stop & Edit button (pencil icon)
                Button(action: onStopAndEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.white)
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Stop & Save button (checkmark icon)
                Button(action: onStopAndSave) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.white)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.trailing, 8)
        }
        .frame(height: 44)
        .background(.black)
        .cornerRadius(12)
        .onAppear {
            startAnimation()
        }
    }
    
    private func waveformBar(at index: Int) -> some View {
        let baseHeight = CGFloat(baseBars[index])
        let animatedHeight = baseHeight * animationMultiplier(for: index)
        
        return Rectangle()
            .fill(.white)
            .frame(width: 3, height: animatedHeight)
            .cornerRadius(1.5)
            .animation(
                .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.1),
                value: animationPhase
            )
    }
    
    private func animationMultiplier(for index: Int) -> CGFloat {
        let phase = animationPhase + Double(index) * 0.3
        return 0.5 + 0.7 * abs(sin(phase))
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Recording state
        WaveformVisualizer(
            onStopAndEdit: {
                print("Stop & Edit tapped")
            },
            onStopAndSave: {
                print("Stop & Save tapped")
            }
        )
        .padding(.horizontal)
        
        // Different background for contrast
        WaveformVisualizer(
            onStopAndEdit: { },
            onStopAndSave: { }
        )
        .padding(.horizontal)
        .background(Color(UIColor.systemGroupedBackground))
    }
    .padding()
    .background(Color(UIColor.systemBackground))
}