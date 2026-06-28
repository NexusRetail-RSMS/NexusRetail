import SwiftUI
import CoreLocation

struct TopLocationsChartView: View {
    let revenueByCountry: [CountryRevenue]
    @State private var countryPolygons: [CountryPolygon] = []
    
    // Zoom and Pan state for the preview
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    @State private var timeRange: StoreChartTimeRange = .monthly(Date())
    @State private var showingDetail = false
    @State private var selectedCountry: String? = nil
    
    private var maxRevenue: Double {
        revenueByCountry.map(\.revenue).max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.lg) {
            
            // Title (Moved above the graph)
            Text("Top Customer Locations")
                .font(RSMSFonts.headline)
                .foregroundColor(RSMSColors.primaryText)
            
            // Custom Vector Map View
            ZStack {
                Color.white // Plain white background
                    .onTapGesture {
                        showingDetail = true
                    }
                
                // Draw countries
                ForEach(countryPolygons) { country in
                    let isSelected = selectedCountry == country.name
                    
                    CountryShape(polygons: country.polygons)
                        .fill(getFillColor(for: country.name).opacity(getOpacity(for: country.name, isSelected: isSelected)))
                        .stroke(isSelected ? Color.blue : Color.white, lineWidth: isSelected ? 1.5 : 0.5)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if selectedCountry == country.name {
                                    selectedCountry = nil
                                } else {
                                    selectedCountry = country.name
                                }
                            }
                        }
                }
            }
            .contentShape(Rectangle()) // Ensure drag/zoom works on whitespace
            .aspectRatio(1.8, contentMode: .fit)
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = max(1.0, value.magnitude)
                    }
                    .onEnded { _ in
                        if scale <= 1.0 {
                            withAnimation { offset = .zero }
                        }
                    }
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if scale > 1.0 {
                            offset = value.translation
                        }
                    }
                    .onEnded { _ in
                        if scale <= 1.0 {
                            withAnimation { offset = .zero }
                        }
                    }
            )
            .clipped()
            .cornerRadius(RSMSRadius.medium)
            
            // Clickable details section to open the detail view
            VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
                // Dynamic Details based on selection
                if let selected = selectedCountry, let data = revenueByCountry.first(where: { $0.country == selected }) {
                    HStack(alignment: .lastTextBaseline, spacing: RSMSSpacing.sm) {
                        Text("₹\(shortCurrency(data.revenue))")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(RSMSColors.primaryText)
                        
                        Text("revenue in \(selected)")
                            .font(RSMSFonts.subheadline)
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                } else {
                    let total = revenueByCountry.reduce(0) { $0 + $1.revenue }
                    HStack(alignment: .lastTextBaseline, spacing: RSMSSpacing.sm) {
                        Text("₹\(shortCurrency(total))")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(RSMSColors.primaryText)
                        
                        Text("Total Worldwide")
                            .font(RSMSFonts.subheadline)
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                }
                
                Text("Tap here to see detailed country stats.")
                    .font(.system(size: 13))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showingDetail = true
            }
            
            // Legend / Data List in same line
            HStack(spacing: RSMSSpacing.lg) {
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: "007AFF")).frame(width: 8, height: 8)
                    Text("Massive").font(.system(size: 12)).foregroundColor(RSMSColors.secondaryText)
                }
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: "F4A261")).frame(width: 8, height: 8)
                    Text("Large").font(.system(size: 12)).foregroundColor(RSMSColors.secondaryText)
                }
                HStack(spacing: 6) {
                    Circle().fill(Color(hex: "E9C46A")).frame(width: 8, height: 8)
                    Text("Medium").font(.system(size: 12)).foregroundColor(RSMSColors.secondaryText)
                }
            }
        }
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .fullScreenCover(isPresented: $showingDetail) {
            TopLocationsDetailView(timeRange: $timeRange, countryPolygons: countryPolygons, revenueByCountry: revenueByCountry)
        }
        .onAppear {
            // Load GeoJSON in background so we don't block the main thread
            DispatchQueue.global(qos: .userInitiated).async {
                let loaded = GeoJSONLoader.loadCountries()
                DispatchQueue.main.async {
                    self.countryPolygons = loaded
                }
            }
        }
    }
    
    private func getFillColor(for countryName: String) -> Color {
        guard let data = revenueByCountry.first(where: { $0.country == countryName }), maxRevenue > 0 else {
            return Color(hex: "E5E5EA")
        }
        let ratio = data.revenue / maxRevenue
        if ratio > 0.66 { return Color(hex: "007AFF") }
        if ratio > 0.33 { return Color(hex: "F4A261") }
        return Color(hex: "E9C46A")
    }
    
    private func getOpacity(for countryName: String, isSelected: Bool) -> Double {
        let hasData = revenueByCountry.contains(where: { $0.country == countryName })
        return isSelected ? 1.0 : (hasData ? 0.8 : 0.4)
    }
    
    private func shortCurrency(_ value: Double) -> String {
        if value >= 1_000_000 { return String(format: "%.1fM", value / 1_000_000) }
        if value >= 1_000 { return String(format: "%.1fK", value / 1_000) }
        return String(format: "%.0f", value)
    }
}

private struct LocationRow: View {
    let color: Color
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: RSMSSpacing.sm) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(RSMSColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(RSMSColors.primaryText)
        }
    }
}

// Shape that draws an array of polygons using a simple equirectangular projection
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

#Preview {
    TopLocationsChartView(revenueByCountry: [])
        .padding()
        .background(RSMSColors.background)
}
