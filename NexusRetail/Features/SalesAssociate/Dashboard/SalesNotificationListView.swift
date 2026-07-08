//
//  SalesNotificationListView.swift
//  NexusRetail
//

import SwiftUI

struct SalesNotificationListView: View {
    @Bindable var viewModel: SalesNotificationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSColors.background.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .tint(RSMSColors.burgundy)
                } else if let error = viewModel.errorMessage {
                    errorView(error)
                } else if viewModel.notifications.isEmpty {
                    emptyStateView
                } else {
                    notificationsList
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(RSMSColors.primaryText)
                    }
                }
            }
        }
    }
    
    // MARK: - Notifications List
    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 14))
                        .foregroundColor(RSMSColors.burgundy)
                    
                    Text("Alerts")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(RSMSColors.primaryText)
                    
                    Spacer()
                    
                    Text("\(viewModel.notifications.count) item\(viewModel.notifications.count == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundColor(RSMSColors.secondaryText)
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 4)
                
                ForEach(viewModel.notifications) { notification in
                    notificationCard(notification)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.markAsRead(notification.id)
                            }
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Notification Card
    private func notificationCard(_ notification: SalesNotification) -> some View {
        HStack(alignment: .top, spacing: 14) {
            // Unread indicator dot
            Circle()
                .fill(viewModel.isRead(notification) ? Color.clear : RSMSColors.burgundy)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            // Icon or Image
            if let urlString = notification.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(notification.color.opacity(0.1))
                        .overlay(
                            Image(systemName: notification.icon)
                                .font(.system(size: 20))
                                .foregroundColor(notification.color)
                        )
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(notification.color.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: notification.icon)
                            .font(.system(size: 20))
                            .foregroundColor(notification.color)
                    )
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(notification.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(RSMSColors.primaryText)
                
                Text(notification.subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(RSMSColors.primaryText.opacity(0.9))
                
                // Extra Details based on type
                switch notification.type {
                case .newEvent(_, _, let venue, let desc, let eventType):
                    if let type = eventType, !type.isEmpty {
                        Text(type.capitalized)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(RSMSColors.burgundy.opacity(0.1))
                            .foregroundColor(RSMSColors.burgundy)
                            .cornerRadius(4)
                    }
                    if let venue = venue, !venue.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin.and.ellipse")
                            Text(venue)
                        }
                        .font(.system(size: 12))
                        .foregroundColor(RSMSColors.secondaryText)
                    }
                    if let desc = desc, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 12))
                            .foregroundColor(RSMSColors.secondaryText)
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                case .upcomingAppointment(_, _, let type, let notes):
                    if let t = type, !t.isEmpty {
                        Text(t.capitalized)
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                    if let notes = notes, !notes.isEmpty {
                        HStack(alignment: .top, spacing: 4) {
                            Image(systemName: "note.text")
                            Text(notes)
                        }
                        .font(.system(size: 12))
                        .foregroundColor(RSMSColors.secondaryText)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                Text(notification.timeAgo)
                    .font(.system(size: 11))
                    .foregroundColor(RSMSColors.secondaryText.opacity(0.7))
                    .padding(.top, 4)
            }
            
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(RSMSColors.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    viewModel.isRead(notification) ? Color.clear : RSMSColors.burgundy.opacity(0.15),
                    lineWidth: 1
                )
        )
        .opacity(viewModel.isRead(notification) ? 0.75 : 1.0)
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 50))
                .foregroundColor(RSMSColors.secondaryText.opacity(0.4))
            
            Text("No Alerts")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(RSMSColors.primaryText)
            
            Text("You're all caught up!")
                .font(.system(size: 14))
                .foregroundColor(RSMSColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(RSMSColors.error)
            Text("Failed to load")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundColor(RSMSColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
