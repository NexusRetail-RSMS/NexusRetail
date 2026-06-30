//
//  ClientDetailView.swift
//  NexusRetail
//
//  Detail page for a single clienteling record.
//

import SwiftUI

struct ClientDetailView: View {
    let client: AssociateClient

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Hero card with avatar, name, phone
                VStack(alignment: .leading, spacing: 12) {
                    Circle()
                        .fill(RSMSColors.burgundy)
                        .frame(width: 68, height: 68)
                        .overlay {
                            Text(client.initials)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }

                    Text(client.name)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(RSMSColors.primaryText)
                    Text(client.phone)
                        .font(RSMSFonts.body)
                        .foregroundStyle(RSMSColors.secondaryText)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .luxuryCard()

                infoRow(title: "Style Preferences",  value: client.preferences,       icon: "sparkles")
                infoRow(title: "Purchase Pattern",   value: client.purchasePattern,   icon: "chart.line.uptrend.xyaxis")
                infoRow(title: "Recommended Next",   value: client.recommendedNext,   icon: "bag.badge.plus")
            }
            .screenPadding()
        }
        .background(RSMSColors.background.ignoresSafeArea())
        .navigationTitle("Client Card")
        .navigationBarTitleDisplayMode(.inline)
    }
}
