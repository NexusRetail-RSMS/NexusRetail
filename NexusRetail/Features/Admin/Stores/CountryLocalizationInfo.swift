//
//  CountryLocalizationInfo.swift
//  NexusRetail
//
//  Created by ANOOP on 01/07/26.
//

import Foundation
import CoreLocation

struct CountryLocalizationInfo {
    let locale: String
    let currencyCode: String
    let timezone: String
    let coordinate: CLLocationCoordinate2D
}

enum CountryLocalizationLookup {
    static let table: [String: CountryLocalizationInfo] = [
        "india": .init(locale: "en_IN", currencyCode: "INR", timezone: "Asia/Kolkata", coordinate: .init(latitude: 22.3511, longitude: 78.6677)),
        "united states": .init(locale: "en_US", currencyCode: "USD", timezone: "America/New_York", coordinate: .init(latitude: 39.8283, longitude: -98.5795)),
        "united kingdom": .init(locale: "en_GB", currencyCode: "GBP", timezone: "Europe/London", coordinate: .init(latitude: 54.0, longitude: -2.0)),
        "canada": .init(locale: "en_CA", currencyCode: "CAD", timezone: "America/Toronto", coordinate: .init(latitude: 56.1304, longitude: -106.3468)),
        "australia": .init(locale: "en_AU", currencyCode: "AUD", timezone: "Australia/Sydney", coordinate: .init(latitude: -25.2744, longitude: 133.7751)),
        "germany": .init(locale: "de_DE", currencyCode: "EUR", timezone: "Europe/Berlin", coordinate: .init(latitude: 51.1657, longitude: 10.4515)),
        "france": .init(locale: "fr_FR", currencyCode: "EUR", timezone: "Europe/Paris", coordinate: .init(latitude: 46.2276, longitude: 2.2137)),
        "japan": .init(locale: "ja_JP", currencyCode: "JPY", timezone: "Asia/Tokyo", coordinate: .init(latitude: 36.2048, longitude: 138.2529)),
        "united arab emirates": .init(locale: "ar_AE", currencyCode: "AED", timezone: "Asia/Dubai", coordinate: .init(latitude: 23.4241, longitude: 53.8478)),
        "singapore": .init(locale: "en_SG", currencyCode: "SGD", timezone: "Asia/Singapore", coordinate: .init(latitude: 1.3521, longitude: 103.8198))
    ]

    static let currencies = Array(Set(table.values.map(\.currencyCode))).sorted()
    static let locales = Array(Set(table.values.map(\.locale))).sorted()
    static let timezones = Array(Set(table.values.map(\.timezone))).sorted()

    static func match(for countryName: String) -> CountryLocalizationInfo? {
        table[countryName.trimmingCharacters(in: .whitespaces).lowercased()]
    }
}
