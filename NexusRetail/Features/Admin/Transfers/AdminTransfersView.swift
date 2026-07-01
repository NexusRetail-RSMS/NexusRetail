import SwiftUI

enum TransferTab: String, CaseIterable {
    case requests = "Requests"
    case waiting = "Waiting"
}

struct AdminTransfersView: View {
    @Environment(AdminTransfersViewModel.self) private var viewModel
    @State private var selectedTab: TransferTab = .requests

    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerSection
                    .padding(.top, 16)
                    .padding(.bottom, 16)

                // Tabs
                Picker("Tabs", selection: $selectedTab) {
                    ForEach(TransferTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.bottom, RSMSSpacing.md)

                // Content
                TabView(selection: $selectedTab) {
                    RequestsListView()
                        .tag(TransferTab.requests)
                    WaitingRequestsView()
                        .tag(TransferTab.waiting)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if viewModel.requests.isEmpty {
                Task {
                    await viewModel.load()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            viewModel.checkAutoApprovals()
        }
    }

    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("Transfers")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(RSMSColors.primaryText)

            Spacer()

            NavigationLink {
                HistoryView()
            } label: {
                ZStack {
                    Circle()
                        .fill(RSMSColors.burgundy.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(RSMSColors.burgundy)
                }
            }
            .accessibilityLabel("History")
        }
        .padding(.horizontal, RSMSSpacing.lg)
    }
}

// MARK: - Requests

struct RequestsListView: View {
    @Environment(AdminTransfersViewModel.self) private var viewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.isLoading && viewModel.requests.isEmpty {
                    skeletonSection
                } else if viewModel.pendingRequests.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.pendingRequests) { request in
                        TransferRequestCard(request: request)
                    }
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.load()
        }
        .background(RSMSColors.background)
    }

    private var skeletonSection: some View {
        ForEach(0..<4, id: \.self) { _ in
            SkeletonCardView()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(RSMSColors.burgundy.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "tray")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(RSMSColors.burgundy)
            }

            VStack(spacing: 6) {
                Text("No Transfer Requests")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(RSMSColors.primaryText)

                Text("New store requests will appear here.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 80)
    }
}

struct SkeletonCardView: View {
    @State private var opacity = 0.3

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Manager Section
            HStack(spacing: 14) {
                Circle()
                    .fill(RSMSColors.burgundy.opacity(0.06))
                    .frame(width: 52, height: 52)

                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(RSMSColors.burgundy.opacity(0.08))
                        .frame(width: 140, height: 14)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(RSMSColors.burgundy.opacity(0.05))
                        .frame(width: 100, height: 11)
                }
            }

            Divider()
                .padding(.top, 14)
                .padding(.bottom, 14)

            // Product Section
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(RSMSColors.burgundy.opacity(0.06))
                    .frame(width: 64, height: 64)

                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(RSMSColors.burgundy.opacity(0.08))
                        .frame(width: 160, height: 14)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(RSMSColors.burgundy.opacity(0.05))
                        .frame(width: 90, height: 11)
                }
            }

            // Request Info — 3 columns
            HStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(RSMSColors.burgundy.opacity(0.05))
                            .frame(width: 40, height: 10)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(RSMSColors.burgundy.opacity(0.08))
                            .frame(width: 50, height: 16)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.top, 18)

            // Action Buttons
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(RSMSColors.burgundy.opacity(0.08))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                RoundedRectangle(cornerRadius: 10)
                    .fill(RSMSColors.burgundy.opacity(0.04))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
            }
            .padding(.top, 20)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                opacity = 0.7
            }
        }
    }
}

// MARK: - Waiting

struct WaitingRequestsView: View {
    @Environment(AdminTransfersViewModel.self) private var viewModel

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.waitingRequests.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.waitingRequests) { request in
                        WaitingRequestCard(request: request)
                    }
                }
            }
            .padding()
        }
        .refreshable {
            await viewModel.load()
        }
        .background(RSMSColors.background)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.checkmark")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("No scheduled requests")
                .foregroundColor(.secondary)
        }
        .padding(.top, 60)
    }
}

// MARK: - History

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                customHeader

                ApprovedHistoryView()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var customHeader: some View {
        HStack(alignment: .center) {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(RSMSColors.burgundy.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(RSMSColors.burgundy)
                }
            }
            .accessibilityLabel("Back")

            Spacer()

            Text("History")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(RSMSColors.primaryText)

            Spacer()

            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

struct ApprovedHistoryView: View {
    @Environment(AdminTransfersViewModel.self) private var viewModel
    @State private var contentOpacity = 0.0

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                if viewModel.approvedRequests.isEmpty {
                    emptyState
                        .padding(.top, 80)
                } else {
                    ForEach(Array(viewModel.approvedRequests.enumerated()), id: \.element.id) { index, request in
                        ApprovedRequestCard(request: request)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            .animation(.easeOut(duration: 0.3).delay(Double(index) * 0.05), value: viewModel.approvedRequests.count)
                    }
                }
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.vertical, 8)
        }
        .refreshable {
            await viewModel.load()
        }
        .background(RSMSColors.background)
        .opacity(contentOpacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) {
                contentOpacity = 1.0
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(RSMSColors.burgundy.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "checkmark.circle")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(RSMSColors.burgundy)
            }

            VStack(spacing: 6) {
                Text("No Transfer History")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(RSMSColors.primaryText)

                Text("Approved transfer requests will appear here.")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}
