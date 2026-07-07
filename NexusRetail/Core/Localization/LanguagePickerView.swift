import SwiftUI

struct LanguagePickerView: View {
    @Environment(LocalizationManager.self) private var localizationManager
    @Environment(\.dismiss) private var dismiss
    
    // Indicates if we are in the initial launch flow or inside Settings
    let isInitialLaunch: Bool
    
    @State private var selectedLanguageCode: String
    
    init(isInitialLaunch: Bool, initialLanguageCode: String) {
        self.isInitialLaunch = isInitialLaunch
        _selectedLanguageCode = State(initialValue: initialLanguageCode)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSColors.background.ignoresSafeArea()
                
                VStack(spacing: RSMSSpacing.lg) {
                    
                    if isInitialLaunch {
                        VStack(spacing: RSMSSpacing.sm) {
                            Image(systemName: "globe")
                                .font(.system(size: 60))
                                .foregroundColor(RSMSColors.burgundy)
                                .padding(.top, 40)
                                .padding(.bottom, 20)
                            
                            // These strings intentionally use static literals because the
                            // picker is shown before the user selects a language —
                            // they are always displayed in English.
                            Text("Select Language")
                                .font(RSMSFonts.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(RSMSColors.primaryText)
                            
                            Text("Choose your preferred language for the application.")
                                .font(RSMSFonts.body)
                                .foregroundColor(RSMSColors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                    
                    List(localizationManager.supportedLanguages) { language in
                        Button {
                            withAnimation {
                                selectedLanguageCode = language.code
                                // Update the language — this triggers bundle swizzle + UserDefaults save
                                localizationManager.currentLanguage = language.code
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(language.displayName)
                                        .font(RSMSFonts.headline)
                                        .foregroundColor(RSMSColors.primaryText)
                                    
                                    Text(Locale(identifier: language.code).localizedString(forLanguageCode: language.code) ?? language.displayName)
                                        .font(RSMSFonts.caption)
                                        .foregroundColor(RSMSColors.secondaryText)
                                }
                                
                                Spacer()
                                
                                if selectedLanguageCode == language.code {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(RSMSColors.burgundy)
                                        .font(.system(size: 20))
                                }
                            }
                        }
                        .listRowBackground(Color.white.opacity(0.8))
                    }
                    .scrollContentBackground(.hidden)
                    .listStyle(.insetGrouped)
                    
                    if isInitialLaunch {
                        Button {
                            withAnimation {
                                // Mark language as selected — persisted to UserDefaults
                                localizationManager.hasSelectedLanguage = true
                            }
                        } label: {
                            Text("Continue")
                                .font(RSMSFonts.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(RSMSColors.burgundy)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .shadow(color: RSMSColors.burgundy.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.bottom, RSMSSpacing.xl)
                    }
                }
            }
            .navigationTitle(isInitialLaunch ? "" : "Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isInitialLaunch {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { dismiss() }
                            .foregroundColor(RSMSColors.burgundy)
                    }
                }
            }
        }
    }
}
