import SwiftUI
import Combine

// MARK: - Requests Card

struct TransferRequestCard: View {
    let request: AdminStockRequest

    @Environment(AdminTransfersViewModel.self) private var viewModel
    @State private var showingScheduleSheet = false

    private var managerImageURL: URL? {
        request.store?.manager?.imageUrl.flatMap { URL(string: $0) }
    }

    private var productImageURL: URL? {
        request.sku.imageUrl.flatMap { URL(string: $0) }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: request.createdAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: Manager Section
            HStack(spacing: 14) {
                managerAvatar
                managerInfo
            }

            Divider()
                .padding(.top, 14)
                .padding(.bottom, 14)

            // MARK: Product Section
            HStack(spacing: 14) {
                productImage
                productInfo
            }

            // MARK: Request Information
            requestInfoRow
                .padding(.top, 18)

            // MARK: Actions
            actionButtons
                .padding(.top, 20)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .sheet(isPresented: $showingScheduleSheet) {
            ScheduleSheet(request: request)
        }
    }

    // MARK: - Manager Avatar

    @ViewBuilder
    private var managerAvatar: some View {
        if let url = managerImageURL {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.15)
            }
            .frame(width: 52, height: 52)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
        } else {
            ZStack {
                Circle()
                    .fill(RSMSColors.burgundy.opacity(0.08))
                    .frame(width: 52, height: 52)

                Text(String(request.managerName.prefix(1)).uppercased())
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(RSMSColors.burgundy)
            }
        }
    }

    // MARK: - Manager Info

    private var managerInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(request.managerName)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(RSMSColors.primaryText)
                .lineLimit(1)

            Text(request.storeName)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }

    // MARK: - Product Image

    @ViewBuilder
    private var productImage: some View {
        if let url = productImageURL {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.1)
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            RoundedRectangle(cornerRadius: 12)
                .fill(RSMSColors.burgundy.opacity(0.05))
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: "bag")
                        .font(.system(size: 24))
                        .foregroundColor(RSMSColors.burgundy.opacity(0.25))
                )
        }
    }

    // MARK: - Product Info

    private var productInfo: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(request.productName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(RSMSColors.primaryText)
                .lineLimit(1)
                .truncationMode(.tail)

            Text("SKU: \(request.skuCode)")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }

    // MARK: - Request Info Row

    private var requestInfoRow: some View {
        HStack(spacing: 0) {
            InfoColumn(title: "Requested", value: "\(request.quantity)")
            Spacer()
            InfoColumn(title: "Requested On", value: formattedDate, alignment: .trailing)
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        HStack(spacing: 10) {
            Button {
                withAnimation { viewModel.approveRequest(request) }
            } label: {
                Text("Approve")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.nexusRed)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            Button {
                showingScheduleSheet = true
            } label: {
                Text("Schedule")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.nexusRed.opacity(0.1))
                    .foregroundColor(Color.nexusRed)
                    .cornerRadius(10)
            }
        }
    }
}

struct InfoColumn: View {
    let title: String
    let value: String
    var alignment: HorizontalAlignment = .leading

    private var textAlignment: TextAlignment {
        alignment == .trailing ? .trailing : .leading
    }

    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(textAlignment)

            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(RSMSColors.primaryText)
                .lineLimit(1)
                .multilineTextAlignment(textAlignment)
        }
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
    }
}

// MARK: - Schedule Sheet

struct ScheduleSheet: View {
    let request: AdminStockRequest
    @Environment(AdminTransfersViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate: Date = {
        Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    }()

    private var minimumDate: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: selectedDate)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 40))
                    .foregroundColor(RSMSColors.burgundy)

                Text("Schedule Request")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Choose the date on which this request should be automatically approved. You can approve it earlier at any time from the Waiting tab.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 32)
            .padding(.bottom, 24)

            // Date Picker
            VStack(spacing: 12) {
                DatePicker(
                    "Auto Approve On",
                    selection: $selectedDate,
                    in: minimumDate...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(Color.nexusRed)
                .padding(.horizontal, 20)

                Text("Auto approval will occur on **\(formattedDate)**")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Actions
            VStack(spacing: 12) {
                Button {
                    withAnimation {
                        viewModel.scheduleRequest(request, autoApproveDate: selectedDate)
                    }
                    dismiss()
                } label: {
                    Text("Schedule Request")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.nexusRed)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.nexusRed.opacity(0.1))
                        .foregroundColor(Color.nexusRed)
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(RSMSColors.background)
        .presentationDetents([.large])
    }
}

// MARK: - Waiting Card

struct WaitingRequestCard: View {
    let request: AdminStockRequest

    @Environment(AdminTransfersViewModel.self) private var viewModel
    @State private var showingApproveEarlyAlert = false
    @State private var now = Date()

    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var countdownText: String {
        guard let autoApprove = request.autoApproveAt else { return "" }
        let calendar = Calendar.current
        let daysRemaining = calendar.dateComponents([.day], from: now, to: autoApprove).day ?? 0

        if daysRemaining > 1 {
            return "\(daysRemaining) days remaining"
        } else if daysRemaining == 1 {
            return "Tomorrow"
        } else if daysRemaining == 0 {
            return "Approves today"
        } else {
            return "Approved"
        }
    }

    var countdownColor: Color {
        guard let autoApprove = request.autoApproveAt else { return .secondary }
        let calendar = Calendar.current
        let daysRemaining = calendar.dateComponents([.day], from: now, to: autoApprove).day ?? 0

        if daysRemaining <= 0 { return .green }
        if daysRemaining <= 2 { return .orange }
        return RSMSColors.burgundy
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Store
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(request.storeName)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)

                    Text("Scheduled")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Countdown
                if let autoApprove = request.autoApproveAt {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(countdownText)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(countdownColor)

                        Text(autoApprove.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()
                .padding(.top, 10)
                .padding(.bottom, 12)

            // Product Info
            VStack(alignment: .leading, spacing: 2) {
                Text(request.productName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text("SKU: \(request.skuCode)")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            // Quantity & Schedule Dates
            HStack(spacing: 0) {
                InfoColumn(title: "Requested", value: "\(request.quantity)", alignment: .leading)

                if let scheduledAt = request.scheduledAt {
                    InfoColumn(
                        title: "Scheduled On",
                        value: scheduledAt.formatted(date: .abbreviated, time: .omitted),
                        alignment: .trailing
                    )
                }
            }
            .padding(.top, 12)

            if let autoApprove = request.autoApproveAt {
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Auto Approves On")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(autoApprove.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(countdownColor)
                    }

                    Spacer()
                }
                .padding(.top, 8)
            }

            // Approve Early Button
            Button {
                showingApproveEarlyAlert = true
            } label: {
                Text("Approve Early")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.nexusRed)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 16)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
        .alert("Approve Early", isPresented: $showingApproveEarlyAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Approve", role: .none) {
                withAnimation {
                    viewModel.approveEarly(request)
                }
            }
        } message: {
            Text("Are you sure you want to approve this scheduled request early?")
        }
        .onReceive(timer) { date in
            now = date
            viewModel.checkAutoApprovals()
        }
    }
}

// MARK: - Approved Card

struct ApprovedRequestCard: View {
    let request: AdminStockRequest

    private var badgeTitle: String {
        guard let method = request.approvalMethod else { return "Approved" }
        switch method {
        case .immediate: return "Approved"
        case .scheduled: return "Auto Approved"
        case .early: return "Approved Early"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header Row: Store Name + Approved Badge
            HStack(alignment: .center) {
                Text(request.storeName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)
                    .lineLimit(1)

                Spacer(minLength: 12)

                HStack(spacing: 4) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                    Text(badgeTitle)
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(RSMSColors.burgundy)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(RSMSColors.burgundy.opacity(0.1))
                .cornerRadius(8)
            }

            Divider()
                .padding(.top, 12)
                .padding(.bottom, 14)

            // Product Info
            VStack(alignment: .leading, spacing: 3) {
                Text(request.productName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text("SKU: \(request.skuCode)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            // Bottom Row: Quantity + Approval Date
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Requested")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("\(request.quantity)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                }

                Spacer()

                if let approvedAt = request.approvedAt {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("Approved On")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)
                        Text(approvedAt.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(RSMSColors.primaryText)
                    }
                }
            }
            .padding(.top, 14)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}


