import SwiftUI

struct OrdersHubView: View {
    @Binding var path: NavigationPath
    @Environment(\.dismiss) private var dismiss
    @Environment(SellViewModel.self) private var sellVM
    @Environment(SessionStore.self) private var sessionStore

    @State private var bopisVM = BOPISViewModel()

    // BOPIS pack/collect flow (pulled up from BOPISView so the hub is self-contained)
    @State private var orderToPack: BOPISOrder?
    @State private var showNotifiedAlert = false
    @State private var notifiedCustomerName = ""

    enum Segment: String, CaseIterable, Identifiable {
        case all = "All"
        case instore = "In-Store"
        case bopis = "BOPIS"
        var id: String { rawValue }
    }
    @State private var segment: Segment = .all

    private var showInStore: Bool { segment == .all || segment == .instore }
    private var showBOPIS: Bool { segment == .all || segment == .bopis }

    var body: some View {
        ZStack {
            RSMSColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

                // Single segment control — replaces the old stacked
                // In-Store/BOPIS + search + Pending/Waiting mess.
                Picker("Orders", selection: $segment) {
                    ForEach(Segment.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, RSMSSpacing.sm)
                .padding(.bottom, RSMSSpacing.md)

                content
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarHidden(true)
        .task { await reloadAll() }
        .sheet(item: $orderToPack) { order in
            BOPISPackOrderView(order: order) {
                bopisVM.packAndNotify(id: order.id, associateID: sessionStore.currentUser?.id)
                notifiedCustomerName = order.customerName
                showNotifiedAlert = true
            }
        }
        .alert("Customer Notified", isPresented: $showNotifiedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("\(notifiedCustomerName) has been sent a verification code for pickup.")
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack(alignment: .center, spacing: RSMSSpacing.md) {
            Button { dismiss() } label: {
                ZStack {
                    Circle().fill(RSMSColors.burgundy.opacity(0.1)).frame(width: 44, height: 44)
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold)).foregroundColor(RSMSColors.burgundy)
                }
            }
            .accessibilityLabel("Back")

            Text("Orders Hub")
                .font(.system(size: 24, weight: .bold)).foregroundColor(RSMSColors.primaryText)

            Spacer()

            ZStack {
                Circle().fill(RSMSColors.burgundy).frame(width: 40, height: 40)
                Text(initials(for: sessionStore.currentUser?.name))
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
            }
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.sm)
    }

    // A single row in the merged "All" list — either a POS order or a BOPIS order.
    private enum HubEntry: Identifiable {
        case pos(DBOrder)
        case bopis(BOPISOrder)

        var id: String {
            switch self {
            case .pos(let o):   return "pos-\(o.id)"
            case .bopis(let o): return "bopis-\(o.id.uuidString)"
            }
        }
        var date: Date {
            switch self {
            case .pos(let o):   return o.createdDate
            case .bopis(let o): return o.createdDate
            }
        }
    }

    private var mergedEntries: [HubEntry] {
        let pos = sellVM.completedOrders.map { HubEntry.pos($0) }
        let bopis = bopisVM.orders.map { HubEntry.bopis($0) }
        return (pos + bopis).sorted { $0.date > $1.date }   // newest first
    }

    // MARK: - Content
    private var content: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: RSMSSpacing.lg) {
                switch segment {
                case .all:
                    if mergedEntries.isEmpty {
                        emptyRow(icon: "bag", text: "No orders yet")
                    } else {
                        ForEach(mergedEntries) { entry in
                            switch entry {
                            case .pos(let order):
                                VStack(alignment: .leading, spacing: 6) {
                                    typeBadge("In-Store", systemImage: "bag.fill")
                                    posOrderRow(order)
                                }
                            case .bopis(let order):
                                VStack(alignment: .leading, spacing: 6) {
                                    typeBadge("BOPIS", systemImage: "shippingbox.fill")
                                    BOPISCardView(order: order) { handleBOPISAction(order) }
                                }
                            }
                        }
                    }
                case .instore:
                    inStoreContent
                case .bopis:
                    bopisContent
                }
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.md)
            .padding(.bottom, RSMSSpacing.xxxl)
        }
        .refreshable { await reloadAll() }
    }

    private func typeBadge(_ text: String, systemImage: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage).font(.system(size: 10, weight: .bold))
            Text(text).font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(RSMSColors.burgundy)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(RSMSColors.burgundy.opacity(0.08))
        .clipShape(Capsule())
    }

    // MARK: - In-Store (POS completed orders)
    @ViewBuilder
    private var inStoreContent: some View {
        if sellVM.isLoadingOrders && sellVM.completedOrders.isEmpty {
            loadingRow("Loading orders…")
        } else if sellVM.completedOrders.isEmpty {
            emptyRow(icon: "bag", text: "No in-store orders yet")
        } else {
            ForEach(sellVM.completedOrders) { order in
                posOrderRow(order)
            }
        }
    }

    private func posOrderRow(_ order: DBOrder) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle().fill(RSMSColors.burgundy.opacity(0.08)).frame(width: 44, height: 44)
                Image(systemName: "shippingbox.fill")
                    .foregroundColor(RSMSColors.burgundy).font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(order.id)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.primaryText)
                Text("\(order.formattedDate) · \(order.formattedTime)")
                    .font(.system(size: 12)).foregroundColor(RSMSColors.secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(formatIndianCurrency(order.amount))
                    .font(.system(size: 14, weight: .bold)).foregroundColor(RSMSColors.primaryText)
                statusPill(order.status)
            }
        }
        .padding(14)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSColors.cardBorder, lineWidth: 1))
    }

    private func statusPill(_ status: String) -> some View {
        let isDone = status == "Completed"
        return Text(status)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(isDone ? RSMSColors.success : RSMSColors.secondaryText)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(isDone ? RSMSColors.success.opacity(0.08) : Color.gray.opacity(0.08))
            .clipShape(Capsule())
    }

    // MARK: - BOPIS (pickup orders)
    @ViewBuilder
    private var bopisContent: some View {
        if bopisVM.orders.isEmpty {
            emptyRow(icon: "bag.badge.questionmark", text: "No pickup orders available")
        } else {
            ForEach(bopisVM.orders) { order in
                BOPISCardView(order: order) { handleBOPISAction(order) }
            }
        }
    }

    private func handleBOPISAction(_ order: BOPISOrder) {
        withAnimation {
            switch order.status {
            case .pending:            orderToPack = order
            case .waitingForCustomer: bopisVM.markCollected(id: order.id)
            case .collected:          break
            }
        }
    }

    // MARK: - Shared bits
    private func loadingRow(_ text: String) -> some View {
        HStack { Spacer(); ProgressView(text).tint(RSMSColors.burgundy); Spacer() }
            .padding(.vertical, 40)
    }

    private func emptyRow(icon: String, text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(RSMSColors.secondaryText.opacity(0.4))
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(RSMSColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func reloadAll() async {
        let storeID = sessionStore.currentUser?.storeID
        await sellVM.fetchRecentOrders(storeID: storeID)
        await bopisVM.loadData(storeID: storeID)
    }

    private func initials(for name: String?) -> String {
        guard let name, !name.isEmpty else { return "SA" }
        let parts = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if parts.count >= 2 { return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased() }
        return String((parts.first ?? "SA").prefix(2)).uppercased()
    }
}
