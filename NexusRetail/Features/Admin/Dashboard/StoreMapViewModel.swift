//
//  StoreMapViewModel.swift
//  NexusRetail
//
//  Dedicated ViewModel for the interactive MapKit store map.
//  Fetches stores exclusively from Supabase and manages
//  map camera state + country statistics.
//

import Foundation
import SwiftUI
import MapKit
import Supabase

// MARK: - ViewModel

@Observable
class StoreMapViewModel {

    // MARK: - Published State

    /// Stores currently displayed on the map.
    var stores: [StoreMapItem] = []

    /// Aggregated stats for the current view (country or worldwide).
    var stats: CountryMapStats?

    /// One-shot camera target. Set this to animate the map to a region,
    /// then NexusMapView clears it back to nil after applying.
    var targetRegion: MKCoordinateRegion?

    /// Whether the store data is currently loading.
    var isLoadingStores = false

    /// Error message if the fetch fails.
    var errorMessage: String?

    /// The currently selected country (nil = world view).
    private(set) var currentCountry: String?
    
    /// Tracks whether the initial data load has completed.
    /// Used to distinguish first load from subsequent filter changes.
    private var initialLoadDone = false

    // MARK: - Supabase RPC Params

    private struct StoresForMapParams: Encodable {
        let p_country: String?
    }

    // MARK: - Update Country

    /// Called when the dashboard country filter changes.
    /// Animates the map and fetches stores for the new country.
    @MainActor
    func updateCountry(_ country: String?, revenueByCountry: [CountryRevenue]) async {
        // On first load, always proceed. After that, skip if country hasn't changed.
        if initialLoadDone {
            guard country != currentCountry else { return }
        }
        
        currentCountry = country

        // 1. Fetch stores from Supabase
        await loadStores(for: country)

        // 2. Compute stats
        computeStats(for: country, revenueByCountry: revenueByCountry)
        
        // 3. Set the camera region
        if country == nil {
            // Global view: frame all actual stores dynamically (prevents massive invalid spans)
            if !stores.isEmpty {
                targetRegion = boundingRegion(for: stores)
            } else {
                targetRegion = CountryMapRegion.world
            }
        } else {
            // Specific country view: use predefined country region for consistency
            targetRegion = CountryMapRegion.region(for: country)
        }
        
        initialLoadDone = true
    }

    // MARK: - Load Stores from Supabase

    @MainActor
    private func loadStores(for country: String?) async {
        isLoadingStores = true
        errorMessage = nil

        do {
            let params = StoresForMapParams(p_country: country)
            let fetched: [StoreMapItem] = try await SupabaseManager.shared.client
                .rpc("stores_for_map", params: params)
                .execute()
                .value

            self.stores = fetched
        } catch {
            print("StoreMapViewModel: Failed to fetch stores — \(error.localizedDescription)")
            self.errorMessage = "Could not load store locations."
            self.stores = []
        }

        isLoadingStores = false
    }
    
    // MARK: - Bounding Region
    
    /// Calculates a region that fits all given stores with padding.
    private func boundingRegion(for items: [StoreMapItem]) -> MKCoordinateRegion {
        guard !items.isEmpty else { return CountryMapRegion.world }
        
        var minLat = items[0].latitude
        var maxLat = items[0].latitude
        var minLon = items[0].longitude
        var maxLon = items[0].longitude
        
        for item in items {
            minLat = min(minLat, item.latitude)
            maxLat = max(maxLat, item.latitude)
            minLon = min(minLon, item.longitude)
            maxLon = max(maxLon, item.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        // Add 20% padding so pins aren't right at the edge
        // Minimum delta of 30.0 ensures the Global view always looks like a zoomed-out global/continental map
        // even if the user only has a single store.
        let latDelta = max((maxLat - minLat) * 1.4, 30.0)
        let lonDelta = max((maxLon - minLon) * 1.4, 30.0)
        
        return MKCoordinateRegion(
            center: center,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }

    // MARK: - Compute Stats

    private func computeStats(for country: String?, revenueByCountry: [CountryRevenue]) {
        if let country = country {
            // Country-specific stats
            let countryStores = stores.filter { $0.country == country }
            let totalRevenue = countryStores.reduce(0) { $0 + $1.revenue }
            let totalOrders = countryStores.reduce(0) { $0 + $1.orderCount }
            let uniqueManagers = Set(countryStores.compactMap { $0.managerName }).count
            let currency = CountryMapRegion.currencySymbols[country] ?? "₹"
            let flag = CountryMapRegion.flags[country] ?? "🌍"

            // Calculate top store in this country (by order count/customers)
            let topStore = countryStores.max(by: { $0.orderCount < $1.orderCount })
            let topStoreName = topStore?.name
            var topStoreDetail: String? = nil
            if let topStore = topStore {
                topStoreDetail = "\(topStore.orderCount) Orders (\(StoreMapViewModel.shortCurrency(topStore.revenue, symbol: currency)))"
            }

            stats = CountryMapStats(
                country: country,
                storeCount: countryStores.count,
                revenue: totalRevenue,
                orderCount: totalOrders,
                managerCount: uniqueManagers,
                currencySymbol: currency,
                flag: flag,
                topCountryName: nil,
                topCountryDetail: nil,
                topStoreName: topStoreName,
                topStoreDetail: topStoreDetail
            )
        } else {
            // World view stats
            let totalRevenue = stores.reduce(0) { $0 + $1.revenue }
            let totalOrders = stores.reduce(0) { $0 + $1.orderCount }
            let uniqueManagers = Set(stores.compactMap { $0.managerName }).count

            // Calculate top country globally (by total order count/customers)
            let countryOrders = Dictionary(grouping: stores, by: { $0.country })
                .mapValues { countryStores in
                    countryStores.reduce(0) { $0 + $1.orderCount }
                }
            let topCountry = countryOrders.max(by: { $0.value < $1.value })
            let topCountryName = topCountry?.key
            
            var topCountryDetail: String? = nil
            if let topCountry = topCountry {
                let countryStores = stores.filter { $0.country == topCountry.key }
                let countryRevenue = countryStores.reduce(0) { $0 + $1.revenue }
                let symbol = CountryMapRegion.currencySymbols[topCountry.key] ?? "₹"
                topCountryDetail = "\(topCountry.value) Orders (\(StoreMapViewModel.shortCurrency(countryRevenue, symbol: symbol)))"
            }

            stats = CountryMapStats(
                country: "Worldwide",
                storeCount: stores.count,
                revenue: totalRevenue,
                orderCount: totalOrders,
                managerCount: uniqueManagers,
                currencySymbol: "₹",
                flag: "🌍",
                topCountryName: topCountryName,
                topCountryDetail: topCountryDetail,
                topStoreName: nil,
                topStoreDetail: nil
            )
        }
    }

    // MARK: - Helpers

    /// Short-format currency string (e.g. "4.2M", "650K").
    static func shortCurrency(_ value: Double, symbol: String = "₹") -> String {
        if value >= 1_000_000 {
            return "\(symbol)\(String(format: "%.1f", value / 1_000_000))M"
        }
        if value >= 1_000 {
            return "\(symbol)\(String(format: "%.0f", value / 1_000))K"
        }
        return "\(symbol)\(String(format: "%.0f", value))"
    }
}
