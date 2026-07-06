import SwiftUI
import Supabase

enum StoreSortMetric: String, CaseIterable {
    case revenue = "Top Revenue"
    case customers = "Most Customers"
    case orders = "Most Orders"

    var icon: String {
        switch self {
        case .revenue:   return "indianrupeesign.circle"
        case .customers: return "person.2"
        case .orders:    return "bag"
        }
    }
}

struct StorePerformance {
    var revenue: Double = 0
    var customers: Int = 0
    var orders: Int = 0
}

struct storeDashView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = StoresViewModel()

    @State private var sortMetric: StoreSortMetric = .revenue
    @State private var performance: [UUID: StorePerformance] = [:]
    @State private var isLoadingPerformance = false

    @State private var rankedOrder: [Store] = []
    @State private var deck: [Store] = []
    @State private var isShowingCreateForm = false
    @State private var selectedStoreForAnalytics: Store?
    @Namespace private var heroNamespace

    private func manager(for store: Store) -> DisplayManager? {
        viewModel.managers.first(where: { $0.id == store.managerID })
    }

    private func stats(for store: Store) -> StorePerformance {
        performance[store.id] ?? StorePerformance()
    }

    private func rank(for store: Store) -> Int {
        rankedOrder.firstIndex(of: store).map { $0 + 1 } ?? 0
    }

    private func rebuildDeck() {
        rankedOrder = viewModel.stores.sorted { lhs, rhs in
            let l = stats(for: lhs)
            let r = stats(for: rhs)
            switch sortMetric {
            case .revenue:   return l.revenue > r.revenue
            case .customers: return l.customers > r.customers
            case .orders:    return l.orders > r.orders
            }
        }
        deck = rankedOrder
    }

    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()

            VStack(spacing: RSMSSpacing.lg) {
                header

                if !viewModel.stores.isEmpty {
                    subheader
                }

                Spacer(minLength: 0)

                if viewModel.isLoading && viewModel.stores.isEmpty {
                    ProgressView()
                        .tint(RSMSColors.burgundy)
                } else if viewModel.stores.isEmpty {
                    noStoresState
                } else {
                    StackedStoreCardsView(
                        stores: deck,
                        rank: rank(for:),
                        manager: manager(for:),
                        stats: stats(for:),
                        metric: sortMetric
                    ) { swiped in
                        cycleToBack(swiped)
                    } onTap: { tapped in
                        selectedStoreForAnalytics = tapped
                    }
                    .frame(height: 460)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, RSMSSpacing.md)
            .padding(.bottom, RSMSSpacing.lg)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await viewModel.load()
            await loadPerformance()
            rebuildDeck()
        }
        .onChange(of: sortMetric) { _, _ in
            rebuildDeck()
        }
        .onChange(of: viewModel.stores.map(\.id)) { _, _ in
            rebuildDeck()
        }
        .sheet(isPresented: $isShowingCreateForm) {
            StoreFormView(viewModel: viewModel)
        }
        .navigationDestination(item: $selectedStoreForAnalytics) { store in
            StoreAnalyticsView(store: store, manager: manager(for: store), viewModel: viewModel, namespace: heroNamespace)
        }
    }

    private func loadPerformance() async {
        isLoadingPerformance = true
        defer { isLoadingPerformance = false }

        do {
            let allOrders: [StoreOrder] = try await SupabaseManager.shared.client
                .from("orders")
                .select("id, client_id, store_id, total, created_at")
                .execute()
                .value

            var grouped: [UUID: [StoreOrder]] = [:]
            for order in allOrders {
                guard let storeID = order.storeID else { continue }
                grouped[storeID, default: []].append(order)
            }

            var result: [UUID: StorePerformance] = [:]
            for (storeID, orders) in grouped {
                let revenue = orders.reduce(0) { $0 + $1.total }
                let customers = Set(orders.compactMap { $0.clientID }).count
                result[storeID] = StorePerformance(revenue: revenue, customers: customers, orders: orders.count)
            }

            self.performance = result
        } catch {
            print("Error loading store performance: \(error)")
        }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(RSMSColors.primaryText)
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
            }

            Spacer()

            Text("Store Leaderboard")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(RSMSColors.primaryText)

            Spacer()

            sortMetricChip
        }
    }

    private var subheader: some View {
        HStack(spacing: 6) {
            Image(systemName: sortMetric.icon)
                .font(.system(size: 12, weight: .semibold))
            Text("Ranked by \(sortMetric.rawValue.lowercased())")
                .font(.system(size: 13, weight: .medium))
        }
        .foregroundColor(RSMSColors.secondaryText)
    }

    private var sortMetricChip: some View {
        Menu {
            Picker("Sort by", selection: $sortMetric) {
                ForEach(StoreSortMetric.allCases, id: \.self) { metric in
                    Label(metric.rawValue, systemImage: metric.icon).tag(metric)
                }
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(RSMSColors.primaryText)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityLabel("Sort stores")
        .accessibilityValue(sortMetric.rawValue)
    }

    private var noStoresState: some View {
        VStack(spacing: RSMSSpacing.md) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [RSMSColors.burgundy.opacity(0.14), RSMSColors.burgundy.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 104, height: 104)
                Image(systemName: "building.2.crop.circle")
                    .font(.system(size: 46))
                    .foregroundColor(RSMSColors.burgundy)
            }

            VStack(spacing: 4) {
                Text("No Stores")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.primaryText)
                Text("Let's create your first store.")
                    .font(.system(size: 14))
                    .foregroundColor(RSMSColors.secondaryText)
            }

            Button {
                isShowingCreateForm = true
            } label: {
                Text("Create Store")
                    .font(.system(size: 14, weight: .bold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [RSMSColors.burgundy, RSMSColors.burgundy.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(color: RSMSColors.burgundy.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(PremiumPressStyle())
            .padding(.top, 6)
        }
    }

    private func cycleToBack(_ store: Store) {
        guard let index = deck.firstIndex(where: { $0.id == store.id }) else { return }
        let moved = deck.remove(at: index)
        deck.append(moved)
    }
}

struct StackedStoreCardsView: View {
    let stores: [Store]
    let rank: (Store) -> Int
    let manager: (Store) -> DisplayManager?
    let stats: (Store) -> StorePerformance
    let metric: StoreSortMetric
    var onSwipe: (Store) -> Void
    var onTap: (Store) -> Void

    @State private var dragOffset: CGSize = .zero

    private let visibleCount = 3

    var body: some View {
        ZStack {
            ForEach(Array(topStores.enumerated().reversed()), id: \.element.id) { index, store in
                cardView(for: store, stackIndex: index)
            }
        }
    }

    private var topStores: [Store] {
        Array(stores.prefix(visibleCount))
    }

    @ViewBuilder
    private func cardView(for store: Store, stackIndex: Int) -> some View {
        let isFront = stackIndex == 0
        let fanOffset: CGFloat = CGFloat(stackIndex) * 14
        let fanRotation: Double = Double(stackIndex) * 6
        let scale: CGFloat = 1 - (CGFloat(stackIndex) * 0.04)

        storeCard(store)
            .scaleEffect(scale)
            .rotationEffect(.degrees(isFront ? Double(dragOffset.width / 20) : fanRotation))
            .offset(
                x: isFront ? dragOffset.width : fanOffset,
                y: isFront ? dragOffset.height * 0.2 : 0
            )
            .zIndex(isFront ? 1 : 0)
            .gesture(isFront ? dragGesture(for: store) : nil)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: dragOffset)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: stores.map(\.id))
    }

    private func dragGesture(for store: Store) -> some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                let distance = sqrt(pow(value.translation.width, 2) + pow(value.translation.height, 2))
                let threshold: CGFloat = 120

                if distance < 10 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        dragOffset = .zero
                    }
                    onTap(store)
                } else if abs(value.translation.width) > threshold {
                    let flyOut = CGSize(
                        width: value.translation.width > 0 ? 600 : -600,
                        height: value.translation.height
                    )
                    withAnimation(.easeOut(duration: 0.25)) {
                        dragOffset = flyOut
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        onSwipe(store)
                        dragOffset = .zero
                    }
                } else {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        dragOffset = .zero
                    }
                }
            }
    }

    private func locationLine(for store: Store) -> String {
        let parts = [store.city, store.country].compactMap { $0?.isEmpty == false ? $0 : nil }
        return parts.isEmpty ? "Location not set" : parts.joined(separator: " · ")
    }

    private func formattedRevenue(_ value: Double) -> String {
        if value >= 100000 {
            return "₹\(String(format: "%.1f", value / 100000))L"
        } else if value >= 1000 {
            return "₹\(String(format: "%.1f", value / 1000))K"
        } else {
            return "₹\(Int(value))"
        }
    }

    private func storeCard(_ store: Store) -> some View {
        let mgr = manager(store)
        let perf = stats(store)
        let position = rank(store)

        return ZStack(alignment: .bottom) {

            Group {
                if let url = store.imageURL, !url.isEmpty {
                    CachedStoreImage(urlString: url)
                } else {
                    placeholderBackground
                }
            }
            .frame(width: 300, height: 420)
            .clipped()

            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: Color.black.opacity(0.15), location: 0.3),
                    .init(color: Color.black.opacity(0.68), location: 0.62),
                    .init(color: Color.black.opacity(0.94), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(width: 300, height: 420)

            VStack {
                HStack {
                    if position > 0 {
                        HStack(spacing: 5) {
                            Image(systemName: position == 1 ? "crown.fill" : "number")
                                .font(.system(size: 10, weight: .bold))
                            Text(position == 1 ? "Top" : "\(position)")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(position == 1 ? Color(hex: "3A2A0A") : .white.opacity(0.92))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            position == 1
                                ? AnyShapeStyle(LinearGradient(colors: [Color.nexusGold, Color.nexusGold.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                : AnyShapeStyle(.ultraThinMaterial),
                            in: Capsule()
                        )
                        .environment(\.colorScheme, .dark)
                    }

                    Spacer()

                    HStack(spacing: 5) {
                        Circle()
                            .fill(store.status == .active ? Color(hex: "34C759") : Color.red)
                            .frame(width: 6, height: 6)
                        Text(store.status == .active ? "Active" : "Inactive")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
                    .environment(\.colorScheme, .dark)
                }
                Spacer()
            }
            .padding(14)
            .frame(width: 300, height: 420)

            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(store.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 2)

                    HStack(spacing: 5) {
                        Image(systemName: "location")
                            .font(.system(size: 11, weight: .medium))
                        Text(locationLine(for: store))
                            .font(.system(size: 13, weight: .regular))
                            .lineLimit(1)
                    }
                    .foregroundColor(.white.opacity(0.78))

                    HStack(spacing: 5) {
                        Image(systemName: "person.circle")
                            .font(.system(size: 11, weight: .medium))
                        Text(mgr?.name ?? "Unassigned")
                            .font(.system(size: 13, weight: mgr == nil ? .regular : .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(mgr == nil ? .white.opacity(0.45) : .white.opacity(0.78))
                }

                HStack(spacing: 8) {
                    statPill(icon: "indianrupeesign", value: formattedRevenue(perf.revenue), highlighted: metric == .revenue)
                    statPill(icon: "person.2.fill", value: "\(perf.customers)", highlighted: metric == .customers)
                    statPill(icon: "bag.fill", value: "\(perf.orders)", highlighted: metric == .orders)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 18)
            .frame(width: 300, alignment: .leading)
        }
        .frame(width: 300, height: 420)
        .clipShape(RoundedRectangle(cornerRadius: RSMSRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .stroke(Color.white.opacity(0.07), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.22), radius: 20, x: 0, y: 10)
    }

    private func statPill(icon: String, value: String, highlighted: Bool) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .monospacedDigit()
        }
        .foregroundColor(highlighted ? Color.nexusDark : .white.opacity(0.85))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            highlighted ? AnyShapeStyle(Color.nexusGold) : AnyShapeStyle(.ultraThinMaterial),
            in: Capsule()
        )
        .environment(\.colorScheme, highlighted ? .light : .dark)
    }

    private var placeholderBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "2C1010"),
                    RSMSColors.burgundy.opacity(0.4),
                    Color(hex: "1C1C1E")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .fill(RSMSColors.burgundy.opacity(0.12))
                .frame(width: 200, height: 200)
                .blur(radius: 40)
                .offset(x: 60, y: -30)

            Circle()
                .fill(RSMSColors.burgundy.opacity(0.08))
                .frame(width: 140, height: 140)
                .blur(radius: 30)
                .offset(x: -50, y: 40)
        }
    }
}

#Preview {
    NavigationStack {
        storeDashView()
    }
}
