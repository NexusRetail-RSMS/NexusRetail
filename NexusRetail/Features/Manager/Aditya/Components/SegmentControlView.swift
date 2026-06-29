//
//  SegmentControlView.swift
//  NexusRetail
//

import SwiftUI

struct SegmentControlView: View {
    @Binding var selection: ManagerSalesTimeRange
    
    var body: some View {
        Picker("Time Range", selection: $selection) {
            ForEach(ManagerSalesTimeRange.allCases, id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .fixedSize()
    }
}

#Preview {
    @Previewable @State var selection: ManagerSalesTimeRange = .weekly
    SegmentControlView(selection: $selection)
        .padding()
        .background(RSMSColors.background)
}
