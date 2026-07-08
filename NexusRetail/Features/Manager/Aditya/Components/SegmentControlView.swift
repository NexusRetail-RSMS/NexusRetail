//
//  SegmentControlView.swift
//  NexusRetail
//

import SwiftUI

struct SegmentControlView: View {
    @Environment(AppTheme.self) private var theme
    @Binding var selection: SalesTimeRange
    
    var body: some View {
        Picker("Time Range", selection: $selection) {
            ForEach([SalesTimeRange.weekly, SalesTimeRange.monthly], id: \.self) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 250)
    }
}

#Preview {
    @Previewable @State var selection: SalesTimeRange = .weekly
    SegmentControlView(selection: $selection)
        .padding()
        .background(AppTheme().background)
}
