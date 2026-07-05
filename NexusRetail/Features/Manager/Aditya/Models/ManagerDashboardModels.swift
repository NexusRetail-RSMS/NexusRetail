//
//  ManagerDashboardModels.swift
//  NexusRetail
//

import Foundation

/// Defines the time range for sales data in the manager dashboard
// ManagerSalesTimeRange removed in favor of unified SalesTimeRange


struct ManagerRevenueChartPoint: Identifiable, Equatable {
    var id: String { label }
    let label: String
    let revenue: Double
}
