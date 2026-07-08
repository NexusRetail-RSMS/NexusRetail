import SwiftUI

struct AfterSalesHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath
    @State private var viewModel = AfterSalesHistoryViewModel()
    @State private var selectedTab: HistoryTab = .exchanges
    
    enum HistoryTab: String, CaseIterable {
        case exchanges = "Exchanges"
        case repairs = "Repairs"
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()
    
    var body: some View {
        ZStack(alignment: .top) {
            RSMSColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                
                Picker("History Tab", selection: $selectedTab) {
                    ForEach(HistoryTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.bottom, RSMSSpacing.md)
                
                ScrollView(showsIndicators: false) {
                    if viewModel.isLoading && viewModel.exchanges.isEmpty && viewModel.repairs.isEmpty {
                        ProgressView()
                            .padding(.top, 40)
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 15))
                            .foregroundColor(RSMSColors.error)
                            .padding(.top, 40)
                    } else {
                        VStack(spacing: 16) {
                            if selectedTab == .exchanges {
                                if viewModel.exchanges.isEmpty {
                                    emptyState(message: "No completed exchanges found.")
                                } else {
                                    ForEach(viewModel.exchanges) { exchange in
                                        exchangeCard(exchange)
                                    }
                                }
                            } else {
                                if viewModel.repairs.isEmpty {
                                    emptyState(message: "No completed repairs found.")
                                } else {
                                    ForEach(viewModel.repairs) { repair in
                                        repairCard(repair)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            await viewModel.fetchHistory()
        }
        .refreshable {
            await viewModel.fetchHistory()
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
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
                .accessibilityAddTraits(.isHeader)
            
            Spacer()
            
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
    
    // MARK: - Empty State
    private func emptyState(message: String) -> some View {
        Text(message)
            .font(.system(size: 15))
            .foregroundColor(RSMSColors.secondaryText)
            .padding(.top, 40)
    }
    
    // MARK: - Cards
    private func exchangeCard(_ item: ExchangeHistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.customerName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                    Text("Invoice #\(item.invoiceNumber)")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(RSMSColors.secondaryText)
                }
                Spacer()
                statusBadge(item.status)
            }
            
            Divider()
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.productName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(RSMSColors.primaryText)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Reason:")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(RSMSColors.secondaryText)
                        Text(item.reason)
                            .font(.system(size: 13))
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                }
                Spacer()
                Text(Self.dateFormatter.string(from: item.exchangeDate))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(RSMSColors.secondaryText)
            }
        }
        .padding(16)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .combine)
    }
    
    private func repairCard(_ item: RepairHistoryItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.customerName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                    Text("Invoice #\(item.invoiceNumber)")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(RSMSColors.secondaryText)
                }
                Spacer()
                statusBadge(item.status)
            }
            
            Divider()
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.productName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(RSMSColors.primaryText)
                    Text(item.repairType)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(RSMSColors.burgundy)
                }
                Spacer()
                Text(Self.dateFormatter.string(from: item.completionDate))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(RSMSColors.secondaryText)
            }
        }
        .padding(16)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .combine)
    }
    
    private func statusBadge(_ status: String) -> some View {
        Text(status)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.green)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.1))
            .clipShape(Capsule())
    }
}
