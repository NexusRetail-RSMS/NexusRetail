//
//  ManagerDashboardView.swift
//  NexusRetail
//

import SwiftUI

struct ManagerDashboardView: View {
    @State private var viewModel = ManagerDashboardViewModel()
    @Environment(SessionStore.self) private var sessionStore
    
    // Presentation States
    @State private var isProfilePresented = false
    @State private var isShowingRevenueDetail = false
    @State private var isShowingRequestsDetail = false
    @State private var isShowingLowStockDetail = false
    @State private var isShowingReturnsDetail = false
    @State private var selectedRange: StoreChartTimeRange = .monthly(Date())
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: RSMSSpacing.xl) {
                // MARK: - Header
                headerSection
                    .padding(.top, RSMSSpacing.sm)
                
                // MARK: - KPI Cards
                kpiSection
                
                // MARK: - Top Product Sales
                ProductSalesChart(
                    data: viewModel.topProductsData,
                    maxValue: viewModel.topProductsMaxValue,
                    timeRange: $viewModel.topProductsTimeRange
                )
                
                // MARK: - Staff Performance
                StaffPerformanceChart(
                    data: viewModel.staffPerformanceData,
                    timeRange: $viewModel.staffTimeRange
                )
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.bottom, RSMSSpacing.xxxl)
        }
        .background(RSMSColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $isProfilePresented) {
            // Reusing a profile placeholder or you can implement ManagerProfileSheet
            Text("Manager Profile")
                .font(.title)
                .presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: $isShowingRevenueDetail) {
            NavigationStack {
                ZStack {
                    RSMSColors.background.ignoresSafeArea()
                    VStack {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sales Report")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(RSMSColors.primaryText)
                                Text("Total: \(viewModel.sixMonthTotal)")
                                    .font(.system(size: 14))
                                    .foregroundColor(RSMSColors.secondaryText)
                            }
                            Spacer()
                            Menu {
                                Button("Weekly") { selectedRange = .weekly(Date()) }
                                Button("Monthly") { selectedRange = .monthly(Date()) }
                                Button("Yearly") { selectedRange = .yearly(Date()) }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(selectedRange.isWeekly ? "Weekly" : selectedRange.isMonthly ? "Monthly" : "Yearly")
                                        .font(.system(size: 14, weight: .medium))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(16)
                                .foregroundColor(RSMSColors.primaryText)
                            }
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.top, RSMSSpacing.lg)
                        
                        SwipeableCalendarView(selectedRange: $selectedRange)
                            .padding(.top, 4)
                        
                        ManagerRevenueChartView(
                            data: viewModel.revenueChartData,
                            maxValue: viewModel.revenueMaxValue,
                            sixMonthTotal: viewModel.sixMonthTotal,
                            peakMonth: viewModel.peakMonth,
                            timeRange: .constant(.weekly) // Fixed to weekly for now
                        )
                        .padding()
                        Spacer()
                    }
                }
                .navigationTitle("Revenue History")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { isShowingRevenueDetail = false }) {
                            Image(systemName: "xmark")
                                .foregroundColor(RSMSColors.primaryText)
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isShowingRequestsDetail) {
            NavigationStack {
                ZStack {
                    RSMSColors.background.ignoresSafeArea()
                    VStack {
                        SwipeableCalendarView(selectedRange: $selectedRange)
                            .padding(.top)
                        ManagerPlaceholderView(title: "Pending Requests History", message: "Chart or list for Pending Requests over time.", icon: "doc.text.fill")
                        Spacer()
                    }
                }
                .navigationTitle("Requests")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { isShowingRequestsDetail = false }) {
                            Image(systemName: "xmark")
                                .foregroundColor(RSMSColors.primaryText)
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isShowingLowStockDetail) {
            NavigationStack {
                ZStack {
                    RSMSColors.background.ignoresSafeArea()
                    VStack {
                        SwipeableCalendarView(selectedRange: $selectedRange)
                            .padding(.top)
                        ManagerPlaceholderView(title: "Low Stock Items", message: "List of items currently low in stock.", icon: "exclamationmark.triangle.fill")
                        Spacer()
                    }
                }
                .navigationTitle("Low Stock")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { isShowingLowStockDetail = false }) {
                            Image(systemName: "xmark")
                                .foregroundColor(RSMSColors.primaryText)
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isShowingReturnsDetail) {
            NavigationStack {
                ZStack {
                    RSMSColors.background.ignoresSafeArea()
                    VStack {
                        SwipeableCalendarView(selectedRange: $selectedRange)
                            .padding(.top)
                        ManagerPlaceholderView(title: "Returns History", message: "Chart or list for Returns over time.", icon: "arrow.uturn.left")
                        Spacer()
                    }
                }
                .navigationTitle("Returns")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { isShowingReturnsDetail = false }) {
                            Image(systemName: "xmark")
                                .foregroundColor(RSMSColors.primaryText)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(RSMSColors.primaryText)

            Spacer()

            // Profile avatar
            Button {
                isProfilePresented = true
            } label: {
                ZStack {
                    Circle()
                        .fill(RSMSColors.burgundy)
                        .frame(width: 44, height: 44)

                    Text(initials(for: sessionStore.currentUser?.name ?? viewModel.managerName))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .accessibilityLabel("Profile")
            .accessibilityHint("Opens your profile and settings")
        }
    }
    
    // MARK: - KPI Section
    private var kpiSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RSMSSpacing.md) {
            KPICardView(title: "Today's Revenue", value: viewModel.todayRevenue, icon: "indianrupeesign", trend: nil, color: Color(hex: "2A9D8F"))
                .contentShape(Rectangle())
                .onTapGesture { isShowingRevenueDetail = true }
            
            KPICardView(title: "Pending Requests", value: viewModel.pendingRequests, icon: "doc.text.fill", trend: nil, color: RSMSColors.burgundy)
                .contentShape(Rectangle())
                .onTapGesture { isShowingRequestsDetail = true }
            
            KPICardView(title: "Low Stock Items", value: viewModel.lowStockItems, icon: "exclamationmark.triangle.fill", trend: nil, color: Color(hex: "E76F51"))
                .contentShape(Rectangle())
                .onTapGesture { isShowingLowStockDetail = true }
            
            KPICardView(title: "Today Returns", value: viewModel.todayReturns, icon: "arrow.uturn.left", trend: nil, color: Color(hex: "D4A017"))
                .contentShape(Rectangle())
                .onTapGesture { isShowingReturnsDetail = true }
        }
    }
    
    private func initials(for name: String?) -> String {
        guard let name = name, !name.isEmpty else { return "M" }
        let components = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let second = components[1].prefix(1)
            return String(first + second).uppercased()
        } else {
            return String(name.prefix(2)).uppercased()
        }
    }
}

#Preview {
    ManagerDashboardView()
}
