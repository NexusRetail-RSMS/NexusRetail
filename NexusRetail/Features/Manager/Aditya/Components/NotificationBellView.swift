//
//  NotificationBellView.swift
//  NexusRetail
//
//  Bell icon button with unread badge overlay for low-stock notifications.
//

import SwiftUI

struct NotificationBellView: View {
    @Environment(AppTheme.self) private var theme
    let unreadCount: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                // Bell icon
                Image(systemName: unreadCount > 0 ? "bell.badge.fill" : "bell.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(theme.burgundy)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(theme.burgundy.opacity(0.1))
                    )
                
                // Unread badge
                if unreadCount > 0 {
                    Text(unreadCount > 99 ? "99+" : "\(unreadCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(theme.error)
                        )
                        .offset(x: 4, y: -4)
                }
            }
        }
        .accessibilityLabel("Notifications")
        .accessibilityHint(unreadCount > 0 ? "\(unreadCount) unread low stock alerts" : "No unread notifications")
    }
}
