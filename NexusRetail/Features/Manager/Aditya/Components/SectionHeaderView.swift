//
//  SectionHeaderView.swift
//  NexusRetail
//

import SwiftUI

struct SectionHeaderView: View {
    let title: String
    
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 15, weight: .heavy))
            .foregroundColor(RSMSColors.secondaryText)
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.lg)
            .padding(.bottom, RSMSSpacing.sm)
    }
}

#Preview {
    SectionHeaderView(title: "Sales Performance")
        .background(RSMSColors.background)
}
