//
//  ManagerDashboardModels.swift
//  NexusRetail
//

import Foundation

/// Defines the time range for sales data in the manager dashboard
enum ManagerSalesTimeRange: String, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly"
}

struct ManagerRevenueChartPoint: Identifiable, Equatable {
    var id: String { label }
    let label: String
    let revenue: Double
}
