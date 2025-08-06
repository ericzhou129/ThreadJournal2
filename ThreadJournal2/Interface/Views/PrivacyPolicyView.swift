//
//  PrivacyPolicyView.swift
//  ThreadJournal2
//
//  Created by Claude on 2025-08-06.
//

import SwiftUI

/// Privacy Policy view displaying ThreadJournal's privacy practices and data handling.
/// Emphasizes local-only storage and strict biometric authentication requirements.
struct PrivacyPolicyView: View {
    
    // MARK: - Properties
    
    let onDismiss: () -> Void
    
    // MARK: - Initialization
    
    /// Creates a PrivacyPolicyView with a dismiss handler.
    /// - Parameter onDismiss: Action to perform when the view should be dismissed
    init(onDismiss: @escaping () -> Void) {
        self.onDismiss = onDismiss
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    privacyPolicyContent
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        onDismiss()
                    }
                    .font(.system(size: 17, weight: .medium))
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Content
    
    private var privacyPolicyContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            
            Text("Privacy Policy")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Last updated: January 1, 2025")
                .font(.caption)
                .foregroundColor(Color(.secondaryLabel))
            
            privacySection(
                title: "1. Information We Collect",
                content: """
                ThreadJournal is designed with privacy in mind. We collect minimal information necessary to provide our service:
                
                • Journal entries and threads you create
                • App settings and preferences
                • Anonymous usage analytics (if enabled)
                """
            )
            
            privacySection(
                title: "2. Data Storage",
                content: """
                Your journal data is stored locally on your device. We do not have access to your journal content. All data remains private on your device and is never transmitted to our servers or any third parties.
                """
            )
            
            privacySection(
                title: "3. Data Security",
                content: """
                We implement comprehensive security measures including:
                
                • Mandatory biometric authentication (Face ID/Touch ID) on every app launch
                • No grace period - authentication required immediately when app returns from background
                • Encrypted data storage using iOS security frameworks
                • No third-party data sharing or analytics tracking
                • Complete offline operation with no network requirements
                """
            )
            
            privacySection(
                title: "4. Biometric Authentication",
                content: """
                When biometric authentication is enabled, ThreadJournal requires Face ID or Touch ID verification every time you:
                
                • Open the app
                • Return from the background
                • Switch between apps
                
                This strict authentication policy ensures maximum privacy protection for your personal journal entries. Your biometric data is processed entirely by iOS and never stored by ThreadJournal.
                """
            )
            
            privacySection(
                title: "5. Data Sharing",
                content: """
                ThreadJournal does not share your personal data with anyone. Your journal entries, settings, and usage patterns remain completely private to you and are stored exclusively on your device.
                """
            )
            
            privacySection(
                title: "6. Contact Us",
                content: """
                If you have questions about this privacy policy or our privacy practices, please contact us at:
                
                support@threadjournal.app
                """
            )
            
            // Additional privacy emphasis
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    Text("🔐")
                        .font(.system(size: 20))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Privacy is Our Priority")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("ThreadJournal is built with privacy-first design. Your personal thoughts and memories stay on your device, protected by the strongest security iOS offers.")
                            .font(.subheadline)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
                .padding(16)
                .background(Color(.systemBlue).opacity(0.1))
                .cornerRadius(12)
            }
            .padding(.top, 20)
        }
    }
    
    // MARK: - Helper Methods
    
    private func privacySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(content)
                .font(.body)
                .foregroundColor(Color(.label))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Preview

struct PrivacyPolicyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyPolicyView {
            // Mock dismiss action
        }
        .preferredColorScheme(.light)
        
        PrivacyPolicyView {
            // Mock dismiss action
        }
        .preferredColorScheme(.dark)
    }
}