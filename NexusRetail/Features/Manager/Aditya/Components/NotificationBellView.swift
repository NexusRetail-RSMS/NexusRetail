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
            // Native Apple bell symbol — shows the built-in dot when there are
            // unread notifications, no custom count badge.
            Image(systemName: unreadCount > 0 ? "bell.badge" : "bell")
                .font(.system(size: 18, weight: .medium))
                .symbolRenderingMode(.multicolor)
                .foregroundColor(theme.burgundy)
                .frame(width: 44, height: 44)
                .background(Circle().fill(theme.burgundy.opacity(0.1)))
        }
        .accessibilityLabel("Notifications")
        .accessibilityHint(unreadCount > 0 ? "You have unread notifications" : "No unread notifications")
    }
}
