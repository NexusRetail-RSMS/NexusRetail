import SwiftUI

enum TransferTab: String, CaseIterable {
    case pending = "Pending"
    case warehouse = "Warehouse Stock"
}

struct AdminTransfersView: View {
    @Environment(AdminTransfersViewModel.self) private var viewModel
    @State private var selectedTab: TransferTab = .pending
    
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
                    RequestsListView(status: .pending)
                        .tag(TransferTab.pending)
                    WarehouseStockView()
                        .tag(TransferTab.warehouse)
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
                    .navigationTitle("Transfer History")
                    .navigationBarTitleDisplayMode(.inline)
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

struct HistoryView: View {
    @State private var historySelection = 0 // 0 = Approved, 1 = Denied
    
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
                    RequestsListView(status: .unfulfillable)
                        .tag(1)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
        }
        .background(RSMSColors.background)
    }
}

struct RequestsListView: View {
    let status: TransferStatus
    @Environment(AdminTransfersViewModel.self) private var viewModel
    
    var filteredRequests: [AdminStockRequest] {
        viewModel.requests.filter {
            if status == .pending {
                return $0.status == .pending
            } else if status == .approved {
                return $0.status == .approved || $0.status == .dispatched || $0.status == .delivered
            } else {
                return $0.status == status
            }
        }.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if filteredRequests.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else {
                            Text("No requests found")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 60)
                } else {
                    ForEach(filteredRequests) { request in
                        if status == .approved, let delivery = viewModel.deliveries.first(where: { $0.transferRequestID == request.id.uuidString }) {
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
        .refreshable {
            await viewModel.load()
        }
        .background(RSMSColors.background)
    }
}
