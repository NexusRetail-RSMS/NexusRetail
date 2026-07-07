//
//  LocalizationManager.swift
//  NexusRetail
//
//  Created by Mahak on 06/07/26.
//

import SwiftUI
import Foundation

// MARK: - Bundle Swizzle
// This is the standard approach for in-app language switching in iOS.
// We replace Bundle.main with a custom bundle that loads strings from
// the selected language's .lproj folder inside the app bundle.

private var bundleKey: UInt8 = 0

final class LocalizedBundle: Bundle {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        guard let languageBundle = objc_getAssociatedObject(self, &bundleKey) as? Bundle else {
            return super.localizedString(forKey: key, value: value, table: tableName)
        }
        return languageBundle.localizedString(forKey: key, value: value, table: tableName)
    }
}

extension Bundle {
    /// Call this once to swizzle Bundle.main so it uses the given language code.
    static func setLanguage(_ languageCode: String) {
        // Swap Bundle.main's class to our subclass (only once)
        defer {
            object_setClass(Bundle.main, LocalizedBundle.self)
        }

        // Find the .lproj folder for this language inside the bundle
        let lprojPath = Bundle.main.path(forResource: languageCode, ofType: "lproj")
            ?? Bundle.main.path(forResource: "en", ofType: "lproj")

        let languageBundle: Bundle? = lprojPath.flatMap { Bundle(path: $0) }

        // Store the language-specific bundle as an associated object on Bundle.main
        objc_setAssociatedObject(
            Bundle.main,
            &bundleKey,
            languageBundle,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}

// MARK: - Supported Language

struct SupportedLanguage: Identifiable, Hashable {
    let code: String
    let displayName: String
    
    var id: String { code }
}

// MARK: - LocalizationManager

@Observable
final class LocalizationManager {
    
    // MARK: - Constants
    private enum Keys {
        static let currentLanguage = "currentLanguage"
        static let hasSelectedLanguage = "hasSelectedLanguage"
    }
    
    static let supportedCodes: [String] = ["en", "hi", "es", "fr", "ar"]
    
    // MARK: - Supported Languages
    let supportedLanguages: [SupportedLanguage] = [
        SupportedLanguage(code: "en", displayName: "English"),
        SupportedLanguage(code: "hi", displayName: "हिंदी"),
        SupportedLanguage(code: "es", displayName: "Español"),
        SupportedLanguage(code: "fr", displayName: "Français"),
        SupportedLanguage(code: "ar", displayName: "العربية")
    ]
    
    // MARK: - Published State
    
    /// The currently active language code (e.g. "en", "hi", "ar")
    /// Setting this will swizzle Bundle.main and persist the choice.
    var currentLanguage: String {
        didSet {
            guard currentLanguage != oldValue else { return }
            applyLanguage(currentLanguage)
            UserDefaults.standard.set(currentLanguage, forKey: Keys.currentLanguage)
        }
    }
    
    /// Whether the user has explicitly chosen a language at least once.
    /// Persisted in UserDefaults so we don't show the picker on every launch.
    var hasSelectedLanguage: Bool {
        didSet {
            UserDefaults.standard.set(hasSelectedLanguage, forKey: Keys.hasSelectedLanguage)
        }
    }
    
    // MARK: - Computed Properties
    
    /// True when the current language reads right-to-left (Arabic, Hebrew, etc.)
    var isRTL: Bool {
        let languageCode = Locale(identifier: currentLanguage).language.languageCode?.identifier ?? "en"
        return Locale.Language(identifier: languageCode).characterDirection == .rightToLeft
    }
    
    // MARK: - Init
    
    init() {
        let defaults = UserDefaults.standard
        
        // Restore persisted language or fall back to system language
        let savedLanguage = defaults.string(forKey: Keys.currentLanguage)
        let resolvedLanguage: String
        
        if let saved = savedLanguage, LocalizationManager.supportedCodes.contains(saved) {
            resolvedLanguage = saved
        } else {
            let systemLang = Locale.current.language.languageCode?.identifier ?? "en"
            resolvedLanguage = LocalizationManager.supportedCodes.contains(systemLang) ? systemLang : "en"
        }
        
        self.currentLanguage = resolvedLanguage
        
        // Always set to false on launch so the language picker shows on every app open
        self.hasSelectedLanguage = false
        
        // Apply the bundle swizzle immediately on launch
        applyLanguage(resolvedLanguage)
    }
    
    // MARK: - Private Helpers
    
    private func applyLanguage(_ code: String) {
        Bundle.setLanguage(code)
    }
}
