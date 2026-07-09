import SwiftUI

struct SettingsView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(SessionStore.self) private var sessionStore
    
    @Bindable var viewModel: ProfileViewModel
    
    @State private var voiceOverEnabled = false
    
    var body: some View {
        Form {
            Section(header: Text("Accessibility")) {
                LanguageSettingsButton()
                    .padding(.vertical, 2)
                
                Toggle(isOn: $voiceOverEnabled) {
                    SettingsRow(icon: "speaker.wave.2.fill", title: "VoiceOver", color: theme.burgundy)
                }
                .tint(theme.burgundy)
                
                Toggle(isOn: Binding(
                    get: { theme.isDarkMode },
                    set: { theme.isDarkMode = $0 }
                )) {
                    SettingsRow(icon: theme.isDarkMode ? "moon.fill" : "sun.max.fill", title: "Dark Mode", color: theme.burgundy)
                }
                .tint(theme.burgundy)
            }
            
            Section(header: Text("Account Security")) {
                NavigationLink(destination: ChangePasswordView(viewModel: viewModel)) {
                    SettingsRow(icon: "lock.fill", title: "Change Password", color: theme.burgundy)
                }
            }
            
            Section {
                Button(role: .destructive) {
                    Task {
                        try? await sessionStore.signOut()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.groupedBackground)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Subviews

struct SettingsRow: View {
    let icon: String
    let title: String
    let color: Color
    
    @Environment(AppTheme.self) private var theme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 20)
            
            Text(title)
                .font(RSMSFonts.body)
                .foregroundColor(theme.primaryText)
        }
        .padding(.vertical, 4)
    }
}

// Removed unused LanguageSettingsView
