import SwiftUI
import Combine

// MARK: - Requests Card

struct TransferRequestCard: View {
    let request: AdminStockRequest

    @Environment(AdminTransfersViewModel.self) private var viewModel
    @State private var showingScheduleSheet = false

    private var productImageURL: URL? {
        request.products.imageUrl.flatMap { URL(string: $0) }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: request.createdAt)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: Manager Section
            managerInfo

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
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(RSMSColors.burgundy.opacity(0.05))
                .frame(width: 70, height: 70)
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
                    .cornerRadius(20)
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
                    .cornerRadius(20)
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
                        .cornerRadius(20)
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
                        .cornerRadius(20)
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

    private var productImageURL: URL? {
        request.products.imageUrl.flatMap { URL(string: $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: Manager Section
            HStack(alignment: .top, spacing: 0) {
                managerInfo
                
                Spacer(minLength: 12)

                // Auto Approve Badge
                if let autoApprove = request.autoApproveAt {
                    VStack(alignment: .center, spacing: 2) {
                        Text("Auto Approves On")
                            .font(.system(size: 10, weight: .semibold))
                        Text(autoApprove.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(RSMSColors.burgundy)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(RSMSColors.burgundy.opacity(0.1))
                    .clipShape(Capsule())
                }
            }

            Divider()
                .padding(.top, 14)
                .padding(.bottom, 14)

            // MARK: Product Section
            HStack(spacing: 14) {
                productImage
                productInfo
            }

            // MARK: Bottom Information
            HStack(spacing: 0) {
                InfoColumn(title: "Requested", value: "\(request.quantity)")
                Spacer()
                if let scheduledAt = request.scheduledAt {
                    InfoColumn(title: "Scheduled On", value: scheduledAt.formatted(date: .abbreviated, time: .omitted), alignment: .trailing)
                }
            }
            .padding(.top, 18)

            // Approve Early Button
            Button {
                showingApproveEarlyAlert = true
            } label: {
                Text("Approve Early")
                    .font(.system(size: 15, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.nexusRed)
                    .foregroundColor(.white)
                    .cornerRadius(20)
            }
            .padding(.top, 20)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
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

    // MARK: - Subviews

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
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(RSMSColors.burgundy.opacity(0.05))
                .frame(width: 70, height: 70)
                .overlay(
                    Image(systemName: "bag")
                        .font(.system(size: 24))
                        .foregroundColor(RSMSColors.burgundy.opacity(0.25))
                )
        }
    }

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

    private var productImageURL: URL? {
        request.products.imageUrl.flatMap { URL(string: $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: Manager Section
            HStack(alignment: .top, spacing: 0) {
                managerInfo
                
                Spacer(minLength: 12)
                
                // Status Badge
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
                .padding(.top, 14)
                .padding(.bottom, 14)

            // MARK: Product Section
            HStack(spacing: 14) {
                productImage
                productInfo
            }

            // MARK: Bottom Information
            HStack(spacing: 0) {
                InfoColumn(title: "Requested", value: "\(request.quantity)")
                Spacer()
                if let approvedAt = request.approvedAt {
                    InfoColumn(title: "Approved On", value: approvedAt.formatted(date: .abbreviated, time: .omitted), alignment: .trailing)
                }
            }
            .padding(.top, 18)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Subviews

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
            .frame(width: 70, height: 70)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(RSMSColors.burgundy.opacity(0.05))
                .frame(width: 70, height: 70)
                .overlay(
                    Image(systemName: "bag")
                        .font(.system(size: 24))
                        .foregroundColor(RSMSColors.burgundy.opacity(0.25))
                )
        }
    }

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
}


