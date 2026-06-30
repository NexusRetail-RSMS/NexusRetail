//
//  FilterSegmentControl.swift
//  NexusRetail
//

import SwiftUI

struct FilterSegmentControl: View {
    @Binding var selectedFilter: BOPISOrderStatus?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: RSMSSpacing.sm) {
                FilterPill(title: "All", isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
                
                ForEach(BOPISOrderStatus.allCases) { status in
                    FilterPill(title: status.rawValue, isSelected: selectedFilter == status) {
                        selectedFilter = status
                    }
                }
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.vertical, RSMSSpacing.sm)
        }
    }
}

private struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(RSMSFonts.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, RSMSSpacing.md)
                .padding(.vertical, RSMSSpacing.sm)
                .background(isSelected ? RSMSColors.burgundy : Color.white)
                .foregroundColor(isSelected ? .white : RSMSColors.primaryText)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : RSMSColors.inputBorder, lineWidth: 1)
                )
        }
    }
}
