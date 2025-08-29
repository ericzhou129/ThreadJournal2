//
//  UnToldTheme.swift
//  ThreadJournal2
//
//  Color theme based on UnTold app design
//

import SwiftUI

struct UnToldTheme {
    
    static let shared = UnToldTheme()
    
    private init() {}
    
    // MARK: - Primary Colors
    
    var background: Color {
        Color(red: 0.96, green: 0.94, blue: 0.91) // Warm beige/cream #F5F0E8
    }
    
    var secondaryBackground: Color {
        Color(red: 0.94, green: 0.92, blue: 0.88) // Slightly darker beige
    }
    
    var cardBackground: Color {
        Color.white.opacity(0.95)
    }
    
    // MARK: - Text Colors
    
    var primaryText: Color {
        Color(red: 0.2, green: 0.18, blue: 0.16) // Dark brown/charcoal
    }
    
    var secondaryText: Color {
        Color(red: 0.5, green: 0.45, blue: 0.4) // Medium brown/gray
    }
    
    var tertiaryText: Color {
        Color(red: 0.6, green: 0.55, blue: 0.5) // Light brown/gray
    }
    
    // MARK: - Accent Colors
    
    var accentBlue: Color {
        Color(red: 0.27, green: 0.47, blue: 0.63) // Soft blue #4578A0
    }
    
    var emotionTagBackground: Color {
        Color(red: 0.75, green: 0.68, blue: 0.58) // Warm tan/brown #BFAD94
    }
    
    var emotionTagText: Color {
        Color(red: 0.5, green: 0.42, blue: 0.32) // Darker brown
    }
    
    // MARK: - Interactive Elements
    
    var buttonBackground: Color {
        accentBlue
    }
    
    var buttonText: Color {
        Color.white
    }
    
    var linkColor: Color {
        accentBlue
    }
    
    // MARK: - Semantic Colors
    
    var separator: Color {
        Color(red: 0.85, green: 0.82, blue: 0.78).opacity(0.5)
    }
    
    var placeholder: Color {
        tertiaryText
    }
    
    // MARK: - Dark Mode Support
    
    func color(for colorScheme: ColorScheme) -> UnToldTheme {
        // For now, return the same colors for both modes
        // Can be expanded later for proper dark mode support
        return self
    }
}

// MARK: - View Extension for Easy Access

extension View {
    var theme: UnToldTheme {
        UnToldTheme.shared
    }
}