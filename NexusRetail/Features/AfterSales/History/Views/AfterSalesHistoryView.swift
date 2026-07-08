import SwiftUI

struct AfterSalesHistoryView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(AppTheme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath
    @State private var viewModel: AfterSalesHistoryViewModel
    @State private var selectedTab: HistoryTab = .exchanges

    init(path: Binding<NavigationPath>, viewModel: AfterSalesHistoryViewModel = AfterSalesHistoryViewModel()) {
        self._path = path
        self._viewModel = State(initialValue: viewModel)
    }

    enum HistoryTab: String, CaseIterable {
        case exchanges = "Exchanges"
        case repairs = "Repairs"
    }

    struct ReplacementItem: Identifiable, Hashable {
        let id: UUID
        let productName: String
        let imageUrl: String?
        let quantity: Int
    }

    struct InvoiceInfo: Identifiable, Hashable {
        let id: UUID
        let orderTotal: Double
        let pricePaid: Double?
        let pickupCode: String?
        let orderDate: Date
    }

    struct ExchangeItem: Identifiable {
        let id: UUID
        let customerName: String
        let orderId: String?
        let productName: String
        let imageUrl: String?
        let date: Date
        let status: String
        let replacementItem: ReplacementItem?
        let invoice: InvoiceInfo?
    }

    struct RepairItem: Identifiable {
        let id: UUID
        let customerName: String
        let orderId: String?
        let productName: String
        let imageUrl: String?
        let issueDescription: String?
        let serviceCost: Double?
        let date: Date
        let status: String
        let invoice: InvoiceInfo?
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter
    }()

    var body: some View {
        ZStack(alignment: .top) {
            theme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Picker("History Tab", selection: $selectedTab) {
                    ForEach(HistoryTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, 4)
                .padding(.bottom, RSMSSpacing.md)

                ScrollView(showsIndicators: false) {
                    if viewModel.isLoading && viewModel.exchanges.isEmpty && viewModel.repairs.isEmpty {
                        ProgressView()
                            .padding(.top, 40)
                    } else if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 15))
                            .foregroundColor(theme.error)
                            .padding(.top, 40)
                    } else {
                        VStack(spacing: 22) {
                            if selectedTab == .exchanges {
                                if viewModel.exchanges.isEmpty {
                                    emptyState(message: "No completed exchanges found.")
                                } else {
                                    ForEach(viewModel.exchanges) { exchange in
                                        NavigationLink(destination: ExchangeDetailView(item: exchange)) {
                                            exchangeCard(exchange)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            } else {
                                if viewModel.repairs.isEmpty {
                                    emptyState(message: "No completed repairs found.")
                                } else {
                                    ForEach(viewModel.repairs) { repair in
                                        NavigationLink(destination: RepairDetailView(item: repair)) {
                                            repairCard(repair)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.top, 4)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.large)
        .tint(RSMSColors.burgundy)
        .task {
            await viewModel.fetchHistory(storeID: sessionStore.currentUser?.storeID)
        }
        .refreshable {
            await viewModel.fetchHistory(storeID: sessionStore.currentUser?.storeID)
        }
    }

    // MARK: - Empty state
    private func emptyState(message: String) -> some View {
        Text(message)
            .font(.system(size: 15))
            .foregroundColor(theme.secondaryText)
            .padding(.top, 40)
    }

    // MARK: - Cards
    private func exchangeCard(_ item: ExchangeItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                monogram(for: item.customerName)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.customerName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                    Text("#\(referenceCode(item.orderId, fallback: item.id))")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(RSMSColors.secondaryText)
                }
            }

            Divider()

            HStack(alignment: .center, spacing: 10) {
                productVisual(imageUrl: item.imageUrl, productName: item.productName)

                Text(item.productName)
                    .font(.system(size: 15.5, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)

                Spacer()

                Text(Self.dateFormatter.string(from: item.date))
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(RSMSColors.secondaryText)
            }
        }
        .padding(16)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    private func repairCard(_ item: RepairItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                monogram(for: item.customerName)

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.customerName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                    Text("#\(referenceCode(item.orderId, fallback: item.id))")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(RSMSColors.secondaryText)
                }
            }

            Divider()

            HStack(alignment: .center, spacing: 10) {
                productVisual(imageUrl: item.imageUrl, productName: item.productName)

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.productName)
                        .font(.system(size: 15.5, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                }
                Spacer()
                Text(Self.dateFormatter.string(from: item.date))
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(RSMSColors.secondaryText)
            }
        }
        .padding(16)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(RSMSColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    // MARK: - Shared subviews

    private func monogram(for name: String) -> some View {
        Circle()
            .fill(RSMSColors.burgundy)
            .frame(width: 38, height: 38)
            .overlay(
                Text(initials(for: name))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            )
    }

    private func productVisual(imageUrl: String?, productName: String) -> some View {
        Group {
            if let imageUrl, let url = URL(string: imageUrl) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 34, height: 34)
                        .clipShape(RoundedRectangle(cornerRadius: 9))
                } placeholder: {
                    productIconTile(for: productName)
                }
            } else {
                productIconTile(for: productName)
            }
        }
    }

    private func productIconTile(for productName: String) -> some View {
        RoundedRectangle(cornerRadius: 9)
            .fill(RSMSColors.burgundy.opacity(0.08))
            .frame(width: 34, height: 34)
            .overlay(
                Image(systemName: iconName(for: productName))
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(RSMSColors.burgundy)
            )
    }

    private func iconName(for productName: String) -> String {
        let name = productName.lowercased()

        let earbudKeywords = ["airpods", "earbud", "earphone", "buds"]
        let headphoneKeywords = ["headphone", "wh-", "over-ear", "on-ear"]
        let watchKeywords = ["watch", "chronograph", "timex", "rolex", "casio", "titan", "fossil", "seiko"]
        let shoeKeywords = ["shoe", "air max", "sneaker", "jordan", "boot", "sandal", "loafer", "cleat"]
        let laptopKeywords = ["macbook", "laptop", "notebook", "chromebook"]
        let tabletKeywords = ["ipad", "tablet"]
        let phoneKeywords = ["iphone", "galaxy s", "galaxy note", "pixel", "smartphone"]
        let tvKeywords = ["tv", "television"]
        let cameraKeywords = ["camera", "gopro", "dslr"]
        let speakerKeywords = ["speaker", "soundbar", "boombox"]
        let bagKeywords = ["bag", "backpack", "handbag", "wallet", "purse"]
        let clothingKeywords = ["shirt", "jacket", "trouser", "jean", "dress", "hoodie", "sweater"]

        if earbudKeywords.contains(where: name.contains) {
            return "airpodspro"
        } else if headphoneKeywords.contains(where: name.contains) {
            return "headphones"
        } else if watchKeywords.contains(where: name.contains) {
            return "applewatch"
        } else if shoeKeywords.contains(where: name.contains) {
            return "shoe.2"
        } else if laptopKeywords.contains(where: name.contains) {
            return "laptopcomputer"
        } else if tabletKeywords.contains(where: name.contains) {
            return "ipad"
        } else if phoneKeywords.contains(where: name.contains) {
            return "iphone"
        } else if tvKeywords.contains(where: name.contains) {
            return "tv"
        } else if cameraKeywords.contains(where: name.contains) {
            return "camera"
        } else if speakerKeywords.contains(where: name.contains) {
            return "hifispeaker"
        } else if bagKeywords.contains(where: name.contains) {
            return "bag"
        } else if clothingKeywords.contains(where: name.contains) {
            return "tshirt"
        } else {
            return "shippingbox"
        }
    }

    private func tagChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(RSMSColors.burgundy)
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(RSMSColors.burgundy.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }


    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let letters = parts.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    private func referenceCode(_ orderId: String?, fallback id: UUID) -> String {
        if let orderId, !orderId.isEmpty {
            return orderId
        }
        return String(id.uuidString.prefix(8)).uppercased()
    }
}

#Preview {
    let previewVM = AfterSalesHistoryViewModel()
    previewVM.exchanges = [
        AfterSalesHistoryView.ExchangeItem(
            id: UUID(), customerName: "Ananya Verma", orderId: "INV-1028",
            productName: "Timex Chronograph", imageUrl: nil,
            date: Date(), status: "Completed",
            replacementItem: AfterSalesHistoryView.ReplacementItem(
                id: UUID(), productName: "Fossil Gen 6", imageUrl: nil, quantity: 1
            ),
            invoice: AfterSalesHistoryView.InvoiceInfo(
                id: UUID(), orderTotal: 12999, pricePaid: 8999,
                pickupCode: "PU-4471", orderDate: Date()
            )
        ),
        AfterSalesHistoryView.ExchangeItem(
            id: UUID(), customerName: "Vikram Singh", orderId: "INV-1011",
            productName: "Sony WH-1000XM5", imageUrl: nil,
            date: Date(), status: "Completed",
            replacementItem: AfterSalesHistoryView.ReplacementItem(
                id: UUID(), productName: "Sony WH-1000XM5", imageUrl: nil, quantity: 1
            ),
            invoice: nil
        )
    ]
    previewVM.repairs = [
        AfterSalesHistoryView.RepairItem(
            id: UUID(), customerName: "Rahul Sharma", orderId: "INV-1045",
            productName: "Nike Air Max", imageUrl: nil,
            issueDescription: "Sole separation on left shoe.", serviceCost: 0,
            date: Date(), status: "Completed",
            invoice: AfterSalesHistoryView.InvoiceInfo(
                id: UUID(), orderTotal: 7999, pricePaid: 7999,
                pickupCode: "PU-2210", orderDate: Date()
            )
        )
    ]

    return NavigationStack {
        AfterSalesHistoryView(path: .constant(NavigationPath()), viewModel: previewVM)
    }
    .environment(SessionStore())
}
