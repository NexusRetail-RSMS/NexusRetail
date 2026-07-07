//
//  SalesModels.swift
//  NexusRetail
//
//  Shared value types and enums for the SalesAssociate feature.
//

import Foundation

// MARK: - Navigation

enum POSFlowDestination: Hashable {
    case newSale
    case searchProduct
    case barcodeScanner
    case cart
    case checkout
    case payment
    case receipt
    case bopis
    case ordersHub
    
    // After Sales Flow
    case invoiceScanner
    case invoiceItemsSelection(invoiceId: String)
    case actionSelection(invoiceId: String, selectedItem: POSProduct)
    case repairForm(invoiceId: String, selectedItem: POSProduct, isUnderWarranty: Bool)
}

// MARK: - Chart / Period

enum SalesPeriod: String {
    case today = "Today"
    case week  = "This Week"
    case month = "This Month"
}

enum ChartPeriod: String, CaseIterable, Identifiable {
    case weekly  = "Weekly"
    case monthly = "Monthly"
    var id: String { rawValue }
}

enum RevenueFilter: String, CaseIterable, Identifiable {
    case week
    case month

    var id: String { rawValue }
    var title: String { self == .week ? "Weekly" : "Monthly" }
}

// MARK: - Dashboard chart data point

struct StoreRevenueChartPoint: Identifiable {
    var id: String { label }
    let label: String
    let revenue: Double
}

// MARK: - Legacy sample data for old Dashboard tab (kept for backward compat)

struct RevenuePoint: Identifiable {
    var id: String { label }
    let label: String
    let value: Double
}

struct SalesSummaryCard: Identifiable {
    let id       = UUID()
    let title:    String
    let subtitle: String
    let value:    String
    let icon:     String
}
