//
//  StoreMapModels.swift
//  NexusRetail
//
//  Data models for the interactive MapKit store map on the Admin Dashboard.
//

import Foundation
import CoreLocation
import MapKit

// MARK: - Store Map Item

/// A lightweight store record optimised for map display.
/// Decoded directly from the `stores_for_map` Supabase RPC.
struct StoreMapItem: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let city: String?
    let country: String
    let latitude: Double
    let longitude: Double
    let revenue: Double
    let orderCount: Int
    let managerName: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    enum CodingKeys: String, CodingKey {
        case id, name, city, country, latitude, longitude, revenue
        case orderCount = "order_count"
        case managerName = "manager_name"
    }
}

// MARK: - Country Map Stats

/// Aggregated statistics for a single country (or worldwide).
struct CountryMapStats {
    let country: String
    let storeCount: Int
    let revenue: Double
    let orderCount: Int
    let managerCount: Int
    let currencySymbol: String
    let flag: String
    let topCountryName: String?
    let topCountryDetail: String?
    let topStoreName: String?
    let topStoreDetail: String?
}

// MARK: - Country Region Lookup

/// Pre-defined MapKit camera regions for every supported country.
/// Ensures instant, predictable map animations without geocoding latency.
enum CountryMapRegion {

    /// World overview — shows all continents.
    static let world = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 180)
    )

    /// Country name → camera region lookup.
    static let regions: [String: MKCoordinateRegion] = [
        // Asia
        "India": MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 22.5, longitude: 78.9),
            span: MKCoordinateSpan(latitudeDelta: 28, longitudeDelta: 28)
        ),
        "Japan": MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 36.2, longitude: 138.2),
            span: MKCoordinateSpan(latitudeDelta: 15, longitudeDelta: 18)
        ),
        "Singapore": MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 1.35, longitude: 103.82),
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        ),

        // Europe
        "France": MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 46.6, longitude: 2.2),
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 12)
        ),
        "Germany": MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 51.2, longitude: 10.4),
            span: MKCoordinateSpan(latitudeDelta: 8, longitudeDelta: 10)
        ),
        "United Kingdom": MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 54.0, longitude: -2.0),
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 8)
        ),
        "UK": MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 54.0, longitude: -2.0),
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 8)
        ),

        // Middle East
        "United Arab Emirates": MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 24.0, longitude: 54.0),
            span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 6)
        ),
        "UAE": MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 24.0, longitude: 54.0),
            span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 6)
        ),

        // Americas
        "United States": MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.8, longitude: -98.6),
            span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 50)
        ),
        "USA": MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.8, longitude: -98.6),
            span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 50)
        ),
        "Canada": MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 56.1, longitude: -106.3),
            span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 50)
        ),

        // Oceania
        "Australia": MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -25.3, longitude: 133.8),
            span: MKCoordinateSpan(latitudeDelta: 30, longitudeDelta: 40)
        ),
    ]

    /// Returns the region for a given country name, falling back to world.
    static func region(for country: String?) -> MKCoordinateRegion {
        guard let country = country, let region = regions[country] else {
            return world
        }
        return region
    }

    /// Country name → flag emoji.
    static let flags: [String: String] = [
        "India": "🇮🇳",
        "France": "🇫🇷",
        "Germany": "🇩🇪",
        "Japan": "🇯🇵",
        "Singapore": "🇸🇬",
        "United Kingdom": "🇬🇧",
        "UK": "🇬🇧",
        "United Arab Emirates": "🇦🇪",
        "UAE": "🇦🇪",
        "United States": "🇺🇸",
        "USA": "🇺🇸",
        "Canada": "🇨🇦",
        "Australia": "🇦🇺",
    ]

    /// Country name → currency symbol.
    static let currencySymbols: [String: String] = [
        "India": "₹",
        "France": "€",
        "Germany": "€",
        "Japan": "¥",
        "Singapore": "S$",
        "United Kingdom": "£",
        "UK": "£",
        "United Arab Emirates": "د.إ",
        "UAE": "د.إ",
        "United States": "$",
        "USA": "$",
        "Canada": "C$",
        "Australia": "A$",
    ]
}
