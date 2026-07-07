//
//  FilterSegmentControl.swift
//  NexusRetail
//

import SwiftUI

struct FilterSegmentControl: View {
    @Binding var selectedFilter: BOPISOrderStatus
    
    var body: some View {
        Picker("Filter", selection: $selectedFilter) {
            Text(LocalizedStringKey(BOPISOrderStatus.pending.rawValue)).tag(BOPISOrderStatus.pending)
            Text(LocalizedStringKey(BOPISOrderStatus.waitingForCustomer.rawValue)).tag(BOPISOrderStatus.waitingForCustomer)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.vertical, RSMSSpacing.sm)
    }
}
