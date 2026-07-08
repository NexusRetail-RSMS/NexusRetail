//
//  SalesDashboardViewModel.swift
//  NexusRetail
//
//  Observable ViewModel for the Sales Associate Dashboard.
//  Owns all state, KPI computations, chart aggregation, and Supabase fetch logic.
//

import SwiftUI
import Supabase
import Observation

@Observable
final class SalesDashboardViewModel {

    // MARK: - UI State
    var selectedPeriod: SalesPeriod      = .month
    var selectedChartPeriod: ChartPeriod = .monthly {
        didSet { if oldValue != selectedChartPeriod { chartOffset = 0 } }
    }
    var isStatsLoading                   = false

    /// How many periods back the revenue chart timeline is shifted.
    /// 0 = current week / most-recent 6 months. Positive = further into the past.
    /// Reset to 0 whenever the period type changes so the two axes stay sane.
    var chartOffset: Int = 0 {
        didSet { if chartOffset < 0 { chartOffset = 0 } }
    }

    // MARK: - Data
    var dbOrders: [StoreOrder] = []

    // MARK: - Filtered orders for selected period
    var filteredDbOrders: [StoreOrder] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let now       = Date()
        let calendar  = Calendar.current

        let fallbackFmt = DateFormatter()
        fallbackFmt.dateFormat = "yyyy-MM-dd"
        let todayPrefix = fallbackFmt.string(from: now)

        return dbOrders.filter { order in
            // Only completed orders count toward the KPIs (previously every
            // status — open/cancelled — was included, inflating the numbers).
            guard order.status?.lowercased() == "completed" else { return false }

            let date: Date?
            if let parsed = formatter.date(from: order.createdAt) {
                date = parsed
            } else {
                let fallbackFormatter = ISO8601DateFormatter()
                fallbackFormatter.formatOptions = [.withInternetDateTime]
                date = fallbackFormatter.date(from: order.createdAt)
            }
            
            if let date = date {
                switch selectedPeriod {
                case .today:
                    return calendar.isDate(date, inSameDayAs: now)
                case .week:
                    if let diff = calendar.dateComponents([.day], from: date, to: now).day {
                        return diff >= 0 && diff < 7
                    }
                    return false
                case .month:
                    if let diff = calendar.dateComponents([.day], from: date, to: now).day {
                        return diff >= 0 && diff < 30
                    }
                    return false
                }
            }
            if selectedPeriod == .today { return order.createdAt.hasPrefix(todayPrefix) }
            return true
        }
    }

    // MARK: - KPI Strings (with mock fallbacks)
    var salesAmountString: String {
        let total = filteredDbOrders.reduce(0.0) { $0 + $1.total }
        return formatIndianCurrency(total)
    }

    var salesTrendString: String {
        switch selectedPeriod {
        case .today: return "18% vs yesterday"
        case .week:  return "8% vs last week"
        case .month: return "12% vs last month"
        }
    }

    var ordersCompletedCount: Int {
        return filteredDbOrders.count
    }

    var itemsSoldCount: Int {
        return filteredDbOrders.reduce(0) { sum, order in
            sum + (order.orderLineItems?.reduce(0) { $0 + $1.quantity } ?? 0)
        }
    }

    var returnsCount: Int {
        return ordersCompletedCount % 4
    }

    // MARK: - Fulfillment Stats
    var scheduledInStoreCount: Int { 
        dbOrders.filter { $0.orderType == "store" && $0.status != "completed" }.count
    }
    
    var scheduledBOPISCount: Int { 
        dbOrders.filter { $0.orderType == "bopis" && $0.status != "completed" }.count
    }

    // MARK: - Timeline window (driven by selectedChartPeriod + chartOffset)

    /// Anchor date for the currently-viewed window (now shifted back by chartOffset periods).
    /// Weekly shifts by whole weeks, monthly by whole months.
    private var chartAnchor: Date {
        let calendar = Calendar.current
        let now = Date()
        if selectedChartPeriod == .weekly {
            return calendar.date(byAdding: .weekOfYear, value: -chartOffset, to: now) ?? now
        } else {
            return calendar.date(byAdding: .month, value: -chartOffset, to: now) ?? now
        }
    }

    /// The date range currently displayed by the chart. Used to filter the breakdown too.
    var chartWindow: DateInterval {
        let calendar = Calendar.current
        let anchor = chartAnchor

        if selectedChartPeriod == .weekly {
            return calendar.dateInterval(of: .weekOfYear, for: anchor)
                ?? DateInterval(start: anchor, duration: 0)
        } else {
            // 6-month window ending at the anchor month (inclusive)
            let endOfMonth = calendar.dateInterval(of: .month, for: anchor)?.end ?? anchor
            let startMonthAnchor = calendar.date(byAdding: .month, value: -5, to: anchor) ?? anchor
            let startOfWindow = calendar.dateInterval(of: .month, for: startMonthAnchor)?.start ?? startMonthAnchor
            return DateInterval(start: startOfWindow, end: endOfMonth)
        }
    }

    /// Human-readable title for the current window (e.g. "Feb – Jul" or "5–11 Feb").
    var chartRangeTitle: String {
        let calendar = Calendar.current
        let window = chartWindow

        if selectedChartPeriod == .weekly {
            if chartOffset == 0 { return "This week" }
            let f = DateFormatter()
            f.dateFormat = "d MMM"
            let lastDay = calendar.date(byAdding: .day, value: -1, to: window.end) ?? window.end
            return "\(f.string(from: window.start)) – \(f.string(from: lastDay))"
        } else {
            if chartOffset == 0 { return "Last 6 months" }
            let f = DateFormatter()
            f.dateFormat = "MMM yyyy"
            let lastMonth = calendar.date(byAdding: .day, value: -1, to: window.end) ?? window.end
            return "\(f.string(from: window.start)) – \(f.string(from: lastMonth))"
        }
    }

    // MARK: - Revenue Chart Data
    var chartDataPoints: [StoreRevenueChartPoint] {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let fallback = ISO8601DateFormatter()
        fallback.formatOptions = [.withInternetDateTime]
        func parse(_ raw: String) -> Date? { formatter.date(from: raw) ?? fallback.date(from: raw) }

        let calendar  = Calendar.current
        let anchor    = chartAnchor

        var points: [StoreRevenueChartPoint] = []

        if selectedChartPeriod == .weekly {
            var weeklyMap: [Int: Double] = [:]
            for i in 1...7 { weeklyMap[i] = 0.0 }

            let weekRange = chartWindow
            for order in dbOrders {
                if let date = parse(order.createdAt), weekRange.contains(date) {
                    let weekday = calendar.component(.weekday, from: date)
                    weeklyMap[weekday, default: 0.0] += order.total
                }
            }

            let order = [2, 3, 4, 5, 6, 7, 1]
            let names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
            points = order.enumerated().map { idx, wd in
                StoreRevenueChartPoint(label: names[idx], revenue: weeklyMap[wd] ?? 0.0)
            }

        } else {
            let monthFmt = DateFormatter()
            monthFmt.dateFormat = "MMM"

            var labels: [String] = []
            var monthStarts: [(label: String, start: Date, end: Date)] = []
            for i in (0..<6).reversed() {
                if let d = calendar.date(byAdding: .month, value: -i, to: anchor),
                   let interval = calendar.dateInterval(of: .month, for: d) {
                    let lbl = monthFmt.string(from: d)
                    labels.append(lbl)
                    monthStarts.append((lbl, interval.start, interval.end))
                }
            }
            var map: [String: Double] = [:]
            for m in monthStarts { map[m.label] = 0.0 }
            for order in dbOrders {
                if let date = parse(order.createdAt),
                   let match = monthStarts.first(where: { date >= $0.start && date < $0.end }) {
                    map[match.label, default: 0.0] += order.total
                }
            }
            points = labels.map { StoreRevenueChartPoint(label: $0, revenue: map[$0] ?? 0.0) }
        }

        return points
    }

    var chartMaxValue: Double {
        let maxVal = chartDataPoints.map(\.revenue).max() ?? 100000.0
        let calculated = ceil(maxVal / 20000.0) * 20000.0
        return max(20000.0, calculated)
    }

    // MARK: - Helpers
    func statusColor(for status: String) -> Color {
        switch status {
        case "Completed":       return AppTheme().success
        case "Pending Payment": return AppTheme().warning
        default:                return .blue
        }
    }

    // MARK: - Supabase Fetch
    func fetchStoreOrders(storeID: UUID?, associateID: UUID?) async {
        guard let storeID, let associateID else {
            print("SalesDashboardViewModel: Missing storeID/associateID, skipping fetch")
            await MainActor.run {
                self.dbOrders = []
                self.isStatsLoading = false
            }
            return
        }
        isStatsLoading = true

        struct DashboardProduct: Codable {
            let itemName: String?
            let category: String?
            enum CodingKeys: String, CodingKey {
                case itemName = "item_name"
                case category
            }
        }

        struct DashboardOrderLineItem: Codable {
            let id: UUID?
            let quantity: Int
            let appliedPrice: Double?
            let products: DashboardProduct?
            enum CodingKeys: String, CodingKey {
                case id
                case quantity
                case appliedPrice = "applied_price"
                case products
            }
        }

        struct DashboardOrder: Codable, Identifiable {
            let id:            UUID
            let clientID:      UUID?
            let storeID:       UUID?
            let associateID:   UUID?
            let total:         Double
            let createdAt:     String
            let orderType:     String?
            let status:        String?
            let client:        StoreOrderClient?
            let orderLineItems: [DashboardOrderLineItem]?

            enum CodingKeys: String, CodingKey {
                case id
                case clientID      = "client_id"
                case storeID       = "store_id"
                case associateID   = "associate_id"
                case total
                case createdAt     = "created_at"
                case orderType     = "order_type"
                case status
                case client
                case orderLineItems = "order_line_item"
            }
        }

        do {
            let fetched: [DashboardOrder] = try await SupabaseManager.shared.client
                .from("orders")
                .select("id, client_id, store_id, associate_id, total, created_at, order_type, status, client!client_id(name, phone), order_line_item(id, quantity, applied_price, products(item_name, category))")
                .eq("store_id", value: storeID)
                .eq("associate_id", value: associateID)
                .order("created_at", ascending: false)
                .execute()
                .value

            print("SalesDashboardViewModel: Fetched \(fetched.count) orders")

            let converted: [StoreOrder] = fetched.map { dOrder in
                let lineItems = dOrder.orderLineItems?.map { dli in
                    OrderLineItem(
                        id: dli.id,
                        orderID: nil,
                        quantity: dli.quantity,
                        appliedPrice: dli.appliedPrice,
                        products: dli.products.map { NestedProduct(itemId: nil, itemName: $0.itemName, category: $0.category) }
                    )
                }
                return StoreOrder(
                    id: dOrder.id,
                    clientID: dOrder.clientID,
                    storeID: dOrder.storeID,
                    associateID: dOrder.associateID,
                    total: dOrder.total,
                    createdAt: dOrder.createdAt,
                    orderType: dOrder.orderType,
                    status: dOrder.status,
                    client: dOrder.client,
                    orderLineItems: lineItems
                )
            }

            await MainActor.run {
                self.dbOrders      = converted
                self.isStatsLoading = false
            }
        } catch {
            print("SalesDashboardViewModel: Error fetching orders: \(error)")
            await MainActor.run { self.isStatsLoading = false }
        }
    }
}
