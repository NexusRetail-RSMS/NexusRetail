import SwiftUI
import Foundation

class CountryLocalizer {
    static let shared = CountryLocalizer()
    private var englishToRegionCode: [String: String] = [:]
    
    private init() {
        let englishLocale = Locale(identifier: "en_US")
        for code in Locale.isoRegionCodes {
            if let name = englishLocale.localizedString(forRegionCode: code) {
                englishToRegionCode[name.lowercased()] = code
            }
        }
        
        // Add common overrides if needed
        englishToRegionCode["usa"] = "US"
        englishToRegionCode["uk"] = "GB"
    }
    
    func localizedName(for englishName: String, in locale: Locale) -> String {
        if let code = englishToRegionCode[englishName.lowercased()] {
            return locale.localizedString(forRegionCode: code) ?? englishName
        }
        return englishName
    }
}

extension View {
    func localizedCountryText(_ country: String, locale: Locale) -> Text {
        Text(CountryLocalizer.shared.localizedName(for: country, in: locale))
    }
}
