//
//  AfterSalesDashboardView.swift
//  NexusRetail
//

import SwiftUI
import Charts

struct AfterSalesDashboardView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(AppTheme.self) private var theme
    @Binding var path: NavigationPath
    var namespace: Namespace.ID
    @Binding var showScanner: Bool

    @State private var vm = AfterSalesDashboardViewModel()
    @State private var ticketFilter: AfterSalesTicketFilter? = nil

    // Content-only view. Navigation lives in AfterSalesTabView.
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    kpiSection
                    serviceTrendChartSection
                    serviceStatusDonutSection
                    Spacer(minLength: 110) // clears the custom bottom bar
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, 16)
            }
            .background(theme.background.ignoresSafeArea())
            .refreshable { await vm.fetch(storeID: sessionStore.currentUser?.storeID) }
            .task { await vm.fetch(storeID: sessionStore.currentUser?.storeID) }
            
            if #available(iOS 18.0, *) {
                floatingQRButton
                    .matchedTransitionSource(id: "scannerButton", in: namespace)
            } else {
                floatingQRButton
            }
        }
        .sheet(item: $ticketFilter) { filter in
            AfterSalesTicketsListView(filter: filter, storeID: sessionStore.currentUser?.storeID)
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(theme.primaryText)
            Spacer()
            
            Button {
                path.append(POSFlowDestination.afterSalesHistory)
            } label: {
                ZStack {
                    Circle().fill(theme.burgundy.opacity(0.1)).frame(width: 44, height: 44)
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(theme.burgundy)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("History")

            NavigationLink(destination: GlobalProfileView()) {
                ZStack {
                    Circle().fill(theme.burgundy).frame(width: 44, height: 44)
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
                        Text(initials(for: sessionStore.currentUser?.name))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Profile")
        }
        .padding(.vertical, 4)
    }
    
    private func initials(for name: String?) -> String {
        guard let name = name, !name.isEmpty else { return "AS" }
        let components = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "AS"
    }
    
    // MARK: - KPI Section
    private var kpiSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RSMSSpacing.md) {
            Button {
                ticketFilter = .pending
            } label: {
                KPICardView(title: "Pending Service Requests", value: "\(vm.pendingServiceRequests)", icon: "wrench.and.screwdriver.fill", trend: nil, color: theme.warning)
            }
            .buttonStyle(.plain)

            Button {
                ticketFilter = .inProgress
            } label: {
                KPICardView(title: "Repairs In Progress", value: "\(vm.repairsInProgress)", icon: "hammer.fill", trend: nil, color: Color(hex: "2A9D8F"))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Service Request Trend Chart
    private var serviceTrendChartSection: some View {
        let accentColor = theme.isDarkMode ? RSMSColors.antiqueGold : RSMSColors.burgundy
        let barGradient: [Color] = theme.isDarkMode
            ? [RSMSColors.antiqueGold.opacity(0.55), RSMSColors.antiqueGold]
            : [RSMSColors.burgundy.opacity(0.6), RSMSColors.burgundy]

        return VStack(alignment: .leading, spacing: RSMSSpacing.md) {
            HStack {
                Text("Service Requests")
                    .font(RSMSFonts.headline)
                    .foregroundColor(theme.primaryText)
                Spacer()
                periodToggle(accentColor: accentColor)
            }
            
            if vm.serviceRequestChartData.allSatisfy({ $0.value == 0 }) {
                emptyChartPlaceholder(text: "No service requests in this period")
            } else {
            Chart(vm.serviceRequestChartData) { point in
                BarMark(x: .value("Period", point.label), y: .value("Requests", point.value), width: .ratio(0.45))
                    .foregroundStyle(LinearGradient(colors: barGradient, startPoint: .top, endPoint: .bottom))
                    .cornerRadius(8)
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4])).foregroundStyle(theme.divider)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v))")
                                .font(.system(size: 9)).foregroundColor(theme.secondaryText)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(theme.secondaryText)
                        }
                    }
                }
            }
            .frame(height: 200)
            }
        }
        .padding(RSMSSpacing.lg)
        .background(theme.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .strokeBorder(accentColor.opacity(theme.isDarkMode ? 0.22 : 0.0), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(theme.isDarkMode ? 0.35 : 0.05), radius: 8, x: 0, y: 4)
    }

    private func periodToggle(accentColor: Color) -> some View {
        HStack(spacing: 0) {
            ForEach(ChartPeriod.allCases) { period in
                let isSelected = vm.selectedChartPeriod == period
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.72)) {
                        vm.selectedChartPeriod = period
                    }
                } label: {
                    Text(period.rawValue)
                        .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                        .foregroundColor(
                            isSelected
                                ? (theme.isDarkMode ? Color(hex: "1A0A0A") : .white)
                                : theme.secondaryText
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(
                            isSelected
                                ? accentColor
                                : Color.clear
                        )
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .animation(.spring(response: 0.3, dampingFraction: 0.72), value: vm.selectedChartPeriod)
            }
        }
        .padding(3)
        .background(theme.divider.opacity(0.3))
        .clipShape(Capsule())
    }

    private func emptyChartPlaceholder(text: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 32))
                .foregroundColor(theme.secondaryText.opacity(0.4))
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(theme.secondaryText)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
    }
    
    // MARK: - Service Status Donut Chart
    private var serviceStatusDonutSection: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.md) {
            Text("Service Status")
                .font(RSMSFonts.headline)
                .foregroundColor(theme.primaryText)
            
            if vm.totalServiceRequests == 0 {
                emptyChartPlaceholder(text: "No service tickets yet")
            } else {
            Chart(vm.serviceStatusChartData) { point in
                SectorMark(
                    angle: .value("Requests", point.value),
                    innerRadius: .ratio(0.65),
                    angularInset: 1.5
                )
                .foregroundStyle(by: .value("Status", point.label))
                .cornerRadius(4)
            }
            .chartForegroundStyleScale([
                "Pending": Color(hex: "E9C46A"),
                "Repair": Color(hex: "2A9D8F"),
                "Completed": Color(hex: "264653"),
                "Returned": Color(hex: "8A2BE2")
            ])
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let anchor = chartProxy.plotFrame {
                        let frame = geometry[anchor]
                        VStack(spacing: 2) {
                            Text("\(vm.totalServiceRequests)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(theme.primaryText)
                            Text("Total")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(theme.secondaryText)
                        }
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
            }
            .frame(height: 220)
            }
        }
        .padding(RSMSSpacing.lg)
        .background(theme.cardBackground)
        .cornerRadius(RSMSRadius.large)
.overlay(
            RoundedRectangle(cornerRadius: RSMSRadius.large)
                .strokeBorder(accentColor.opacity(theme.isDarkMode ? 0.22 : 0.0), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(theme.isDarkMode ? 0.35 : 0.04), radius: 6, x: 0, y: 3)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Service Status Chart, Total service tickets: \(vm.totalServiceRequests)")
    }
    
    // MARK: - Floating QR Button
    private var floatingQRButton: some View {
        Button {
            showScanner = true
        } label: {
            ZStack {
                Circle()
                    .fill(accentColor)
                    .frame(width: 60, height: 60)
                    .shadow(color: accentColor.opacity(0.5), radius: 8, x: 0, y: 4)
                
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(AnimatedFloatingButtonStyle())
        .padding(.trailing, 20)
        .padding(.bottom, 24)
        .accessibilityLabel("Scan QR Code")
    }
}
