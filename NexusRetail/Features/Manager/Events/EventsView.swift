//
//  EventsView.swift
//  NexusRetail
//
//  Create VIP/launch events, invites, RSVP reports. (TEAM5-11,12,70,71)
//

import SwiftUI

struct EventsView: View {
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Custom Header
            HStack(alignment: .center) {
                Text("Events")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(RSMSColors.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.sm)
            .padding(.bottom, RSMSSpacing.md)
            
            // MARK: - Content
            ManagerPlaceholderView(
                title: "Store Events",
                message: "Track and organize upcoming promotional events and product launches.",
                icon: "calendar"
            )
        }
        .background(RSMSColors.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    EventsView()
}
