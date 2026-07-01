import SwiftUI

enum TransferTab: String, CaseIterable {
    case pending = "Pending"
    case warehouse = "Warehouse Stock"
}

struct AdminTransfersView: View {
    @Environment(AdminTransfersViewModel.self) private var viewModel
    @State private var selectedTab: TransferTab = .pending

    private var pendingCount: Int {
        viewModel.requests.filter { $0.status == .pending || $0.status == .awaitingRestock }.count
    }

    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                headerSection
                    .padding(.top, 16)
                    .padding(.bottom, 18)

                customTabBar
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.bottom, RSMSSpacing.md)

                TabView(selection: $selectedTab) {
                    RequestsListView(status: .pending)
                        .tag(TransferTab.pending)
                    WarehouseStockView()
                        .tag(TransferTab.warehouse)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: selectedTab)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Transfers")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.primaryText)

                HStack(spacing: 5) {
                    Circle()
                        .fill(pendingCount > 0 ? RSMSColors.burgundy : Color.green)
                        .frame(width: 6, height: 6)
                    Text("\(pendingCount) request\(pendingCount == 1 ? "" : "s") awaiting review")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            NavigationLink {
                HistoryView()
                    .navigationTitle("Transfer History")
                    .navigationBarTitleDisplayMode(.inline)
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [RSMSColors.burgundy.opacity(0.14), RSMSColors.burgundy.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)
                        .overlay(
                            Circle().stroke(RSMSColors.burgundy.opacity(0.14), lineWidth: 1)
                        )
                        .shadow(color: RSMSColors.burgundy.opacity(0.12), radius: 8, x: 0, y: 4)

                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(RSMSColors.burgundy)
                }
            }
            .accessibilityLabel("History")
        }
        .padding(.horizontal, RSMSSpacing.lg)
    }

    private var customTabBar: some View {
        HStack(spacing: 6) {
            ForEach(TransferTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        selectedTab = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(tab.rawValue)
                            .font(.system(size: 14, weight: .semibold))

                        if tab == .pending && pendingCount > 0 {
                            Text("\(pendingCount)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(selectedTab == tab ? RSMSColors.burgundy : .white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(selectedTab == tab ? RSMSColors.burgundy.opacity(0.12) : RSMSColors.burgundy)
                                )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .foregroundColor(selectedTab == tab ? RSMSColors.burgundy : .secondary)
                    .background(
                        ZStack {
                            if selectedTab == tab {
                                RoundedRectangle(cornerRadius: 13)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.09), radius: 7, x: 0, y: 3)
                            }
                        }
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 17)
                .fill(RSMSColors.burgundy.opacity(0.06))
        )
    }
}

struct HistoryView: View {
    @State private var historySelection = 0

    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Picker("History Type", selection: $historySelection) {
                    Text("Approved").tag(0)
                    Text("Denied").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                TabView(selection: $historySelection) {
                    RequestsListView(status: .approved)
                        .tag(0)
                    RequestsListView(status: .denied)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .background(RSMSColors.background)
    }
}

struct RequestsListView: View {
    let status: TransferRequestStatus
    @Environment(AdminTransfersViewModel.self) private var viewModel

    var filteredRequests: [AdminStockRequest] {
        viewModel.requests.filter {
            if status == .pending {
                return $0.status == .pending || $0.status == .awaitingRestock
            } else if status == .approved {
                return $0.status == .approved || $0.status == .readyForDispatch || $0.status == .dispatched
            } else {
                return $0.status == status
            }
        }.sorted { $0.requestDate > $1.requestDate }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if filteredRequests.isEmpty {
                    VStack(spacing: 18) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.07))
                                .frame(width: 92, height: 92)
                            Image(systemName: "tray")
                                .font(.system(size: 34, weight: .light))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        VStack(spacing: 4) {
                            Text("No requests found")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("New requests will appear here")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 64)
                } else {
                    ForEach(filteredRequests) { request in
                        if status == .approved, let delivery = viewModel.deliveries.first(where: { $0.transferRequestID == request.id }) {
                            NavigationLink {
                                DeliveryDetailView(delivery: delivery)
                            } label: {
                                TransferRequestCard(request: request)
                            }
                            .buttonStyle(.plain)
                        } else {
                            TransferRequestCard(request: request)
                        }
                    }
                }
            }
            .padding()
        }
        .background(RSMSColors.background)
    }
}
