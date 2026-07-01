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
    var selectedPeriod: SalesPeriod      = .today
    var selectedChartPeriod: ChartPeriod = .monthly
    var isStatsLoading                   = false

    // MARK: - Data
    var dbOrders: [StoreOrder] = []

    // MARK: - Filtered orders for selected period
    var filteredDbOrders: [StoreOrder] {
        let formatter = ISO8601DateFormatter()
        let now       = Date()
        let calendar  = Calendar.current

        let fallbackFmt = DateFormatter()
        fallbackFmt.dateFormat = "yyyy-MM-dd"
        let todayPrefix = fallbackFmt.string(from: now)

        return dbOrders.filter { order in
            if let date = formatter.date(from: order.createdAt) {
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
        let fmt = NumberFormatter()
        fmt.numberStyle   = .currency
        fmt.currencySymbol = "₹"
        fmt.maximumFractionDigits = 2
        return fmt.string(from: NSNumber(value: total)) ?? "₹\(String(format: "%.2f", total))"
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

    // MARK: - Revenue Chart Data
    var chartDataPoints: [StoreRevenueChartPoint] {
        let formatter = ISO8601DateFormatter()
        let calendar  = Calendar.current
        let now       = Date()

        var points: [StoreRevenueChartPoint] = []

        if selectedChartPeriod == .weekly {
            var weeklyMap: [Int: Double] = [:]
            for i in 1...7 { weeklyMap[i] = 0.0 }

            if let weekRange = calendar.dateInterval(of: .weekOfYear, for: now) {
                for order in dbOrders {
                    if let date = formatter.date(from: order.createdAt), weekRange.contains(date) {
                        let weekday = calendar.component(.weekday, from: date)
                        weeklyMap[weekday, default: 0.0] += order.total
                    }
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
            var map: [String: Double] = [:]
            for i in (0..<6).reversed() {
                if let d = calendar.date(byAdding: .month, value: -i, to: now) {
                    let lbl = monthFmt.string(from: d)
                    labels.append(lbl)
                    map[lbl] = 0.0
                }
            }
            for order in dbOrders {
                if let date = formatter.date(from: order.createdAt) {
                    let lbl = monthFmt.string(from: date)
                    if map[lbl] != nil { map[lbl, default: 0.0] += order.total }
                }
            }
            points = labels.map { StoreRevenueChartPoint(label: $0, revenue: map[$0] ?? 0.0) }
        }

        return points
    }

    var chartMaxValue: Double {
        let maxVal = chartDataPoints.map(\.revenue).max() ?? 100000.0
        return ceil(maxVal / 20000.0) * 20000.0
    }

    // MARK: - Helpers
    func statusColor(for status: String) -> Color {
        switch status {
        case "Completed":       return RSMSColors.success
        case "Pending Payment": return RSMSColors.warning
        default:                return .blue
        }
    }

    // MARK: - Supabase Fetch
    func fetchStoreOrders(storeID: UUID?) async {
        guard let storeID else {
            print("SalesDashboardViewModel: No storeID, skipping fetch")
            return
        }
        isStatsLoading = true

        struct DashboardOrderLineItem: Codable {
            let id: UUID?
            let quantity: Int
        }

        struct DashboardOrder: Codable, Identifiable {
            let id:            UUID
            let clientID:      UUID?
            let storeID:       UUID?
            let associateID:   UUID?
            let total:         Double
            let createdAt:     String
            let orderLineItems: [DashboardOrderLineItem]?

            enum CodingKeys: String, CodingKey {
                case id
                case clientID      = "client_id"
                case storeID       = "store_id"
                case associateID   = "associate_id"
                case total
                case createdAt     = "created_at"
                case orderLineItems = "order_line_item"
            }
        }

        do {
            let fetched: [DashboardOrder] = try await SupabaseManager.shared.client
                .from("orders")
                .select("id, client_id, store_id, associate_id, total, created_at, order_line_item(id, quantity)")
                .eq("store_id", value: storeID)
                .execute()
                .value

            print("SalesDashboardViewModel: Fetched \(fetched.count) orders")

            let converted: [StoreOrder] = fetched.map { dOrder in
                let lineItems = dOrder.orderLineItems?.map { dli in
                    OrderLineItem(id: dli.id, orderID: nil, quantity: dli.quantity, appliedPrice: 0, products: nil)
                }
                return StoreOrder(
                    id: dOrder.id,
                    clientID: dOrder.clientID,
                    storeID: dOrder.storeID,
                    associateID: dOrder.associateID,
                    total: dOrder.total,
                    createdAt: dOrder.createdAt,
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
