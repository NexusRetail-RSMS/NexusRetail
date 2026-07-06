import Foundation
import SwiftUI
import Supabase

enum SalesTimeRange: String, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
}

struct RevenueChartPoint: Identifiable, Equatable {
    var id: String { label }
    let label: String
    let index: Int
    let revenue: Double

    static func == (lhs: RevenueChartPoint, rhs: RevenueChartPoint) -> Bool {
        lhs.label == rhs.label && lhs.revenue == rhs.revenue
    }
}

struct ProductChartPoint: Identifiable, Equatable {
    var id: String { name }
    let name: String
    let category: String
    let sales: Int
    var imageURL: URL? = nil

    static func == (lhs: ProductChartPoint, rhs: ProductChartPoint) -> Bool {
        lhs.name == rhs.name && lhs.sales == rhs.sales
    }
}

@Observable
class DashboardViewModel {

    var kpis: DashboardKPIs?
    var monthly: [MonthlyRevenue] = []
    var weekly: [WeeklyRevenue] = []
    var byCountry: [CountryRevenue] = []
    var topProductsWeekly: [DashboardTopProduct] = []
    var topProductsMonthly: [DashboardTopProduct] = []

    var isLoading = false
    var errorMessage: String?

    var selectedCountry: String? = nil {
        didSet {
            Task {
                await load()
            }
        }
    }

    var countries: [String] {
        byCountry.map(\.country).sorted()
    }

    var displayCountry: String {
        selectedCountry ?? "All Global"
    }

    var revenueTimeRange: SalesTimeRange = .monthly
    var productTimeRange: SalesTimeRange = .monthly

    var formattedRevenue: String {
        guard let total = kpis?.totalRevenue else { return "₹0" }
        return formatIndianCurrency(total)
    }

    var activeStoresText: String {
        "\(kpis?.activeStores ?? 0)"
    }

    var pendingTransfersText: String {
        "\(kpis?.pendingTransfers ?? 0)"
    }

    var lowStockText: String {
        "\(kpis?.lowStockAlerts ?? 0)"
    }

    var revenueChartData: [RevenueChartPoint] {
        if revenueTimeRange == .weekly {
            return weekly.enumerated().map { index, point in
                let parts = point.week.split(separator: "-")
                let label = parts.count == 2 ? "W\(parts[1])" : point.week
                return RevenueChartPoint(
                    label: label,
                    index: index,
                    revenue: point.revenue / 100000.0
                )
            }.suffix(8)
        } else {
            return monthly.enumerated().map { index, point in
                let label: String
                let parts = point.month.split(separator: "-")
                if parts.count == 2, let monthNum = Int(parts[1]) {
                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "en_US")
                    label = formatter.shortMonthSymbols[monthNum - 1]
                } else {
                    label = point.month
                }

                return RevenueChartPoint(
                    label: label,
                    index: index,
                    revenue: point.revenue / 100000.0
                )
            }.suffix(12)
        }
    }

    var revenueMaxValue: Double {
        let maxRev = revenueChartData.map(\.revenue).max() ?? 100
        return ceil(maxRev / 50) * 50
    }

    var yearlyRevenuePoints: [Double] {
        monthly.sorted { $0.month < $1.month }.map { $0.revenue / 100000.0 }
    }

    var yearlyRevenueTrendText: String {
        let points = yearlyRevenuePoints
        guard let first = points.first, let last = points.last, first != 0 else { return "" }
        let change = ((last - first) / first) * 100
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.0f", change))%"
    }

    var productChartData: [ProductChartPoint] {
        let sourceData = productTimeRange == .weekly ? topProductsWeekly : topProductsMonthly

        return sourceData.map { product in
            let url = product.imageUrl.flatMap { URL(string: $0) }
            return ProductChartPoint(name: product.name, category: product.category, sales: product.units, imageURL: url)
        }
        .sorted { $0.sales > $1.sales }
    }

    var productMaxValue: Int {
        let maxVal = productChartData.map(\.sales).max() ?? 100
        return ((maxVal / 50) + 1) * 50
    }

    struct DashboardRPCParams: Encodable {
        let p_country: String?
    }

    struct TopProductsRPCParams: Encodable {
        let p_period: String
        let p_limit: Int
        let p_country: String?
    }

    @MainActor
    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            let params = DashboardRPCParams(p_country: selectedCountry)
            let weekParams = TopProductsRPCParams(p_period: "week", p_limit: 20, p_country: selectedCountry)
            let monthParams = TopProductsRPCParams(p_period: "month", p_limit: 20, p_country: selectedCountry)

            async let kpisTask: DashboardKPIs = SupabaseManager.shared.client
                .rpc("dashboard_kpis", params: params).execute().value

            async let monthlyTask: [MonthlyRevenue] = SupabaseManager.shared.client
                .rpc("revenue_by_month", params: params).execute().value

            async let weeklyTask: [WeeklyRevenue] = SupabaseManager.shared.client
                .rpc("revenue_by_week", params: params).execute().value

            async let countryTask: [CountryRevenue] = SupabaseManager.shared.client
                .rpc("revenue_by_country").execute().value

            async let topWeeklyTask: [DashboardTopProduct] = SupabaseManager.shared.client
                .rpc("top_products", params: weekParams).execute().value

            async let topMonthlyTask: [DashboardTopProduct] = SupabaseManager.shared.client
                .rpc("top_products", params: monthParams).execute().value

            self.kpis = try await kpisTask
            self.monthly = try await monthlyTask
            self.weekly = try await weeklyTask
            self.byCountry = try await countryTask
            self.topProductsWeekly = try await topWeeklyTask
            self.topProductsMonthly = try await topMonthlyTask

        } catch {
            self.errorMessage = "Failed to load dashboard data: \(error.localizedDescription)"
            print("Dashboard Error: \(error)")
        }

        isLoading = false
    }
}
