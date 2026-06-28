//
//  AdminDashboardView.swift
//  NexusRetail
//
//  Admin Dashboard — the central command view for corporate retail ops.
//
//  Layout (top → bottom):
//    1. Floating "Dashboard" header matching the Stores page style
//    2. KPI overview cards (Revenue, Active Stores, Pending Transfers, Low-Stock)
//    3. Store Revenue chart (has its own Weekly/Monthly toggle + country filter chips)
//    4. Top Product Sales chart (has its own separate Weekly/Monthly toggle)
//
//  Each chart manages its own time-range toggle independently.
//  The country filter inside the Revenue chart also updates the KPI cards.
//

import SwiftUI
import Supabase

struct AdminDashboardView: View {
    @Environment(SessionStore.self) private var sessionStore
    @State private var viewModel = DashboardViewModel()
    @State private var isProfilePresented = false
    
    // Drill-down states
    @State private var isShowingSalesDetail = false
    @State private var isShowingProductsDetail = false
    
    // Dummy store for global drill-downs
    private var globalStore: Store {
        Store(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000") ?? UUID(),
            name: viewModel.displayCountry == "All Global" ? "Global Sales" : "\(viewModel.displayCountry) Sales",
            address: nil, locale: "en_US", currencyCode: "USD", timezone: nil,
            phone: nil, managerID: nil, isWarehouse: false, status: .active
        )
    }

    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()

            ZStack(alignment: .top) {
                // 1. Scrollable Content
                Group {
                    if viewModel.isLoading && viewModel.kpis == nil {
                        // Initial full-screen loading
                        VStack {
                            Spacer()
                            ProgressView("Loading Dashboard...")
                                .tint(RSMSColors.burgundy)
                                .padding()
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                // MARK: - Error Banner
                                if let errorMessage = viewModel.errorMessage {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.white)
                                        Text(errorMessage)
                                            .font(RSMSFonts.caption)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Button("Retry") {
                                            Task { await viewModel.load() }
                                        }
                                        .foregroundColor(.white)
                                        .font(RSMSFonts.caption.bold())
                                    }
                                    .padding()
                                    .background(Color(hex: "FF3B30"))
                                    .cornerRadius(RSMSRadius.medium)
                                    .padding(.horizontal, RSMSSpacing.lg)
                                    .padding(.top, RSMSSpacing.md)
                                }

                                // MARK: - Content
                                VStack(alignment: .leading, spacing: RSMSSpacing.xl) {

                                    // MARK: - KPI Overview
                                    kpiSection

                                    // MARK: - Store Revenue
                                    RevenueBarChart(
                                        data: viewModel.revenueChartData,
                                        maxValue: viewModel.revenueMaxValue,
                                        timeRange: $viewModel.revenueTimeRange
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture { isShowingSalesDetail = true }

                                    // MARK: - Top Product Sales (with its own toggle)
                                    ProductSalesChart(
                                        data: viewModel.productChartData,
                                        maxValue: viewModel.productMaxValue,
                                        timeRange: $viewModel.productTimeRange
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture { isShowingProductsDetail = true }

                                    // MARK: - Top Locations
                                    TopLocationsChartView()
                                }
                                .padding(.horizontal, RSMSSpacing.lg)
                                .padding(.top, RSMSSpacing.xl)
                                .padding(.bottom, RSMSSpacing.xxl)
                            }
                        }
                        .safeAreaInset(edge: .top) {
                            Color.clear.frame(height: 70)
                        }
                        .refreshable {
                            await viewModel.load()
                        }
                    }
                }

                // 2. Floating Header (matches Stores page style)
                VStack(spacing: 0) {
                    HStack {
                        Text("Dashboard")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(RSMSColors.primaryText)

                        Spacer()

                        Button {
                            isProfilePresented = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(RSMSColors.burgundy)
                                    .frame(width: 44, height: 44)

                                Text(initials(for: sessionStore.currentUser?.name))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        .accessibilityLabel("Profile")
                        .accessibilityHint("Opens your profile and settings")
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }
                .background(
                    RSMSColors.background
                        .ignoresSafeArea(edges: .top)
                )
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            // Only load on first appearance if we haven't loaded yet
            if viewModel.kpis == nil {
                await viewModel.load()
            }
        }
        .sheet(isPresented: $isProfilePresented) {
            AdminProfileSheet()
        }
        .fullScreenCover(isPresented: $isShowingSalesDetail) {
            NavigationStack {
                SalesDetailView(store: globalStore)
            }
        }
        .fullScreenCover(isPresented: $isShowingProductsDetail) {
            NavigationStack {
                TopProductsDetailView(store: globalStore)
            }
        }
    }

    private func initials(for name: String?) -> String {
        guard let name = name, !name.isEmpty else { return "AD" }
        let components = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "AD"
    }

    // MARK: - KPI Cards
    //
    // These four cards map directly to the Admin workflow:
    //   • Total Revenue      → "Sales Revenue of Stores"
    //   • Active Stores      → "Create Store" branch
    //   • Pending Transfers  → "Review Stock Request → Approve Transfer"
    //   • Low-Stock Alerts   → triggers "Create Purchase Order" or manager replenishment
    //
    // They react to the country filter inside the Revenue chart.
    private var kpiSection: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
            HStack {
                Text("Overview")
                    .font(RSMSFonts.headline)
                    .foregroundColor(RSMSColors.darkBrown)
                    .padding(.leading, 4)
                
                Spacer()
                
                Menu {
                    Button("All Global") {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.selectedCountry = nil
                        }
                    }
                    ForEach(viewModel.countries, id: \.self) { country in
                        Button(country) {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.selectedCountry = country
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(viewModel.displayCountry)
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(RSMSColors.primaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RSMSSpacing.md) {
                KPICardView(
                    title: "Total Revenue",
                    value: viewModel.formattedRevenue,
                    icon: "indianrupeesign.circle.fill",
                    trend: nil,
                    color: Color(hex: "34C759") // Green
                )
                KPICardView(
                    title: "Active Stores",
                    value: viewModel.activeStoresText,
                    icon: "building.2.fill",
                    trend: nil,
                    color: Color(hex: "007AFF") // Blue
                )
                KPICardView(
                    title: "Pending Transfers",
                    value: viewModel.pendingTransfersText,
                    icon: "arrow.left.arrow.right.circle.fill",
                    trend: nil,
                    color: Color(hex: "FF9500") // Orange
                )
                KPICardView(
                    title: "Low-Stock Alerts",
                    value: viewModel.lowStockText,
                    icon: "exclamationmark.triangle.fill",
                    trend: nil,
                    color: Color(hex: "FF3B30") // Red
                )
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.selectedCountry)
        }
    }
}



#Preview {
    NavigationStack {
        AdminDashboardView()
            .environment(SessionStore())
    }
}
