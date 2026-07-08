//
//  TopLocationsChartView.swift
//  NexusRetail
//
//  Interactive MapKit-based store map for the Admin Dashboard.
//  Replaces the static GeoJSON vector map with native Apple Maps,
//  animated country zoom, store markers with clustering, and
//  country-level statistics.
//

import SwiftUI
import MapKit
import CoreLocation

// MARK: - Main View

struct TopLocationsChartView: View {
    let revenueByCountry: [CountryRevenue]
    let selectedCountry: String?

    @State private var mapVM = StoreMapViewModel()
    @State private var showingDetail = false
    @State private var timeRange: StoreChartTimeRange = .monthly(Date())
    @State private var countryPolygons: [CountryPolygon] = []
    @State private var selectedStore: StoreMapItem?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // MARK: - Header
            headerSection
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, RSMSSpacing.lg)
                .padding(.bottom, RSMSSpacing.md)

            // MARK: - Map
            mapSection
                .padding(.horizontal, RSMSSpacing.md)

            // MARK: - Stats Summary
            statsSection
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, RSMSSpacing.md)

            // MARK: - Store Pills (when country selected)
            if selectedCountry != nil {
                storePillsSection
                    .padding(.top, RSMSSpacing.sm)
                    .padding(.horizontal, RSMSSpacing.lg)
            }

            Spacer().frame(height: RSMSSpacing.lg)
        }
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 4)
        .task {
            await mapVM.updateCountry(selectedCountry, revenueByCountry: revenueByCountry)
        }
        .onChange(of: selectedCountry) { _, newValue in
            Task {
                await mapVM.updateCountry(newValue, revenueByCountry: revenueByCountry)
            }
        }
        .fullScreenCover(isPresented: $showingDetail) {
            TopLocationsDetailView(
                countryPolygons: countryPolygons,
                revenueByCountry: revenueByCountry
            )
        }
        .onAppear {
            // Load GeoJSON for detail view (unchanged)
            DispatchQueue.global(qos: .userInitiated).async {
                let loaded = GeoJSONLoader.loadCountries()
                DispatchQueue.main.async {
                    self.countryPolygons = loaded
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(selectedCountry != nil ? "\(CountryMapRegion.flags[selectedCountry ?? ""] ?? "📍") \(selectedCountry ?? "")" : "Top Customer Locations")
                    .font(RSMSFonts.headline)
                    .foregroundColor(RSMSColors.primaryText)

                if selectedCountry == nil {
                    Text("Stores across all regions")
                        .font(.system(size: 12))
                        .foregroundColor(RSMSColors.secondaryText)
                }
            }

        }
    }

    // MARK: - Map Section

    private var mapSection: some View {
        Map(position: $mapVM.cameraPosition) {
            // Store markers / annotations
            ForEach(mapVM.stores) { store in
                Annotation(store.name, coordinate: store.coordinate) {
                    StoreMarkerView(store: store, isSelected: selectedStore?.id == store.id)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if selectedStore?.id == store.id {
                                    selectedStore = nil
                                } else {
                                    selectedStore = store
                                }
                            }
                        }
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll))
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .frame(height: 260)
        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.medium)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .overlay(alignment: .bottom) {
            // Selected store callout
            if let store = selectedStore {
                storeCallout(store)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(RSMSSpacing.sm)
            }
        }
        .overlay(alignment: .topTrailing) {
            // Loading indicator
            if mapVM.isLoadingStores {
                ProgressView()
                    .tint(RSMSColors.burgundy)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .padding(RSMSSpacing.sm)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedStore?.id)
    }

    // MARK: - Store Callout Overlay

    private func storeCallout(_ store: StoreMapItem) -> some View {
        let currency = CountryMapRegion.currencySymbols[store.country] ?? "₹"
        return HStack(spacing: RSMSSpacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(RSMSColors.burgundy)
                    .frame(width: 36, height: 36)
                Image(systemName: "building.2.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(store.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(RSMSColors.primaryText)
                    .lineLimit(1)

                HStack(spacing: RSMSSpacing.sm) {
                    if let city = store.city {
                        Label(city, systemImage: "mappin")
                            .font(.system(size: 11))
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                    Text("·")
                        .foregroundColor(RSMSColors.secondaryText)
                    Text(StoreMapViewModel.shortCurrency(store.revenue, symbol: currency))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(RSMSColors.burgundy)
                    Text("·")
                        .foregroundColor(RSMSColors.secondaryText)
                    Text("\(store.orderCount) orders")
                        .font(.system(size: 11))
                        .foregroundColor(RSMSColors.secondaryText)
                }
            }

            Spacer(minLength: 0)

            // Dismiss
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedStore = nil
                }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(RSMSColors.secondaryText.opacity(0.5))
            }
        }
        .padding(.horizontal, RSMSSpacing.md)
        .padding(.vertical, RSMSSpacing.sm)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.medium))
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        Group {
            if let stats = mapVM.stats {
                if selectedCountry != nil {
                    // Country-specific stats
                    countryStatsView(stats)
                } else {
                    // World stats
                    worldStatsView(stats)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: mapVM.stats?.country)
    }

    private func worldStatsView(_ stats: CountryMapStats) -> some View {
        VStack(spacing: RSMSSpacing.md) {
            HStack(spacing: 0) {
                statPill(
                    icon: "building.2.fill",
                    value: "\(stats.storeCount)",
                    label: "Total Stores",
                    color: RSMSColors.burgundy
                )

                Spacer()

                statPill(
                    icon: "indianrupeesign.circle.fill",
                    value: StoreMapViewModel.shortCurrency(stats.revenue),
                    label: "Revenue",
                    color: Color(hex: "2A9D8F")
                )

                Spacer()

                statPill(
                    icon: "globe",
                    value: "\(Set(mapVM.stores.map { $0.country }).count)",
                    label: "Countries",
                    color: Color(hex: "E76F51")
                )
            }
            
            if let topCountry = stats.topCountryName, let topDetail = stats.topCountryDetail {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "D4A017").opacity(0.12))
                            .frame(width: 28, height: 28)
                        Image(systemName: "crown.fill")
                            .foregroundColor(Color(hex: "D4A017"))
                            .font(.system(size: 12, weight: .bold))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("Top Region:")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(RSMSColors.secondaryText)
                            Text("\(CountryMapRegion.flags[topCountry] ?? "") \(topCountry)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(RSMSColors.primaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        
                        Text(topDetail)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(RSMSColors.burgundy)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "F4A261").opacity(0.08))
                .cornerRadius(RSMSRadius.small)
            }
        }
    }

    private func countryStatsView(_ stats: CountryMapStats) -> some View {
        VStack(spacing: RSMSSpacing.md) {
            // Revenue headline
            HStack(alignment: .lastTextBaseline, spacing: RSMSSpacing.sm) {
                Text(StoreMapViewModel.shortCurrency(stats.revenue, symbol: stats.currencySymbol))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)

                Text("Revenue")
                    .font(RSMSFonts.subheadline)
                    .foregroundColor(RSMSColors.secondaryText)

                Spacer()
            }

            // Stat chips row
            HStack(spacing: RSMSSpacing.sm) {
                statChip(icon: "building.2.fill", value: "\(stats.storeCount)", label: "Stores")
                statChip(icon: "cart.fill", value: "\(stats.orderCount)", label: "Orders")
                statChip(icon: "person.2.fill", value: "\(stats.managerCount)", label: "Managers")
            }
            
            if let topStore = stats.topStoreName, let topDetail = stats.topStoreDetail {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "D4A017").opacity(0.12))
                            .frame(width: 28, height: 28)
                        Image(systemName: "crown.fill")
                            .foregroundColor(Color(hex: "D4A017"))
                            .font(.system(size: 12, weight: .bold))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("Top Store:")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(RSMSColors.secondaryText)
                            Text(topStore)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(RSMSColors.primaryText)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        
                        Text(topDetail)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(RSMSColors.burgundy)
                    }
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "F4A261").opacity(0.08))
                .cornerRadius(RSMSRadius.small)
            }
        }
    }

    // MARK: - Store Pills (scrollable for country view)

    private var storePillsSection: some View {
        HStack {
            Text("Store Locations")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(RSMSColors.secondaryText)
            
            Spacer()
            
            Menu {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedStore = nil
                        mapVM.cameraPosition = .region(CountryMapRegion.region(for: selectedCountry))
                    }
                } label: {
                    Text("All Stores")
                    if selectedStore == nil {
                        Image(systemName: "checkmark")
                    }
                }
                
                Divider()
                
                ForEach(mapVM.stores) { store in
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedStore = store
                            // Zoom to this store
                            mapVM.cameraPosition = .region(
                                MKCoordinateRegion(
                                    center: store.coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                )
                            )
                        }
                    } label: {
                        Text(store.name)
                        if selectedStore?.id == store.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(mapVM.stores.isEmpty ? "No Stores" : (selectedStore?.name ?? "Select Store"))
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    if !mapVM.stores.isEmpty {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                            .font(.system(size: 14))
                    }
                }
                .foregroundColor(mapVM.stores.isEmpty ? RSMSColors.secondaryText : RSMSColors.burgundy)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    mapVM.stores.isEmpty
                        ? RSMSColors.secondaryText.opacity(0.08)
                        : RSMSColors.burgundy.opacity(0.12)
                )
                .clipShape(Capsule())
            }
            .disabled(mapVM.stores.isEmpty)
        }
    }

    // MARK: - Reusable Components

    private func statPill(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(RSMSColors.primaryText)

            Text(label)
                .font(.system(size: 11))
                .foregroundColor(RSMSColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private func statChip(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(RSMSColors.burgundy)

            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(RSMSColors.primaryText)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(RSMSColors.secondaryText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RSMSColors.burgundy.opacity(0.05))
        .clipShape(Capsule())
    }
}

// MARK: - Custom Store Marker View

/// A branded map marker with a burgundy pin appearance.
private struct StoreMarkerView: View {
    let store: StoreMapItem
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                // Outer glow when selected
                if isSelected {
                    Circle()
                        .fill(RSMSColors.burgundy.opacity(0.15))
                        .frame(width: 40, height: 40)
                }

                // Main pin circle
                Circle()
                    .fill(isSelected ? RSMSColors.darkBurgundy : RSMSColors.burgundy)
                    .frame(width: isSelected ? 28 : 22, height: isSelected ? 28 : 22)
                    .shadow(color: RSMSColors.burgundy.opacity(0.35), radius: 4, x: 0, y: 2)

                // Icon
                Image(systemName: "building.2.fill")
                    .font(.system(size: isSelected ? 12 : 9, weight: .bold))
                    .foregroundColor(.white)
            }

            // Triangle pointer
            Triangle()
                .fill(isSelected ? RSMSColors.darkBurgundy : RSMSColors.burgundy)
                .frame(width: 10, height: 6)
                .offset(y: -1)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Triangle Shape

private struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Country Shape (used by TopLocationsDetailView)

/// Shape that draws an array of polygons using a simple equirectangular projection.
struct CountryShape: Shape {
    let polygons: [[CLLocationCoordinate2D]]

    func path(in rect: CGRect) -> Path {
        var path = Path()

        for polygon in polygons {
            if polygon.isEmpty { continue }

            var subpath = Path()
            for (i, coord) in polygon.enumerated() {
                // Simple equirectangular projection
                // Longitude: -180 to 180 -> 0 to 1
                let x = (coord.longitude + 180) / 360.0
                // Latitude: -90 to 90 -> 1 to 0 (since Y is down)
                // We crop some Antarctica and top Arctic to make it look better
                // Valid latitude typically -60 to 85
                let normalizedLat = (coord.latitude + 60) / 145.0
                let y = 1.0 - normalizedLat

                let point = CGPoint(
                    x: CGFloat(x) * rect.width,
                    y: CGFloat(y) * rect.height
                )

                if i == 0 {
                    subpath.move(to: point)
                } else {
                    subpath.addLine(to: point)
                }
            }
            subpath.closeSubpath()
            path.addPath(subpath)
        }

        return path
    }
}

// MARK: - Preview

#Preview {
    TopLocationsChartView(
        revenueByCountry: [
            CountryRevenue(country: "India", revenue: 5_000_000),
            CountryRevenue(country: "France", revenue: 3_200_000),
            CountryRevenue(country: "UAE", revenue: 2_100_000),
        ],
        selectedCountry: nil
    )
    .padding()
    .background(RSMSColors.background)
}
