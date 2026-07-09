import SwiftUI

struct SettingsView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(SessionStore.self) private var sessionStore
    
    @Bindable var viewModel: ProfileViewModel
    
    @State private var voiceOverEnabled = false
    
    var body: some View {
        Form {
            Section(header: Text("Accessibility")) {
                NavigationLink(destination: LanguageSettingsView()) {
                    SettingsRow(icon: "globe", title: "Language", color: .blue)
                }
                
                Toggle(isOn: $voiceOverEnabled) {
                    SettingsRow(icon: "speaker.wave.2.fill", title: "VoiceOver", color: .green)
                }
                .tint(theme.primaryAction)
                
                Toggle(isOn: Binding(
                    get: { theme.isDarkMode },
                    set: { theme.isDarkMode = $0 }
                )) {
                    SettingsRow(icon: theme.isDarkMode ? "moon.fill" : "sun.max.fill", title: "Dark Mode", color: .purple)
                }
                .tint(theme.primaryAction)
            }
            
            Section(header: Text("Account Security")) {
                NavigationLink(destination: ChangePasswordView(viewModel: viewModel)) {
                    SettingsRow(icon: "lock.fill", title: "Change Password", color: .gray)
                }
                
                NavigationLink(destination: ChangeEmailView(viewModel: viewModel)) {
                    SettingsRow(icon: "envelope.fill", title: "Change Email Address", color: .orange)
                }
                
                NavigationLink(destination: ChangePhoneView(viewModel: viewModel)) {
                    SettingsRow(icon: "phone.fill", title: "Change Phone Number", color: .mint)
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
        .navigationBarTitleDisplayMode(.large)
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
            ZStack {
                color.opacity(0.15)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(width: 30, height: 30)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Text(title)
                .font(RSMSFonts.body)
                .foregroundColor(theme.primaryText)
        }
        .padding(.vertical, 4)
    }
}

struct LanguageSettingsView: View {
    @Environment(AppTheme.self) private var theme
    
    var body: some View {
        Form {
            Section {
                LanguageSettingsButton()
            }
        }
        .scrollContentBackground(.hidden)
        .background(theme.groupedBackground)
        .navigationTitle("Language")
        .navigationBarTitleDisplayMode(.inline)
    }
}
