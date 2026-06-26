//
//  TopLocationsDetailView.swift
//  NexusRetail
//

import SwiftUI
import CoreLocation

struct TopLocationsDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var timeRange: StoreChartTimeRange
    let countryPolygons: [CountryPolygon]
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var selectedCountry: String? = nil
    
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
                    Picker("Time Range", selection: $timeRange) {
                        ForEach(StoreChartTimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Map Area
                    GeometryReader { geometry in
                        ZStack {
                            Color.white
                            
                            ForEach(countryPolygons) { country in
                                let isSelected = selectedCountry == country.name
                                let colorData = TopLocationsSampleData.salesData(for: timeRange)[country.name]
                                let defaultColor = Color(hex: "E5E5EA")
                                let fillColor = colorData?.color ?? defaultColor
                                
                                CountryShape(polygons: country.polygons)
                                    .fill(fillColor.opacity(isSelected ? 1.0 : (colorData != nil ? 0.8 : 0.4)))
                                    .stroke(isSelected ? Color.blue : Color.white, lineWidth: isSelected ? 1.5 : 0.5)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedCountry = (selectedCountry == country.name) ? nil : country.name
                                        }
                                    }
                            }
                        }
                        .contentShape(Rectangle())
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
                                    if scale == 1.0 { offset = .zero; lastOffset = .zero }
                                }
                                .simultaneously(with: DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { value in
                                        lastOffset = offset
                                    }
                                )
                        )
                    }
                    .frame(height: 350)
                    .cornerRadius(RSMSRadius.medium)
                    .padding(.horizontal)
                    .clipped()
                    
                    // Details
                    if let selected = selectedCountry, let data = TopLocationsSampleData.salesData(for: timeRange)[selected] {
                        VStack(spacing: RSMSSpacing.sm) {
                            Text(selected)
                                .font(RSMSFonts.headline)
                                .foregroundColor(RSMSColors.primaryText)
                            
                            Text("\(data.value) Customers")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(data.color)
                        }
                    } else {
                        VStack(spacing: RSMSSpacing.sm) {
                            Text("Worldwide")
                                .font(RSMSFonts.headline)
                                .foregroundColor(RSMSColors.primaryText)
                            
                            Text("19,870 Customers")
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
                        
                        let sortedData = TopLocationsSampleData.salesData(for: timeRange).sorted { $0.value.value > $1.value.value }
                        ForEach(Array(sortedData.enumerated()), id: \.element.key) { index, item in
                            HStack {
                                Text("#\(index + 1)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(RSMSColors.secondaryText)
                                    .frame(width: 30, alignment: .leading)
                                
                                Circle()
                                    .fill(item.value.color)
                                    .frame(width: 12, height: 12)
                                
                                Text(item.key)
                                    .font(.system(size: 16))
                                    .foregroundColor(RSMSColors.primaryText)
                                
                                Spacer()
                                
                                Text("\(item.value.value) cust.")
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
}
