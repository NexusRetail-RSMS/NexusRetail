//
//  AdminDashboardView.swift
//  NexusRetail
//
//  Admin Dashboard — the central command view for corporate retail ops.
//
//  Layout (top → bottom):
//    1. "Dashboard" header with curved bottom edge + profile avatar
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
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // MARK: - Header
                headerSection
                
                if viewModel.isLoading && viewModel.kpis == nil {
                    // Initial full-screen loading
                    VStack {
                        Spacer()
                        ProgressView("Loading Dashboard...")
                            .padding()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                } else {
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
        }
        .refreshable {
            await viewModel.load()
        }
        .task {
            // Only load on first appearance if we haven't loaded yet
            if viewModel.kpis == nil {
                await viewModel.load()
            }
        }
        .background(RSMSColors.background.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .navigationBarHidden(true)
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

    // MARK: - Header
    //
    // Just "Dashboard" title + profile avatar.
    // Smooth curved bottom edge to eliminate the harsh line.
    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("Dashboard")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Button {
                isProfilePresented = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Text(initials(for: sessionStore.currentUser?.name))
                        .font(.headline.bold())
                        .foregroundColor(.white)
                }
            }
            .accessibilityLabel("Profile")
            .accessibilityHint("Opens your profile and settings")
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.xxxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(HeaderCurve())
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

// MARK: - Header Curve Shape

/// Custom shape that gives the header a smooth curved bottom edge
/// instead of a harsh straight line.
struct HeaderCurve: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 20))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.maxY - 20),
            control: CGPoint(x: rect.midX, y: rect.maxY + 10)
        )
        path.closeSubpath()
        return path
    }
}



#Preview {
    NavigationStack {
        AdminDashboardView()
            .environment(SessionStore())
    }
}
