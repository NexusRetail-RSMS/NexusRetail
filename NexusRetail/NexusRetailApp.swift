//
//  NexusRetailApp.swift
//  NexusRetail
//

import SwiftUI

/// App entry point (@main). Creates the shared SessionStore and launches RootView.
@main
struct NexusRetailApp: App {
    @State private var sessionStore = SessionStore()
    @State private var localizationManager = LocalizationManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(sessionStore)
                .environment(localizationManager)
                .environment(\.locale, Locale(identifier: localizationManager.currentLanguage))
                .environment(\.layoutDirection, localizationManager.isRTL ? .rightToLeft : .leftToRight)
                .id(localizationManager.currentLanguage)
                .task {
                    // Attempt to restore session on app launch
                    await sessionStore.restore()
                }
        }
    }
}

/// Formats a number into Indian ₹ with Lac / Cr suffixes
public func formatIndianCurrency(_ value: Double) -> String {
    let absoluteAmount = abs(value)
    let isNegative = value < 0
    let sign = isNegative ? "-" : ""
    
    if absoluteAmount >= 1_00_00_000 {
        let cr = absoluteAmount / 1_00_00_000
        return String(format: "%@₹%.2fCr", sign, cr)
    } else if absoluteAmount >= 1_00_000 {
        let lac = absoluteAmount / 1_00_000
        return String(format: "%@₹%.2fL", sign, lac)
    } else if absoluteAmount >= 1_000 {
        let k = absoluteAmount / 1_000
        return String(format: "%@₹%.1fK", sign, k)
    } else {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.currencySymbol = "₹"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 2
        
        let formattedString = formatter.string(from: NSNumber(value: absoluteAmount)) ?? "₹\(absoluteAmount)"
        return "\(sign)\(formattedString)"
    }
}
