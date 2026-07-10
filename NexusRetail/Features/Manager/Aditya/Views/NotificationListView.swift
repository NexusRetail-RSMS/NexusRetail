//
//  NotificationListView.swift
//  NexusRetail
//
//  Sheet view displaying low-stock notifications and inter-store transfer
//  approval requests for the manager.
//

import SwiftUI

struct NotificationListView: View {
    @Environment(AppTheme.self) private var theme
    @Bindable var viewModel: LowStockNotificationViewModel
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView()
                        .tint(theme.burgundy)
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
                            .foregroundColor(theme.primaryText)
                    }
                }
            }
        }
    }

    // MARK: - Notifications List

    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Transfer requests section (actionable — shown first)
                let transferRequests = viewModel.notifications.filter {
                    if case .transferRequest = $0.type { return true }
                    return false
                }

                if !transferRequests.isEmpty {
                    sectionHeader(icon: "arrow.triangle.swap", title: "Transfer Requests", count: transferRequests.count, color: theme.burgundy)

                    ForEach(transferRequests) { notification in
                        transferRequestCard(notification)
                    }

                    Divider()
                        .padding(.vertical, 4)
                }

                // Low stock & approved transfers section
                let otherNotifications = viewModel.notifications.filter {
                    if case .transferRequest = $0.type { return false }
                    return true
                }

                if !otherNotifications.isEmpty {
                    sectionHeader(icon: "bell.badge.fill", title: "Alerts", count: otherNotifications.count, color: theme.burgundy)

                    ForEach(otherNotifications) { notification in
                        notificationCard(notification)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.markAsRead(notification.id)
                                }
                            }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    // MARK: - Section Header

    private func sectionHeader(icon: String, title: String, count: Int, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(theme.primaryText)

            Spacer()

            Text("\(count) item\(count == 1 ? "" : "s")")
                .font(.system(size: 12))
                .foregroundColor(theme.secondaryText)
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 4)
    }

    // MARK: - Transfer Request Card (Approve/Decline)

    private func transferRequestCard(_ notification: LowStockNotification) -> some View {
        guard case .transferRequest(let quantity, let storeName, let transferId, let itemId, let sourceOnHand, let requestingStoreId) = notification.type else {
            return AnyView(EmptyView())
        }

        let isDeclineMode = viewModel.declineTargetId == transferId

        return AnyView(
            VStack(alignment: .leading, spacing: 12) {
                // Header row
                HStack(spacing: 12) {
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

                    VStack(alignment: .leading, spacing: 3) {
                        Text(notification.productName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(theme.primaryText)
                            .lineLimit(1)

                        Text("\(storeName) is requesting **\(quantity)** units")
                            .font(.system(size: 13))
                            .foregroundColor(theme.secondaryText)
                    }

                    Spacer()
                }

                // Stock context banner
                HStack(spacing: 8) {
                    Image(systemName: "cube.box.fill")
                        .font(.system(size: 12))
                        .foregroundColor(sourceOnHand > quantity + 10 ? theme.success : theme.warning)

                    Text("Your stock: **\(sourceOnHand)** units")
                        .font(.system(size: 12))
                        .foregroundColor(theme.primaryText)

                    Spacer()

                    Text("After transfer: \(sourceOnHand - quantity)")
                        .font(.system(size: 12))
                        .foregroundColor(theme.secondaryText)
                }
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(sourceOnHand > quantity + 10 ? theme.success.opacity(0.08) : theme.warning.opacity(0.08))
                )

                // Time ago
                HStack {
                    Image(systemName: "clock")
                        .font(.system(size: 10))
                    Text(notification.timeAgo)
                        .font(.system(size: 11))
                }
                .foregroundColor(theme.secondaryText)

                if isDeclineMode {
                    // Decline reason input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reason for declining (optional)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.secondaryText)

                        TextField("e.g. Running low ourselves", text: Bindable(viewModel).declineReasonText)
                            .font(.system(size: 14))
                            .padding(12)
                            .background(theme.background)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(theme.cardBorder, lineWidth: 1)
                            )

                        HStack(spacing: 10) {
                            Button {
                                Task {
                                    await viewModel.declineTransferRequest(
                                        transferId: transferId,
                                        reason: viewModel.declineReasonText,
                                        storeID: sessionStore.currentUser?.storeID ?? UUID()
                                    )
                                }
                            } label: {
                                Text("Confirm Decline")
                                    .font(.system(size: 13, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(theme.error)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            .disabled(viewModel.isProcessingAction)

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.declineTargetId = nil
                                    viewModel.declineReasonText = ""
                                }
                            } label: {
                                Text("Cancel")
                                    .font(.system(size: 13, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 38)
                                    .background(theme.cardBorder.opacity(0.5))
                                    .foregroundColor(theme.primaryText)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                } else {
                    // Action buttons
                    HStack(spacing: 10) {
                        Button {
                            Task {
                                guard let myStoreId = sessionStore.currentUser?.storeID else { return }

                                await viewModel.approveTransferRequest(
                                    transferId: transferId,
                                    itemId: itemId,
                                    quantity: quantity,
                                    sourceStoreId: myStoreId,
                                    requestingStoreId: requestingStoreId
                                )
                            }
                        } label: {
                            HStack(spacing: 6) {
                                if viewModel.isProcessingAction {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .tint(.white)
                                } else {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                }
                                Text("Approve")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(theme.success)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isProcessingAction)

                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.declineTargetId = transferId
                                viewModel.declineReasonText = ""
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .bold))
                                Text("Decline")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(theme.error.opacity(0.12))
                            .foregroundColor(theme.error)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isProcessingAction)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.cardBackground)
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.burgundy.opacity(0.2), lineWidth: 1)
            )
        )
    }


    // MARK: - Notification Card (Low Stock / Transfer Approved)

    private func notificationCard(_ notification: LowStockNotification) -> some View {
        HStack(spacing: 14) {
            // Unread indicator dot
            Circle()
                .fill(viewModel.isRead(notification) ? Color.clear : theme.burgundy)
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
                    .foregroundColor(theme.primaryText)
                    .lineLimit(1)

                switch notification.type {
                case .lowStock(_, let sku, let category):
                    Text("SKU: \(sku)")
                        .font(.system(size: 12))
                        .foregroundColor(theme.secondaryText)

                    if let category = category {
                        Text(localized: category)
                            .font(.system(size: 11))
                            .foregroundColor(theme.secondaryText.opacity(0.8))
                    }
                case .transferApproved(_):
                    Text("Transfer Request Approved")
                        .font(.system(size: 12))
                        .foregroundColor(theme.success)
                case .transferRequest:
                    EmptyView() // Handled by transferRequestCard
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
                .fill(theme.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    viewModel.isRead(notification) ? Color.clear : theme.burgundy.opacity(0.15),
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
                .foregroundColor(theme.secondaryText.opacity(0.4))

            Text("No Alerts")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(theme.primaryText)

            Text("No items are below 5 units.")
                .font(.system(size: 14))
                .foregroundColor(theme.secondaryText)
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
                .foregroundColor(theme.error)

            Text("Couldn't Load Notifications")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.primaryText)

            Text(localized: message)
                .font(.system(size: 13))
                .foregroundColor(theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}
