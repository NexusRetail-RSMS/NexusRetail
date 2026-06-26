import SwiftUI
import CoreLocation

struct TopLocationsChartView: View {
    @State private var countryPolygons: [CountryPolygon] = []
    
    // Zoom and Pan state for the preview
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    
    @State private var timeRange: StoreChartTimeRange = .month
    @State private var showingDetail = false
    @State private var selectedCountry: String? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.lg) {
            
            // Title (Moved above the graph)
            Text("Top Customer Locations")
                .font(RSMSFonts.headline)
                .foregroundColor(RSMSColors.primaryText)
            
            // Custom Vector Map View
            GeometryReader { geometry in
                ZStack {
                    Color.white // Plain white background
                    
                    // Draw countries
                    ForEach(countryPolygons) { country in
                        let isSelected = selectedCountry == country.name
                        let salesData = TopLocationsSampleData.salesData(for: timeRange)
                        let colorData = salesData[country.name]
                        let defaultColor = Color(hex: "E5E5EA")
                        let fillColor = colorData?.color ?? defaultColor
                        
                        CountryShape(polygons: country.polygons)
                            .fill(fillColor.opacity(isSelected ? 1.0 : (colorData != nil ? 0.8 : 0.4)))
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
                .scaleEffect(scale)
                .offset(offset)
            }
            .frame(height: 280)
            .cornerRadius(RSMSRadius.medium)
            .clipped()
            
            // Clickable details section to open the detail view
            VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
                // Dynamic Details based on selection
                if let selected = selectedCountry, let data = TopLocationsSampleData.salesData(for: timeRange)[selected] {
                    HStack(alignment: .lastTextBaseline, spacing: RSMSSpacing.sm) {
                        Text(data.value)
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(data.color)
                        
                        Text("customers in \(selected)")
                            .font(RSMSFonts.subheadline)
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                } else {
                    HStack(alignment: .lastTextBaseline, spacing: RSMSSpacing.sm) {
                        Text(TopLocationsSampleData.salesData(for: timeRange)["United States of America"]?.value ?? "19k")
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
            TopLocationsDetailView(timeRange: $timeRange, countryPolygons: countryPolygons)
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
    TopLocationsChartView()
        .padding()
        .background(RSMSColors.background)
}
