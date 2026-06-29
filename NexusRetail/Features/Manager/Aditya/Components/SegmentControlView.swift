//
//  SegmentControlView.swift
//  NexusRetail
//

import SwiftUI

struct SegmentControlView: View {
    @Binding var selection: ManagerSalesTimeRange
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(ManagerSalesTimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selection = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 13, weight: selection == range ? .semibold : .regular))
                        .foregroundColor(selection == range ? .white : RSMSColors.burgundy)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selection == range
                                ? RSMSColors.burgundy
                                : Color.clear
                        )
                        .cornerRadius(RSMSRadius.small)
                }
                .buttonStyle(.plain)
            }
        }
        .background(RSMSColors.burgundy.opacity(0.08))
        .cornerRadius(RSMSRadius.small)
    }
}

#Preview {
    @Previewable @State var selection: ManagerSalesTimeRange = .weekly
    SegmentControlView(selection: $selection)
        .padding()
        .background(RSMSColors.background)
}
