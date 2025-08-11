import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
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
                    // The toggle has been replaced with informational text.
                    HStack {
                        Text("Theme")
                        Spacer()
                        Text("Follows System")
                            .foregroundColor(.secondary)
                    }
                }

                Section(header: Text("About")) {
                    // These are now NavigationLinks that will push the new views onto the stack.
                    NavigationLink(destination: PrivacyPolicyView()) {
                        SettingsRow(icon: "shield.lefthalf.filled", title: "Privacy Policy", color: .blue)
                    }
                    NavigationLink(destination: TermsOfServiceView()) {
                        SettingsRow(icon: "doc.text.fill", title: "Terms of Service", color: .green)
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
