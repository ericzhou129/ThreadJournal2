//
//  SettingsScreen.swift
//  ThreadJournal2
//
//  Created by Claude on 2025-08-06.
//

import SwiftUI

/// Settings screen for configuring app preferences and viewing information.
/// Provides privacy-focused biometric authentication settings, display preferences,
/// and essential app information following iOS design standards.
struct SettingsScreen: View {
    
    // MARK: - Properties
    
    @StateObject private var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Initialization
    
    /// Creates a SettingsScreen with the specified ViewModel.
    /// - Parameter viewModel: The SettingsViewModel to manage state and operations
    init(viewModel: SettingsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 35) {
                    
                    // Security Section
                    settingsSection(title: "SECURITY") {
                        VStack(spacing: 0) {
                            SettingsToggleRow(
                                title: "Require Face ID",
                                isOn: .constant(viewModel.biometricAuthEnabled)
                            ) {
                                await viewModel.toggleBiometric()
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                    }
                    
                    securityFooter
                    
                    // Display Section
                    settingsSection(title: "DISPLAY") {
                        VStack(spacing: 0) {
                            SettingsStepperRow(
                                title: "Text Size",
                                value: $viewModel.textSizePercentage,
                                range: UserSettings.minimumTextSize...UserSettings.maximumTextSize,
                                step: UserSettings.textSizeIncrement,
                                format: "%d%%"
                            ) { newValue in
                                await viewModel.updateTextSize(newValue)
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Adjust the text size for journal entries. This setting is independent of system Dynamic Type.")
                            .font(.footnote)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    
                    // About Section
                    settingsSection(title: "ABOUT") {
                        VStack(spacing: 0) {
                            SettingsLinkRow(title: "Privacy Policy") {
                                viewModel.showPrivacyPolicy()
                            }
                            
                            Divider()
                                .padding(.leading, 16)
                            
                            SettingsInfoRow(
                                title: "Support",
                                detail: "support@threadjournal.app"
                            )
                            
                            Divider()
                                .padding(.leading, 16)
                            
                            SettingsInfoRow(
                                title: "Version",
                                detail: appVersionString
                            )
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                    }
                    
                    // App Info Footer
                    VStack(spacing: 4) {
                        Text("ThreadJournal 2.0")
                            .font(.footnote)
                            .foregroundColor(Color(.secondaryLabel))
                        
                        Text("© 2025 ThreadJournal")
                            .font(.footnote)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal, 16)
                .padding(.top, 35)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: 17, weight: .medium))
                }
            }
            .sheet(isPresented: $viewModel.showingPrivacyPolicy) {
                PrivacyPolicyView {
                    viewModel.hidePrivacyPolicy()
                }
            }
            .alert("Settings Error", isPresented: .constant(!viewModel.errorMessage.isEmpty)) {
                Button("OK") {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Private Views
    
    private func settingsSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote)
                .foregroundColor(Color(.secondaryLabel))
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 16)
            
            content()
        }
    }
    
    private var securityFooter: some View {
        Text("When enabled, Face ID or Touch ID will be required every time you open ThreadJournal.")
            .font(.footnote)
            .foregroundColor(Color(.secondaryLabel))
            .padding(.horizontal, 16)
    }
    
    // MARK: - Computed Properties
    
    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}

// MARK: - Preview

struct SettingsScreen_Previews: PreviewProvider {
    static var previews: some View {
        // Create mock dependencies for preview
        let mockRepository = MockSettingsRepository()
        let mockGetSettingsUseCase = MockGetSettingsUseCase()
        let mockUpdateSettingsUseCase = MockUpdateSettingsUseCase()
        let mockBiometricAuthService = BiometricAuthService(settingsRepository: mockRepository)
        
        let viewModel = SettingsViewModel(
            getSettingsUseCase: mockGetSettingsUseCase,
            updateSettingsUseCase: mockUpdateSettingsUseCase,
            biometricAuthService: mockBiometricAuthService
        )
        
        SettingsScreen(viewModel: viewModel)
            .preferredColorScheme(.light)
        
        SettingsScreen(viewModel: viewModel)
            .preferredColorScheme(.dark)
    }
}

// MARK: - Preview Mocks

private class MockGetSettingsUseCase: GetSettingsUseCase {
    func execute() async throws -> UserSettings {
        UserSettings(biometricAuthEnabled: true, textSizePercentage: 110)
    }
}

private class MockUpdateSettingsUseCase: UpdateSettingsUseCase {
    func execute(settings: UserSettings) async throws {
        // Mock implementation for preview
    }
}

private class MockSettingsRepository: SettingsRepository {
    func get() async throws -> UserSettings {
        UserSettings(biometricAuthEnabled: true, textSizePercentage: 110)
    }
    
    func save(_ settings: UserSettings) async throws {
        // Mock implementation for preview
    }
}