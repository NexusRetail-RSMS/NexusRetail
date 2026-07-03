//
//  AfterSalesDashboardViewModel.swift
//  NexusRetail
//

import Foundation
import SwiftUI

@Observable
final class AfterSalesDashboardViewModel {
    
    // UI State
    var selectedChartPeriod: ChartPeriod = .monthly
    
    // Mock Data arrays
    var urgentCases: [ServiceRequest] = []
    var recentActivities: [ServiceActivity] = []
    
    // KPIs
    let pendingServiceRequests: Int = 12
    let repairsInProgress: Int = 8
    let warrantyVerifications: Int = 5
    let returnsAwaitingApproval: Int = 3
    
    init() {
        loadMockData()
    }
    
    private func loadMockData() {
        urgentCases = [
            ServiceRequest(id: UUID(), serviceId: "SR-2034", customerName: "Ananya Rao", issueType: "Repair", priority: .high, daysRemaining: 2, status: .repair),
            ServiceRequest(id: UUID(), serviceId: "SR-2012", customerName: "Vikram Singh", issueType: "Warranty", priority: .high, daysRemaining: 1, status: .pending),
            ServiceRequest(id: UUID(), serviceId: "SR-2045", customerName: "Priya Desai", issueType: "Return", priority: .medium, daysRemaining: 4, status: .pending)
        ]
        
        recentActivities = [
            ServiceActivity(id: UUID(), statusIcon: "checkmark.shield.fill", statusText: "Warranty Verified", customerName: "Rajesh Kumar", serviceId: "SR-2015", time: "10 mins ago", iconColor: RSMSColors.success),
            ServiceActivity(id: UUID(), statusIcon: "wrench.and.screwdriver.fill", statusText: "Repair Completed", customerName: "Sunita Patel", serviceId: "SR-1998", time: "1 hour ago", iconColor: RSMSColors.primaryText),
            ServiceActivity(id: UUID(), statusIcon: "arrow.uturn.backward.circle.fill", statusText: "Return Approved", customerName: "Amit Sharma", serviceId: "SR-2021", time: "3 hours ago", iconColor: RSMSColors.burgundy),
            ServiceActivity(id: UUID(), statusIcon: "bell.fill", statusText: "Customer Notified", customerName: "Kavita Reddy", serviceId: "SR-2005", time: "Yesterday", iconColor: RSMSColors.warning),
            ServiceActivity(id: UUID(), statusIcon: "arrow.triangle.2.circlepath", statusText: "Exchange Initiated", customerName: "Neha Gupta", serviceId: "SR-2044", time: "Yesterday", iconColor: Color(hex: "2A9D8F"))
        ]
    }
    
    // Chart Data
    var serviceRequestChartData: [ServiceChartDataPoint] {
        if selectedChartPeriod == .weekly {
            return [
                ServiceChartDataPoint(label: "Mon", value: 12),
                ServiceChartDataPoint(label: "Tue", value: 18),
                ServiceChartDataPoint(label: "Wed", value: 15),
                ServiceChartDataPoint(label: "Thu", value: 24),
                ServiceChartDataPoint(label: "Fri", value: 30),
                ServiceChartDataPoint(label: "Sat", value: 45),
                ServiceChartDataPoint(label: "Sun", value: 20)
            ]
        } else {
            return [
                ServiceChartDataPoint(label: "Jan", value: 120),
                ServiceChartDataPoint(label: "Feb", value: 145),
                ServiceChartDataPoint(label: "Mar", value: 130),
                ServiceChartDataPoint(label: "Apr", value: 160),
                ServiceChartDataPoint(label: "May", value: 185),
                ServiceChartDataPoint(label: "Jun", value: 210)
            ]
        }
    }
    
    var serviceStatusChartData: [ServiceChartDataPoint] {
        return [
            ServiceChartDataPoint(label: "Pending", value: 15),
            ServiceChartDataPoint(label: "Repair", value: 35),
            ServiceChartDataPoint(label: "Completed", value: 40),
            ServiceChartDataPoint(label: "Returned", value: 10)
        ]
    }
    
    var totalServiceRequests: Int {
        return Int(serviceStatusChartData.reduce(0) { $0 + $1.value })
    }
}
