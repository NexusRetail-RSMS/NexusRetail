//
//  SectionHeaderView.swift
//  NexusRetail
//

import SwiftUI

struct SectionHeaderView: View {
    @Environment(AppTheme.self) private var theme
    let title: String
    
    var body: some View {
        Text(title.uppercased())
            .font(.system(size: 15, weight: .heavy))
            .foregroundColor(theme.secondaryText)
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.lg)
            .padding(.bottom, RSMSSpacing.sm)
    }
}

#Preview {
    SectionHeaderView(title: "Sales Performance")
        .background(RSMSColors.background)
}
