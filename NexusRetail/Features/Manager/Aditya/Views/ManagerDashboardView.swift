//
//  ManagerDashboardView.swift
//  NexusRetail
//

import SwiftUI

struct ManagerDashboardView: View {
    @State private var viewModel = ManagerDashboardViewModel()
    @Environment(SessionStore.self) private var sessionStore
    @Environment(AppTheme.self) private var theme
    
    // Notification ViewModel
    @State private var notificationVM = LowStockNotificationViewModel()
    
    // Presentation States
    @State private var isProfilePresented = false
    @State private var isNotificationPresented = false
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
                    timeRange: $viewModel.topProductsTimeRange,
                    allowsYearly: true
                )
                
                // MARK: - Staff Performance
                StaffPerformanceChart(
                    data: viewModel.staffPerformanceData
                )
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.bottom, RSMSSpacing.xxxl)
        }
        .background(theme.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .refreshable {
            // Pick up any store reassignment made by an admin without needing re-login.
            await sessionStore.refreshCurrentUser()
            await viewModel.fetchData(storeID: sessionStore.currentUser?.storeID)
        }
        .task {
            await sessionStore.refreshCurrentUser()
            await viewModel.fetchData(storeID: sessionStore.currentUser?.storeID)
            await viewModel.fetchRevenueData(storeID: sessionStore.currentUser?.storeID)
            await notificationVM.load(storeID: sessionStore.currentUser?.storeID)
            // Start real-time listener for instant low-stock notifications
            Task {
                await notificationVM.startListening(storeID: sessionStore.currentUser?.storeID)
            }
        }
        .onChange(of: viewModel.topProductsTimeRange) { _, _ in
            Task { await viewModel.fetchData(storeID: sessionStore.currentUser?.storeID) }
        }
        .onAppear {
            // Refresh data when view appears (e.g., after completing a sale)
            Task {
                await viewModel.fetchData(storeID: sessionStore.currentUser?.storeID)
                await notificationVM.load(storeID: sessionStore.currentUser?.storeID)
            }
        }
        .sheet(isPresented: $isProfilePresented) {
            AdminProfileSheet()
                .environment(theme)
        }
        .sheet(isPresented: $isNotificationPresented) {
            NotificationListView(viewModel: notificationVM)
        }
        .fullScreenCover(isPresented: $isShowingRevenueDetail) {
            NavigationStack {
                ZStack {
                    theme.background.ignoresSafeArea()
                    VStack {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Sales Report")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(theme.primaryText)
                                Text("Total: \(viewModel.sixMonthTotal)")
                                    .font(.system(size: 14))
                                    .foregroundColor(theme.secondaryText)
                            }
                            Spacer()
                            Menu {
                                Button("Weekly") { 
                                    viewModel.revenueTimeRange = .weekly
                                    viewModel.revenueDate = Date()
                                    Task { await viewModel.fetchRevenueData(storeID: sessionStore.currentUser?.storeID) }
                                }
                                Button("Monthly") { 
                                    viewModel.revenueTimeRange = .monthly
                                    viewModel.revenueDate = Date()
                                    Task { await viewModel.fetchRevenueData(storeID: sessionStore.currentUser?.storeID) }
                                }
                                Button("Yearly") { 
                                    viewModel.revenueTimeRange = .yearly
                                    viewModel.revenueDate = Date()
                                    Task { await viewModel.fetchRevenueData(storeID: sessionStore.currentUser?.storeID) }
                                }
                            } label: {
                                HStack(spacing: 4) {
                                    Text(viewModel.revenueTimeRange.rawValue)
                                        .font(.system(size: 14, weight: .medium))
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.05))
                                .cornerRadius(16)
                                .foregroundColor(theme.primaryText)
                            }
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.top, RSMSSpacing.lg)
                        
                        let calendarBinding = Binding<StoreChartTimeRange>(
                            get: {
                                switch viewModel.revenueTimeRange {
                                case .weekly: return .weekly(viewModel.revenueDate)
                                case .monthly: return .monthly(viewModel.revenueDate)
                                case .yearly: return .yearly(viewModel.revenueDate)
                                }
                            },
                            set: { newRange in
                                switch newRange {
                                case .weekly(let d):
                                    viewModel.revenueTimeRange = .weekly
                                    viewModel.revenueDate = d
                                case .monthly(let d):
                                    viewModel.revenueTimeRange = .monthly
                                    viewModel.revenueDate = d
                                case .yearly(let d):
                                    viewModel.revenueTimeRange = .yearly
                                    viewModel.revenueDate = d
                                }
                                Task { await viewModel.fetchRevenueData(storeID: sessionStore.currentUser?.storeID) }
                            }
                        )
                        
                        SwipeableCalendarView(selectedRange: calendarBinding)
                            .padding(.top, 4)
                        
                        ManagerRevenueChartView(
                            data: viewModel.revenueChartData,
                            maxValue: viewModel.revenueMaxValue,
                            sixMonthTotal: viewModel.sixMonthTotal,
                            peakMonth: viewModel.peakMonth,
                            timeRange: $viewModel.revenueTimeRange
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
                                .foregroundColor(theme.primaryText)
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isShowingRequestsDetail) {
            NavigationStack {
                ZStack {
                    theme.background.ignoresSafeArea()
                    VStack {
                        ManagerRequestsView()
                    }
                }
                .navigationTitle("Requests")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { isShowingRequestsDetail = false }) {
                            Image(systemName: "xmark")
                                .foregroundColor(theme.primaryText)
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isShowingLowStockDetail) {
            NavigationStack {
                ZStack {
                    theme.background.ignoresSafeArea()
                    VStack {
                        ManagerLowStockView()
                    }
                }
                .navigationTitle("Low Stock")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { isShowingLowStockDetail = false }) {
                            Image(systemName: "xmark")
                                .foregroundColor(theme.primaryText)
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $isShowingReturnsDetail) {
            NavigationStack {
                ZStack {
                    theme.background.ignoresSafeArea()
                    VStack {
                        ManagerReturnsView()
                    }
                }
                .navigationTitle("After Service")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { isShowingReturnsDetail = false }) {
                            Image(systemName: "xmark")
                                .foregroundColor(theme.primaryText)
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
                .foregroundColor(theme.primaryText)

            Spacer()

            // Notification bell
            NotificationBellView(unreadCount: notificationVM.unreadCount) {
                isNotificationPresented = true
            }
            
            // Profile avatar
            Button {
                isProfilePresented = true
            } label: {
                ZStack {
                    Circle()
                        .fill(theme.burgundy)
                        .frame(width: 44, height: 44)

                    if let urlString = sessionStore.currentUser?.imageUrl, let url = URL(string: urlString) {
                        CachedAsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                        } placeholder: {
                            ProgressView()
                                .frame(width: 44, height: 44)
                        }
                    } else {
                        Text(initials(for: sessionStore.currentUser?.name ?? viewModel.managerName))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
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
            
            KPICardView(title: "Pending Requests", value: viewModel.pendingRequests, icon: "doc.text.fill", trend: nil, color: theme.burgundy)
                .contentShape(Rectangle())
                .onTapGesture { isShowingRequestsDetail = true }
            
            KPICardView(title: "Low Stock Items", value: viewModel.lowStockItems, icon: "exclamationmark.triangle.fill", trend: nil, color: Color(hex: "E76F51"))
                .contentShape(Rectangle())
                .onTapGesture { isShowingLowStockDetail = true }
            
            KPICardView(title: "After Service", value: viewModel.afterServiceCount, icon: "wrench.and.screwdriver.fill", trend: nil, color: Color(hex: "D4A017"))
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
