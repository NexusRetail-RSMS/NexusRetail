//
//  NotificationListView.swift
//  NexusRetail
//
//  Sheet view displaying low-stock notifications for the manager.
//

import SwiftUI

struct NotificationListView: View {
    @Bindable var viewModel: LowStockNotificationViewModel
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
                // Section header
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
    
    private func notificationCard(_ notification: LowStockNotification) -> some View {
        HStack(spacing: 14) {
            // Unread indicator dot
            Circle()
                .fill(viewModel.isRead(notification) ? Color.clear : RSMSColors.burgundy)
                .frame(width: 8, height: 8)
            
            // Product image
            if let urlString = notification.imageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    productImagePlaceholder
                }
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                productImagePlaceholder
            }
            
            // Product info
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.productName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(RSMSColors.primaryText)
                    .lineLimit(1)
                
                switch notification.type {
                case .lowStock(_, let sku, let category):
                    Text("SKU: \(sku)")
                        .font(.system(size: 12))
                        .foregroundColor(RSMSColors.secondaryText)
                    
                    if let category = category {
                        Text(category)
                            .font(.system(size: 11))
                            .foregroundColor(RSMSColors.secondaryText.opacity(0.8))
                    }
                case .transferApproved(_):
                    Text("Transfer Request Approved")
                        .font(.system(size: 12))
                        .foregroundColor(RSMSColors.success)
                }
            }
            
            Spacer()
            
            // Stock count + urgency
            VStack(alignment: .trailing, spacing: 6) {
                // Stock count
                HStack(spacing: 2) {
                    if case .transferApproved = notification.type {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                    } else {
                        Image(systemName: "cube.box.fill")
                            .font(.system(size: 10))
                    }
                    Text("\(notification.onHand)")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundColor(notification.urgencyColor)
            }
        }
        .padding(14)
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
        .opacity(viewModel.isRead(notification) ? 0.7 : 1.0)
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
            
            Text("No items are below 5 units.")
                .font(.system(size: 14))
                .foregroundColor(RSMSColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Helpers
    
    private var productImagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray.opacity(0.12))
            .frame(width: 50, height: 50)
            .overlay(
                Image(systemName: "cube.box")
                    .font(.system(size: 18))
                    .foregroundColor(Color.gray.opacity(0.4))
            )
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(RSMSColors.error)
            
            Text("Couldn't Load Notifications")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(RSMSColors.primaryText)
            
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(RSMSColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}
