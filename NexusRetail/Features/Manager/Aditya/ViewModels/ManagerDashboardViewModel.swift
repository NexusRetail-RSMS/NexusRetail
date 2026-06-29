//
//  ManagerDashboardViewModel.swift
//  NexusRetail
//

import SwiftUI
import Observation

@Observable
final class ManagerDashboardViewModel {
    
    // MARK: - Properties
    
    var timeRange: ManagerSalesTimeRange = .weekly
    
    // MARK: - Mock Data
    
    let managerName = "Alex"
    let storeName = "Jewellery Store, Indiranagar"
    
    let todayRevenue = "₹1,25,000"
    let revenueTrend = "+12.4%"
    
    let transactions = "42"
    let averageTicket = "₹2,976"
    let returns = "2"
    
    let productsInStock = "3,450"
    let productsInStockTrend = "+12"
    
    let lowStockItems = "18"
    let lowStockTrend = "+3"
    
    var sixMonthTotal: String {
        timeRange == .weekly ? "₹12.2L" : "₹84.5L"
    }
    
    var peakMonth: String {
        timeRange == .weekly ? "Sat" : "Jun"
    }
    
    // Chart Data
    var revenueChartData: [ManagerRevenueChartPoint] {
        switch timeRange {
        case .weekly:
            return [
                ManagerRevenueChartPoint(label: "Mon", revenue: 1.2),
                ManagerRevenueChartPoint(label: "Tue", revenue: 1.5),
                ManagerRevenueChartPoint(label: "Wed", revenue: 1.1),
                ManagerRevenueChartPoint(label: "Thu", revenue: 1.8),
                ManagerRevenueChartPoint(label: "Fri", revenue: 2.1),
                ManagerRevenueChartPoint(label: "Sat", revenue: 2.5),
                ManagerRevenueChartPoint(label: "Sun", revenue: 2.0)
            ]
        case .monthly:
            return [
                ManagerRevenueChartPoint(label: "Jan", revenue: 12.5),
                ManagerRevenueChartPoint(label: "Feb", revenue: 14.0),
                ManagerRevenueChartPoint(label: "Mar", revenue: 11.2),
                ManagerRevenueChartPoint(label: "Apr", revenue: 15.6),
                ManagerRevenueChartPoint(label: "May", revenue: 13.4),
                ManagerRevenueChartPoint(label: "Jun", revenue: 16.8)
            ]
        }
    }
    
    var revenueMaxValue: Double {
        timeRange == .weekly ? 3.0 : 20.0
    }
}
