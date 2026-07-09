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
                Image(systemName: "bell.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(theme.burgundy)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(theme.burgundy.opacity(0.1)))
                
                if unreadCount > 0 {
                    Text("\(unreadCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.red)
                        .clipShape(Capsule())
                        .offset(x: 2, y: -2)
                }
            }
        }
        .accessibilityLabel("Notifications")
        .accessibilityHint(unreadCount > 0 ? "You have \(unreadCount) unread notifications" : "No unread notifications")
    }
}
