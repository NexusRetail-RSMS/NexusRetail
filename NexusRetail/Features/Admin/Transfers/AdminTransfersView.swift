import SwiftUI

enum TransferTab: String, CaseIterable {
    case pending = "Pending"
    case history = "History"
    case warehouse = "Warehouse Stock"
}

struct AdminTransfersView: View {
    @Environment(AdminTransfersViewModel.self) private var viewModel
    @State private var selectedTab: TransferTab = .pending
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Text("Transfers")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(RSMSColors.primaryText)

                    Spacer()
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, 16)
                .padding(.bottom, 8)

                // Header
                VStack(alignment: .leading, spacing: 8) {
                    // Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(TransferTab.allCases, id: \.self) { tab in
                                Button {
                                    withAnimation {
                                        selectedTab = tab
                                    }
                                } label: {
                                    Text(tab.rawValue)
                                        .fontWeight(selectedTab == tab ? .bold : .regular)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 16)
                                        .background(selectedTab == tab ? Color.nexusRed : Color.clear)
                                        .foregroundColor(selectedTab == tab ? .white : .primary)
                                        .cornerRadius(20)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 20)
                                                .stroke(selectedTab == tab ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.top, 8)
                .background(Color.nexusBackground)
                
                Divider()
                
                // Content
                switch selectedTab {
                case .pending:
                    RequestsListView(status: .pending)
                case .history:
                    HistoryView()
                case .warehouse:
                    WarehouseStockView()
                }
            }
        }
        .background(Color.nexusBackground)
    }
}

struct HistoryView: View {
    @State private var historySelection = 0 // 0 = Approved, 1 = Denied
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("History Type", selection: $historySelection) {
                Text("Approved").tag(0)
                Text("Denied").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()
            .background(Color.nexusBackground)
            
            if historySelection == 0 {
                RequestsListView(status: .approved)
            } else {
                RequestsListView(status: .denied)
            }
        }
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
        LazyVStack(spacing: 16) {
            if filteredRequests.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    Text("No requests found")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 60)
            } else {
                ForEach(filteredRequests) { request in
                    TransferRequestCard(request: request)
                }
            }
        }
        .padding()
        .background(Color.nexusBackground)
    }
}
