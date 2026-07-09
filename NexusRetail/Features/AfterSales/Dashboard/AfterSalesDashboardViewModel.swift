//
//  AfterSalesDashboardViewModel.swift
//  NexusRetail
//
//  Real, DB-backed dashboard for the After-Sales specialist. Reads tickets from
//  `after_sales_ticket` (scoped to the specialist's store by RLS) and derives
//  KPIs + charts. No mock data.
//

import Foundation
import SwiftUI
import Supabase

private struct AfterSalesTicketRow: Decodable {
    let id: UUID
    let type: String
    let stage: String
    let createdAt: Date
    let serviceCost: Double?
    let itemName: String?
    let warrantyStatus: String?

    enum CodingKeys: String, CodingKey {
        case id, type, stage
        case createdAt = "created_at"
        case serviceCost = "service_cost"
        case itemName = "item_name"
        case warrantyStatus = "warranty_status"
    }
}

@Observable
final class AfterSalesDashboardViewModel {

    // UI State
    var selectedChartPeriod: ChartPeriod = .monthly
    var isLoading = false

    // Live tickets
    private var tickets: [AfterSalesTicketRow] = []

    // KPIs (derived from real tickets)
    var pendingServiceRequests: Int = 0
    var completedServices: Int = 0
    var repairsInProgress: Int = 0
    var warrantyVerifications: Int = 0
    var returnsAwaitingApproval: Int = 0

    // MARK: - Fetch

    @MainActor
    func fetch(storeID: UUID?) async {
        isLoading = true
        defer { isLoading = false }
        do {
            var query = SupabaseManager.shared.client
                .from("after_sales_ticket")
                .select("id, type, stage, created_at, service_cost, item_name, warranty_status")

            if let storeID {
                query = query.eq("store_id", value: storeID.uuidString)
            }

            let rows: [AfterSalesTicketRow] = try await query
                .order("created_at", ascending: false)
                .execute()
                .value

            self.tickets = rows
            recomputeKPIs()
        } catch {
            print("After Sales dashboard fetch error: \(error)")
        }
    }

    private func recomputeKPIs() {
        pendingServiceRequests = tickets.filter { $0.stage != "completed" }.count
        completedServices = tickets.filter { $0.stage == "completed" }.count
        repairsInProgress = tickets.filter { $0.type == "repair" && ($0.stage == "in_repair" || $0.stage == "qa_check") }.count
        warrantyVerifications = tickets.filter { $0.warrantyStatus == "active" }.count
        returnsAwaitingApproval = tickets.filter { $0.type == "exchange" || $0.type == "return" }.count
    }

    // MARK: - Charts

    /// Trend: number of tickets per period bucket (weekly = last 7 days, else last 6 months).
    var serviceRequestChartData: [ServiceChartDataPoint] {
        let calendar = Calendar.current
        let now = Date()

        if selectedChartPeriod == .weekly {
            let dayFmt = DateFormatter(); dayFmt.dateFormat = "EEE"
            var points: [ServiceChartDataPoint] = []
            for offset in stride(from: 6, through: 0, by: -1) {
                guard let day = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
                let count = tickets.filter { calendar.isDate($0.createdAt, inSameDayAs: day) }.count
                points.append(ServiceChartDataPoint(label: dayFmt.string(from: day), value: Double(count)))
            }
            return points
        } else {
            let monthFmt = DateFormatter(); monthFmt.dateFormat = "MMM"
            var points: [ServiceChartDataPoint] = []
            for offset in stride(from: 5, through: 0, by: -1) {
                guard let month = calendar.date(byAdding: .month, value: -offset, to: now) else { continue }
                let comps = calendar.dateComponents([.year, .month], from: month)
                let count = tickets.filter {
                    let c = calendar.dateComponents([.year, .month], from: $0.createdAt)
                    return c.year == comps.year && c.month == comps.month
                }.count
                points.append(ServiceChartDataPoint(label: monthFmt.string(from: month), value: Double(count)))
            }
            return points
        }
    }

    /// Donut breakdown by service stage/type.
    var serviceStatusChartData: [ServiceChartDataPoint] {
        let pending = tickets.filter { $0.stage == "received" }.count
        let repair = tickets.filter { $0.stage == "in_repair" || $0.stage == "qa_check" }.count
        let completed = tickets.filter { $0.stage == "completed" }.count
        let returned = tickets.filter { $0.type == "exchange" || $0.type == "return" }.count

        return [
            ServiceChartDataPoint(label: "Pending", value: Double(pending)),
            ServiceChartDataPoint(label: "Repair", value: Double(repair)),
            ServiceChartDataPoint(label: "Completed", value: Double(completed)),
            ServiceChartDataPoint(label: "Returned", value: Double(returned))
        ]
    }

    var totalServiceRequests: Int {
        tickets.count
    }
}
