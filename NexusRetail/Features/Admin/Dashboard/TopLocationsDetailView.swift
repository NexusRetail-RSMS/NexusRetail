//
//  TopLocationsDetailView.swift
//  NexusRetail
//
//  Full-screen, fully-interactive customer-footprint map.
//  Native MapKit (pan / pinch-zoom / drag) with burgundy country
//  overlays shaded by distinct-customer count, store pins, a legend,
//  and a per-country ranking list.
//

import SwiftUI
import MapKit
import CoreLocation

struct TopLocationsDetailView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(\.dismiss) private var dismiss

    let footprint: [CountryFootprint]
    let storePoints: [StorePoint]
    /// When set (a country is selected on the dashboard), the detail is scoped
    /// to that country: its stores, totals, and a zoomed map.
    var focusCountry: String? = nil

    private var ranked: [CountryFootprint] {
        footprint.sorted { $0.customerCount > $1.customerCount }
    }

    /// Stores belonging to the selected country (for the store-level breakdown).
    private var scopedStores: [StorePoint] {
        guard let focusCountry else { return storePoints }
        return storePoints
            .filter { $0.country == focusCountry }
            .sorted { $0.orderCount > $1.orderCount }
    }

    private var totalCustomers: Int {
        focusCountry == nil
            ? footprint.reduce(0) { $0 + $1.customerCount }
            : scopedStores.reduce(0) { $0 + $1.customerCount }
    }
    private var totalOrders: Int {
        focusCountry == nil
            ? footprint.reduce(0) { $0 + $1.orderCount }
            : scopedStores.reduce(0) { $0 + $1.orderCount }
    }
    private var thirdTile: (value: String, label: String) {
        focusCountry == nil
            ? ("\(footprint.count)", "Countries")
            : ("\(scopedStores.count)", "Stores")
    }
    private var headerTitle: String {
        if let focusCountry {
            return "\(CountryMapRegion.flags[focusCountry] ?? "📍") \(focusCountry)"
        }
        return "Top Customer Locations"
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: RSMSSpacing.lg) {
                    // ECharts store-bubble map (pinch-zoom / drag-pan, tooltips)
                    ChoroplethWebView(storePoints: storePoints, focusCountry: focusCountry)
                        .frame(height: 380)
                        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: RSMSRadius.medium)
                                .stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                        .padding(.horizontal)

                    // Totals
                    HStack(spacing: RSMSSpacing.md) {
                        totalTile(icon: "person.2.fill", value: "\(totalCustomers)", label: "Customers")
                        totalTile(icon: "cart.fill", value: "\(totalOrders)", label: "Orders")
                        totalTile(icon: focusCountry == nil ? "globe" : "building.2.fill",
                                  value: thirdTile.value, label: thirdTile.label)
                    }
                    .padding(.horizontal)

                    if focusCountry == nil {
                        countryRankingList
                    } else {
                        storeBreakdownList
                    }
                }
                .padding(.vertical)
            }
        }
        .background(theme.background.ignoresSafeArea())
    }

    private var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(theme.secondaryText)
            }
            Spacer()
            Text(headerTitle)
                .font(RSMSFonts.headline)
                .foregroundColor(theme.primaryText)
                .lineLimit(1)
            Spacer()
            Color.clear.frame(width: 26, height: 26)
        }
        .padding()
        .background(theme.background)
    }

    // Global view: per-country ranking.
    private var countryRankingList: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
            Text("Customer Footprint by Country")
                .font(RSMSFonts.headline)
                .foregroundColor(theme.primaryText)
                .padding(.bottom, 2)

            ForEach(Array(ranked.enumerated()), id: \.element.country) { index, item in
                HStack(spacing: RSMSSpacing.sm) {
                    Text("#\(index + 1)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(theme.secondaryText)
                        .frame(width: 28, alignment: .leading)

                    Text("\(CountryMapRegion.flags[item.country] ?? "📍") \(item.country)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(theme.primaryText)

                    Spacer()

                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(item.customerCount) customers")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.burgundy)
                        Text("\(item.orderCount) orders · \(StoreMapViewModel.shortCurrency(item.revenue, symbol: CountryMapRegion.currencySymbols[item.country] ?? "₹"))")
                            .font(.system(size: 11))
                            .foregroundColor(theme.secondaryText)
                    }
                }
                .padding()
                .background(theme.cardBackground)
                .cornerRadius(RSMSRadius.medium)
                .shadow(color: Color.black.opacity(0.03), radius: 4, y: 2)
            }

            if ranked.isEmpty {
                emptyState
            }
        }
        .padding(.horizontal)
    }

    // Country view: per-store breakdown for the selected country.
    private var storeBreakdownList: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
            Text("Stores in \(focusCountry ?? "")")
                .font(RSMSFonts.headline)
                .foregroundColor(theme.primaryText)
                .padding(.bottom, 2)

            ForEach(Array(scopedStores.enumerated()), id: \.element.id) { index, store in
                HStack(spacing: RSMSSpacing.sm) {
                    Text("#\(index + 1)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(theme.secondaryText)
                        .frame(width: 28, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(store.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(theme.primaryText)
                            .lineLimit(1)
                        if let city = store.city, !city.isEmpty {
                            Text(city)
                                .font(.system(size: 11))
                                .foregroundColor(theme.secondaryText)
                        }
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 1) {
                        Text("\(store.customerCount) customers")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.burgundy)
                        Text("\(store.orderCount) orders · \(StoreMapViewModel.shortCurrency(store.revenue, symbol: CountryMapRegion.currencySymbols[focusCountry ?? ""] ?? "₹"))")
                            .font(.system(size: 11))
                            .foregroundColor(theme.secondaryText)
                    }
                }
                .padding()
                .background(theme.cardBackground)
                .cornerRadius(RSMSRadius.medium)
                .shadow(color: Color.black.opacity(0.03), radius: 4, y: 2)
            }

            if scopedStores.isEmpty {
                emptyState
            }
        }
        .padding(.horizontal)
    }

    private var emptyState: some View {
        Text("No customer activity yet.")
            .font(RSMSFonts.subheadline)
            .foregroundColor(theme.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, RSMSSpacing.xl)
    }

    private func totalTile(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(theme.burgundy)
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(theme.primaryText)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RSMSSpacing.md)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.medium))
        .overlay(RoundedRectangle(cornerRadius: RSMSRadius.medium).stroke(theme.cardBorder.opacity(0.5), lineWidth: 1))
    }
}
