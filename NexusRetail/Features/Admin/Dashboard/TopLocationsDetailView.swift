//
//  TopLocationsDetailView.swift
//  NexusRetail
//

import SwiftUI
import CoreLocation

struct TopLocationsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    let countryPolygons: [CountryPolygon]
    let revenueByCountry: [CountryRevenue]
    
    private var maxRevenue: Double {
        revenueByCountry.map(\.revenue).max() ?? 1
    }
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var selectedCountry: String? = nil
    @State private var timeRange: StoreChartTimeRange = .monthly(Date())
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(RSMSColors.secondaryText)
                }
                
                Spacer()
                
                Text("Top Customer Locations")
                    .font(RSMSFonts.headline)
                    .foregroundColor(RSMSColors.primaryText)
                
                Spacer()
                
                // Placeholder for balance
                Color.clear.frame(width: 28, height: 28)
            }
            .padding()
            .background(RSMSColors.background)
            
            ScrollView {
                VStack(spacing: RSMSSpacing.xl) {
                    
                    // Time Range Picker
                    SwipeableCalendarView(selectedRange: $timeRange)
                        .padding(.horizontal)
                    // Map Area
                    ZStack {
                        Color.white
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedCountry = nil
                                }
                            }
                        
                        ForEach(countryPolygons) { country in
                            let isSelected = selectedCountry == country.name
                            
                            CountryShape(polygons: country.polygons)
                                .fill(getFillColor(for: country.name).opacity(getOpacity(for: country.name, isSelected: isSelected)))
                                .stroke(isSelected ? Color.blue : Color.white, lineWidth: isSelected ? 1.5 : 0.5)
                                .onTapGesture {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedCountry = (selectedCountry == country.name) ? nil : country.name
                                    }
                                }
                        }
                    }
                    .contentShape(Rectangle())
                    .aspectRatio(1.8, contentMode: .fit)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = max(1.0, lastScale * value)
                            }
                            .onEnded { value in
                                lastScale = max(1.0, scale)
                                scale = lastScale
                                if scale <= 1.0 {
                                    scale = 1.0
                                    lastScale = 1.0
                                    withAnimation { offset = .zero; lastOffset = .zero }
                                }
                            }
                            .simultaneously(with: DragGesture()
                                .onChanged { value in
                                    if scale > 1.0 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { value in
                                    lastOffset = offset
                                }
                            )
                    )
                    .clipped()
                    .cornerRadius(RSMSRadius.medium)
                    .padding(.horizontal)
                    
                    // Details
                    if let selected = selectedCountry, let data = revenueByCountry.first(where: { $0.country == selected }) {
                        VStack(spacing: RSMSSpacing.sm) {
                            Text(selected)
                                .font(RSMSFonts.headline)
                                .foregroundColor(RSMSColors.primaryText)
                            
                            Text("₹\(shortCurrency(data.revenue)) Revenue")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(getColor(for: data.revenue))
                        }
                    } else {
                        let total = revenueByCountry.reduce(0) { $0 + $1.revenue }
                        VStack(spacing: RSMSSpacing.sm) {
                            Text("Worldwide")
                                .font(RSMSFonts.headline)
                                .foregroundColor(RSMSColors.primaryText)
                            
                            Text("₹\(shortCurrency(total)) Revenue")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(RSMSColors.primaryText)
                            
                            Text("Tap any highlighted region for details")
                                .font(.system(size: 14))
                                .foregroundColor(RSMSColors.secondaryText)
                        }
                    }
                    
                    // Ranking List
                    VStack(alignment: .leading, spacing: RSMSSpacing.md) {
                        Text("Location Ranking")
                            .font(RSMSFonts.headline)
                            .padding(.bottom, RSMSSpacing.sm)
                        
                        let sortedData = revenueByCountry.sorted { $0.revenue > $1.revenue }
                        ForEach(Array(sortedData.enumerated()), id: \.element.country) { index, item in
                            HStack {
                                Text("#\(index + 1)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(RSMSColors.secondaryText)
                                    .frame(width: 30, alignment: .leading)
                                
                                Circle()
                                    .fill(getColor(for: item.revenue))
                                    .frame(width: 12, height: 12)
                                
                                Text(item.country)
                                    .font(.system(size: 16))
                                    .foregroundColor(RSMSColors.primaryText)
                                
                                Spacer()
                                
                                Text("₹\(shortCurrency(item.revenue))")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(RSMSColors.primaryText)
                            }
                            .padding()
                            .background(RSMSColors.cardBackground)
                            .cornerRadius(RSMSRadius.medium)
                            .shadow(color: Color.black.opacity(0.02), radius: 4, y: 2)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
        }
        .background(RSMSColors.background)
    }
    
    private func getFillColor(for countryName: String) -> Color {
        guard let data = revenueByCountry.first(where: { $0.country == countryName }) else {
            return Color(hex: "E5E5EA")
        }
        return getColor(for: data.revenue)
    }
    
    private func getOpacity(for countryName: String, isSelected: Bool) -> Double {
        let hasData = revenueByCountry.contains(where: { $0.country == countryName })
        return isSelected ? 1.0 : (hasData ? 0.8 : 0.4)
    }
    
    private func getColor(for revenue: Double) -> Color {
        guard maxRevenue > 0 else { return Color(hex: "E5E5EA") }
        let ratio = revenue / maxRevenue
        if ratio > 0.66 { return Color(hex: "007AFF") }
        if ratio > 0.33 { return Color(hex: "F4A261") }
        return Color(hex: "E9C46A")
    }
    
    private func shortCurrency(_ value: Double) -> String {
        if value >= 1_000_000 { return String(format: "%.1fM", value / 1_000_000) }
        if value >= 1_000 { return String(format: "%.1fK", value / 1_000) }
        return String(format: "%.0f", value)
    }
}
