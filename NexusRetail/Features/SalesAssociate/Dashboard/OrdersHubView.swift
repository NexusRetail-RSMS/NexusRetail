import SwiftUI

struct OrdersHubView: View {
    @Environment(AppTheme.self) private var theme
    @Binding var path: NavigationPath
    @Environment(\.dismiss) private var dismiss
    @Environment(SellViewModel.self) private var sellVM
    @Environment(SessionStore.self) private var sessionStore

    @State private var bopisVM = BOPISViewModel()

    // BOPIS pack/collect flow (pulled up from BOPISView so the hub is self-contained)
    @State private var orderToPack: BOPISOrder?
    @State private var orderToCollect: BOPISOrder?
    @State private var showNotifiedAlert = false
    @State private var notifiedMessage = ""

    enum Segment: String, CaseIterable, Identifiable {
        case instore = "In-Store"
        case bopis = "BOPIS"
        var id: String { rawValue }
    }
    @State private var segment: Segment = .instore

    private var showInStore: Bool { segment == .instore }
    private var showBOPIS: Bool { segment == .bopis }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

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
                Task {
                    let outcome = await bopisVM.packAndNotify(id: order.id, associateID: sessionStore.currentUser?.id)
                    switch outcome {
                    case .emailed:
                        notifiedMessage = "A pickup code has been emailed to \(order.customerName)."
                    case .noEmail:
                        notifiedMessage = "Order packed, but no email is on file for \(order.customerName). Ask them for their code another way."
                    case .sendFailed:
                        notifiedMessage = "Order packed, but the pickup email couldn't be sent right now. Please try resending or check the email setup."
                    }
                    showNotifiedAlert = true
                }
            }
        }
        .sheet(item: $orderToCollect) { order in
            CollectVerifyView(order: order) { code in
                await bopisVM.verifyAndCollect(id: order.id, code: code)
            } onResend: {
                let outcome = await bopisVM.resendCode(id: order.id)
                switch outcome {
                case .emailed:
                    return "A new pickup code was emailed to \(order.customerName)."
                case .noEmail:
                    return "No email on file for \(order.customerName). Ask them for their code another way."
                case .sendFailed:
                    return "Couldn't send the code right now. Please try again."
                }
            }
        }
        .alert("Ready for Pickup", isPresented: $showNotifiedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(notifiedMessage)
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack(alignment: .center, spacing: RSMSSpacing.md) {
            Button { dismiss() } label: {
                ZStack {
                    Circle().fill(theme.burgundy.opacity(0.1)).frame(width: 44, height: 44)
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold)).foregroundColor(theme.burgundy)
                }
            }
            .accessibilityLabel("Back")

            Text("Orders Hub")
                .font(.system(size: 24, weight: .bold)).foregroundColor(theme.primaryText)
                
            Spacer()

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
        .foregroundColor(theme.burgundy)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(theme.burgundy.opacity(0.08))
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
                Circle().fill(theme.burgundy.opacity(0.08)).frame(width: 44, height: 44)
                Image(systemName: "shippingbox.fill")
                    .foregroundColor(theme.burgundy).font(.system(size: 16))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(order.id)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(theme.primaryText)
                Text("\(order.formattedDate) · \(order.formattedTime)")
                    .font(.system(size: 12)).foregroundColor(theme.secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text(formatIndianCurrency(order.amount))
                    .font(.system(size: 14, weight: .bold)).foregroundColor(theme.primaryText)
                statusPill(order.status)
            }
        }
        .padding(14)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(theme.cardBorder, lineWidth: 1))
    }

    private func statusPill(_ status: String) -> some View {
        let isDone = status == "Completed"
        return Text(status)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(isDone ? theme.success : theme.secondaryText)
            .padding(.horizontal, 8).padding(.vertical, 4)
            .background(isDone ? theme.success.opacity(0.08) : Color.gray.opacity(0.08))
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
            case .waitingForCustomer: orderToCollect = order
            case .collected:          break
            }
        }
    }

    // MARK: - Shared bits
    private func loadingRow(_ text: String) -> some View {
        HStack { Spacer(); ProgressView(text).tint(theme.burgundy); Spacer() }
            .padding(.vertical, 40)
    }

    private func emptyRow(icon: String, text: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(theme.secondaryText.opacity(0.4))
            Text(LocalizedStringKey(text))
                .font(.system(size: 14))
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func reloadAll() async {
        let storeID = sessionStore.currentUser?.storeID
        // Recent POS orders are personal to this associate; BOPIS is a shared
        // store-level pickup queue (associate_id is null until packed).
        await sellVM.fetchRecentOrders(storeID: storeID, associateID: sessionStore.currentUser?.id)
        await bopisVM.loadData(storeID: storeID)
    }

    private func initials(for name: String?) -> String {
        guard let name, !name.isEmpty else { return "SA" }
        let parts = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if parts.count >= 2 { return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased() }
        return String((parts.first ?? "SA").prefix(2)).uppercased()
    }
}
