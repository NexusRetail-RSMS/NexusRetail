//
//  AfterSalesDashboardView.swift
//  NexusRetail
//

import SwiftUI
import Charts

struct AfterSalesDashboardView: View {
    @Environment(SessionStore.self) private var sessionStore
    @State private var vm = AfterSalesDashboardViewModel()
    @State private var isProfilePresented = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSColors.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        headerSection
                        kpiSection
                        serviceTrendChartSection
                        serviceStatusDonutSection
                        urgentCasesSection
                        quickActionsSection
                        recentActivitySection
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, 16)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $isProfilePresented) {
                AdminProfileSheet()
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(RSMSColors.primaryText)
            Spacer()
            Button { isProfilePresented = true } label: {
                ZStack {
                    Circle().fill(RSMSColors.burgundy).frame(width: 44, height: 44)
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
            KPICardView(title: "Pending Service Requests", value: "\(vm.pendingServiceRequests)", icon: "wrench.and.screwdriver.fill", trend: nil, color: RSMSColors.warning)
            KPICardView(title: "Repairs In Progress", value: "\(vm.repairsInProgress)", icon: "hammer.fill", trend: nil, color: Color(hex: "2A9D8F"))
            KPICardView(title: "Warranty Verifications", value: "\(vm.warrantyVerifications)", icon: "shield.lefthalf.filled", trend: nil, color: RSMSColors.success)
            KPICardView(title: "Returns Awaiting Approval", value: "\(vm.returnsAwaitingApproval)", icon: "arrow.uturn.backward.circle.fill", trend: nil, color: RSMSColors.error)
        }
    }
    
    // MARK: - Service Request Trend Chart
    private var serviceTrendChartSection: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.md) {
            HStack {
                Text("Service Requests")
                    .font(RSMSFonts.headline)
                    .foregroundColor(RSMSColors.primaryText)
                Spacer()
                Picker("Period", selection: $vm.selectedChartPeriod) {
                    ForEach(ChartPeriod.allCases) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .fixedSize()
            }
            
            Chart(vm.serviceRequestChartData) { point in
                BarMark(x: .value("Period", point.label), y: .value("Requests", point.value), width: .ratio(0.45))
                    .foregroundStyle(LinearGradient(colors: [Color(hex: "2A9D8F").opacity(0.6), Color(hex: "2A9D8F")], startPoint: .top, endPoint: .bottom))
                    .cornerRadius(8)
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4])).foregroundStyle(RSMSColors.divider)
                    AxisValueLabel {
                        if let v = value.as(Double.self) {
                            Text("\(Int(v))")
                                .font(.system(size: 9)).foregroundColor(RSMSColors.secondaryText)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let label = value.as(String.self) {
                            Text(label).font(.system(size: 10, weight: .medium)).foregroundColor(RSMSColors.secondaryText)
                        }
                    }
                }
            }
            .frame(height: 200)
        }
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - Service Status Donut Chart
    private var serviceStatusDonutSection: some View {
        VStack(alignment: .leading, spacing: RSMSSpacing.md) {
            Text("Service Status")
                .font(RSMSFonts.headline)
                .foregroundColor(RSMSColors.primaryText)
            
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
                "Pending": RSMSColors.warning,
                "Repair": Color(hex: "2A9D8F"),
                "Completed": RSMSColors.success,
                "Returned": RSMSColors.error
            ])
            .chartBackground { chartProxy in
                GeometryReader { geometry in
                    if let anchor = chartProxy.plotFrame {
                        let frame = geometry[anchor]
                        VStack(spacing: 2) {
                            Text("\(vm.totalServiceRequests)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(RSMSColors.primaryText)
                            Text("Total")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(RSMSColors.secondaryText)
                        }
                        .position(x: frame.midX, y: frame.midY)
                    }
                }
            }
            .frame(height: 220)
        }
        .padding(RSMSSpacing.lg)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - Urgent Cases
    private var urgentCasesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Urgent Cases")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(RSMSColors.darkBrown)
                .padding(.horizontal, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(vm.urgentCases) { request in
                        urgentCaseCard(request)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 8)
            }
        }
    }
    
    private func urgentCaseCard(_ request: ServiceRequest) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(request.serviceId)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(RSMSColors.burgundy)
                Spacer()
                Text("\(request.daysRemaining) Days Left")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(RSMSColors.error)
            }
            
            Text(request.customerName)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(RSMSColors.primaryText)
            
            HStack {
                Label(request.issueType, systemImage: "tag.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(RSMSColors.secondaryText)
                Spacer()
                Text(request.priority.rawValue)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(request.priority.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(request.priority.color.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(16)
        .frame(width: 240)
        .background(RSMSColors.cardBackground)
        .cornerRadius(RSMSRadius.large)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick Actions")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(RSMSColors.darkBrown)
                .padding(.horizontal, 4)
            
            let columns = [GridItem(.flexible()), GridItem(.flexible())]
            
            LazyVGrid(columns: columns, spacing: 12) {
                quickActionButton(title: "Verify Warranty", icon: "checkmark.shield", color: RSMSColors.burgundy)
                quickActionButton(title: "Update Repair Status", icon: "wrench.and.screwdriver", color: Color(hex: "2A9D8F"))
                quickActionButton(title: "Approve Return", icon: "arrow.uturn.backward.circle", color: RSMSColors.error)
                quickActionButton(title: "Notify Customer", icon: "bell", color: RSMSColors.warning)
            }
        }
    }
    
    private func quickActionButton(title: String, icon: String, color: Color) -> some View {
        Button { } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.8)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Recent Activity
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Activities")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(RSMSColors.darkBrown)
                .padding(.horizontal, 4)
            
            VStack(spacing: 12) {
                ForEach(vm.recentActivities) { activity in
                    activityRow(activity)
                }
            }
        }
    }
    
    private func activityRow(_ activity: ServiceActivity) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(activity.iconColor.opacity(0.1)).frame(width: 40, height: 40)
                Image(systemName: activity.statusIcon)
                    .font(.system(size: 15))
                    .foregroundColor(activity.iconColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.statusText).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(RSMSColors.primaryText)
                Text("\(activity.customerName) • \(activity.serviceId)").font(.system(size: 12)).foregroundColor(RSMSColors.secondaryText)
            }
            Spacer()
            Text(activity.time).font(.system(size: 11)).foregroundColor(RSMSColors.secondaryText.opacity(0.8))
        }
        .padding(12)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSColors.cardBorder, lineWidth: 1))
    }
}
