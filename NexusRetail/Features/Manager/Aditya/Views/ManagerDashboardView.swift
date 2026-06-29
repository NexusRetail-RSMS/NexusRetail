//
//  ManagerDashboardView.swift
//  NexusRetail
//

import SwiftUI

struct ManagerDashboardView: View {
    @State private var viewModel = ManagerDashboardViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Header
                DashboardHeaderView(
                    name: viewModel.managerName
                )
                
                // MARK: - Store Overview
                SectionHeaderView(title: "Store Overview")
                    .padding(.top, RSMSSpacing.sm)
                    .padding(.bottom, -RSMSSpacing.sm)
                    
                    // MARK: - Revenue Card
                    RevenueCardView(
                        revenue: viewModel.todayRevenue,
                        trend: viewModel.revenueTrend,
                        transactions: viewModel.transactions,
                        averageTicket: viewModel.averageTicket,
                        returns: viewModel.returns
                    )
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, RSMSSpacing.sm)
                    
                    // MARK: - KPI Cards
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RSMSSpacing.md) {
                        KPICardView(
                            title: "Products in Stock",
                            value: viewModel.productsInStock,
                            icon: "shippingbox.fill",
                            trend: nil
                        )
                        
                        KPICardView(
                            title: "Low Stock Items",
                            value: viewModel.lowStockItems,
                            icon: "exclamationmark.triangle.fill",
                            trend: nil
                        )
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, RSMSSpacing.md)
                    
                    // MARK: - Revenue Trend Chart
                    ManagerRevenueChartView(
                        data: viewModel.revenueChartData,
                        maxValue: viewModel.revenueMaxValue,
                        sixMonthTotal: viewModel.sixMonthTotal,
                        peakMonth: viewModel.peakMonth,
                        timeRange: $viewModel.timeRange
                    )
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, RSMSSpacing.xl)
                    .padding(.bottom, RSMSSpacing.xxxl)
                }
            }
            .background(RSMSColors.background.ignoresSafeArea())
            .navigationBarHidden(true)
    }
}

#Preview {
    ManagerDashboardView()
}
