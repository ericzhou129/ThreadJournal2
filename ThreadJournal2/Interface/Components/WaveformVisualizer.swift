//
//  WaveformVisualizer.swift
//  ThreadJournal2
//
//  Minimal waveform visualization component for voice recording
//

import SwiftUI
import UIKit

struct PressedButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct WaveformVisualizer: View {
    @State private var animationPhase = 0.0
    @State private var isVisible = false
    let onStopAndEdit: () -> Void
    let onStopAndSave: () -> Void
    let audioLevel: Float
    
    let barCount = 10
    let baseBars = [12, 20, 16, 24, 18, 22, 14, 20, 16, 18]
    
    init(audioLevel: Float = 0.0, onStopAndEdit: @escaping () -> Void, onStopAndSave: @escaping () -> Void) {
        self.audioLevel = audioLevel
        self.onStopAndEdit = onStopAndEdit
        self.onStopAndSave = onStopAndSave
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Waveform bars
            HStack(spacing: 2) {
                ForEach(0..<barCount, id: \.self) { index in
                    waveformBar(at: index)
                        .opacity(isVisible ? 1.0 : 0.0)
                        .scaleEffect(isVisible ? 1.0 : 0.5)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8)
                            .delay(Double(index) * 0.05),
                            value: isVisible
                        )
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
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                        .scaleEffect(1.0)
                }
                .buttonStyle(PressedButtonStyle())
                .opacity(isVisible ? 1.0 : 0.0)
                .scaleEffect(isVisible ? 1.0 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3), value: isVisible)
                
                // Stop & Save button (checkmark icon)
                Button(action: onStopAndSave) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(.white)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                        .scaleEffect(1.0)
                }
                .buttonStyle(PressedButtonStyle())
                .opacity(isVisible ? 1.0 : 0.0)
                .scaleEffect(isVisible ? 1.0 : 0.8)
                .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.35), value: isVisible)
            }
            .padding(.trailing, 8)
        }
        .frame(height: 44)
        .background(.black)
        .cornerRadius(12)
        .scaleEffect(isVisible ? 1.0 : 0.9)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
        .onAppear {
            withAnimation {
                isVisible = true
            }
            startAnimation()
        }
    }
    
    private func waveformBar(at index: Int) -> some View {
        let baseHeight = CGFloat(baseBars[index])
        let animatedHeight = baseHeight * animationMultiplier(for: index)
        
        return Rectangle()
            .fill(
                LinearGradient(
                    colors: [.white, .white.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 3, height: animatedHeight)
            .cornerRadius(1.5)
            .animation(
                .easeInOut(duration: 0.6 + Double.random(in: 0...0.4))
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.08),
                value: animationPhase
            )
    }
    
    private func animationMultiplier(for index: Int) -> CGFloat {
        let phase = animationPhase + Double(index) * 0.3
        let baseAnimation = 0.5 + 0.7 * abs(sin(phase))
        
        // Modulate animation with audio level (0.0 to 1.0)
        // Ensure audioLevel is valid and clamped to prevent NaN
        let safeAudioLevel = max(0.0, min(1.0, audioLevel.isNaN ? 0.0 : audioLevel))
        let levelMultiplier = 0.3 + (CGFloat(safeAudioLevel) * 0.7)
        return baseAnimation * levelMultiplier
    }
    
    private func startAnimation() {
        withAnimation(.linear(duration: 1.8).repeatForever(autoreverses: false)) {
            animationPhase = .pi * 2
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Recording state with high audio level
        WaveformVisualizer(
            audioLevel: 0.8,
            onStopAndEdit: {
                print("Stop & Edit tapped")
            },
            onStopAndSave: {
                print("Stop & Save tapped")
            }
        )
        .padding(.horizontal)
        
        // Different background for contrast with low audio level
        WaveformVisualizer(
            audioLevel: 0.2,
            onStopAndEdit: { },
            onStopAndSave: { }
        )
        .padding(.horizontal)
        .background(Color(UIColor.systemGroupedBackground))
    }
    .padding()
    .background(Color(UIColor.systemBackground))
}