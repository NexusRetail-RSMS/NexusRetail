//
//  ManagerDashboardViewModel.swift
//  NexusRetail
//

import SwiftUI
import Observation

struct StaffPerformancePoint: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let score: Int
}

@Observable
final class ManagerDashboardViewModel {
    
    // MARK: - Properties
    
    // Toggles for the main dashboard charts
    var topProductsTimeRange: SalesTimeRange = .monthly
    var staffTimeRange: SalesTimeRange = .monthly
    
    // MARK: - Mock Data
    
    let managerName = "Alex"
    let storeName = "Jewellery Store, Indiranagar"
    
    // New KPI Metrics
    let todayRevenue = "₹1.25L"
    let pendingRequests = "5"
    let lowStockItems = "18"
    let todayReturns = "2"
    
    // Detail Chart Data (Revenue History)
    var sixMonthTotal: String {
        "₹12.2L"
    }
    
    var peakMonth: String {
        "Sat"
    }
    
    var revenueChartData: [ManagerRevenueChartPoint] {
        return [
            ManagerRevenueChartPoint(label: "Mon", revenue: 1.2),
            ManagerRevenueChartPoint(label: "Tue", revenue: 1.5),
            ManagerRevenueChartPoint(label: "Wed", revenue: 1.1),
            ManagerRevenueChartPoint(label: "Thu", revenue: 1.8),
            ManagerRevenueChartPoint(label: "Fri", revenue: 2.1),
            ManagerRevenueChartPoint(label: "Sat", revenue: 2.5),
            ManagerRevenueChartPoint(label: "Sun", revenue: 2.0)
        ]
    }
    
    var revenueMaxValue: Double {
        3.0
    }
    
    // Main Dashboard Charts Data
    
    var topProductsData: [ProductChartPoint] {
        let isQuarterly = topProductsTimeRange == .quarterly
        if isQuarterly {
            return [
                ProductChartPoint(category: "Jewelry", sales: 420),
                ProductChartPoint(category: "Watches", sales: 380),
                ProductChartPoint(category: "Accessories", sales: 310),
                ProductChartPoint(category: "Leather", sales: 250)
            ]
        } else {
            return [
                ProductChartPoint(category: "Jewelry", sales: 150),
                ProductChartPoint(category: "Watches", sales: 130),
                ProductChartPoint(category: "Accessories", sales: 90),
                ProductChartPoint(category: "Leather", sales: 75)
            ]
        }
    }
    
    var topProductsMaxValue: Int {
        topProductsTimeRange == .quarterly ? 500 : 200
    }
    
    var staffPerformanceData: [StaffPerformancePoint] {
        let isQuarterly = staffTimeRange == .quarterly
        if isQuarterly {
            return [
                StaffPerformancePoint(name: "Aman", score: 95),
                StaffPerformancePoint(name: "Priya", score: 88),
                StaffPerformancePoint(name: "Rahul", score: 82),
                StaffPerformancePoint(name: "Sneha", score: 78)
            ]
        } else {
            return [
                StaffPerformancePoint(name: "Aman", score: 92),
                StaffPerformancePoint(name: "Priya", score: 85),
                StaffPerformancePoint(name: "Rahul", score: 80),
                StaffPerformancePoint(name: "Sneha", score: 75)
            ]
        }
    }
}
