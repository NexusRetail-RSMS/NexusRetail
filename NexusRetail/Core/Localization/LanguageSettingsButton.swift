//
//  LanguageSettingsButton.swift
//  NexusRetail
//
//  A reusable settings row that shows the current language and opens the
//  language picker (non-onboarding mode). Drop this into any profile/settings
//  screen to let users change the app language.
//

import SwiftUI

struct LanguageSettingsButton: View {
    @Environment(LocalizationManager.self) private var localizationManager
    @State private var showPicker = false

    /// When true, renders as a plain HStack row (for VStack-based sheets).
    /// When false (default), renders as a Button suitable for Form/List rows.
    var plainRowStyle: Bool = false

    private var currentDisplayName: String {
        localizationManager.supportedLanguages
            .first { $0.code == localizationManager.currentLanguage }?
            .displayName ?? localizationManager.currentLanguage.uppercased()
    }

    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(RSMSColors.burgundy)
                Text("Language")
                    .foregroundColor(RSMSColors.primaryText)
                Spacer()
                Text(currentDisplayName)
                    .foregroundColor(RSMSColors.secondaryText)
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            LanguagePickerView(isInitialLaunch: false, initialLanguageCode: localizationManager.currentLanguage)
                .environment(localizationManager)
        }
    }
}
