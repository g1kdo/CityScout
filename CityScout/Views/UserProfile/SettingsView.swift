import SwiftUI
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Notifications")) {
                    Toggle("Enable Notifications", isOn: $viewModel.notificationsEnabled)
                        .onChange(of: viewModel.notificationsEnabled) { _, newValue in
                            viewModel.saveNotificationSetting(isEnabled: newValue)
                        }
                }

                Section(header: Text("Appearance")) {
                    HStack {
                        Text("Follows System")
                        Spacer()
                        Toggle("Theme", isOn: .constant(colorScheme == .dark))
                            .labelsHidden()
                            .disabled(true) // Disable user interaction
                    }
                }
                
                Section(header: Text("About")) {
                    NavigationLink(destination: PrivacyPolicyView()) {
                        SettingsRow(icon: "shield.lefthalf.filled", title: "Privacy Policy", color: .blue)
                    }
                    NavigationLink(destination: TermsOfServiceView()) {
                        SettingsRow(icon: "doc.text.fill", title: "Terms of Service", color: .green)
                    }
                    
                    Button(action: {
                        viewModel.rateApp()
                    }) {
                        SettingsRow(icon: "star.fill", title: "Rate App", color: .yellow)
                            .foregroundColor(.primary)
                    }
                    
                    Button(action: {
                        viewModel.shareApp()
                    }) {
                        SettingsRow(icon: "square.and.arrow.up.fill", title: "Share App", color: .orange)
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
    }
}

// A helper view for rows in the Settings screen
struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.body)
                .frame(width: 24, height: 24)
                .foregroundColor(.white)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            
            Text(title)
        }
    }
}
