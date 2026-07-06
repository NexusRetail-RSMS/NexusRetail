import SwiftUI
import Supabase

struct AdminDashboardView: View {
    @Environment(SessionStore.self) private var sessionStore
    @State private var viewModel = DashboardViewModel()
    @State private var isProfilePresented = false

    @State private var isShowingSalesDetail = false
    @State private var isShowingProductsDetail = false
    @State private var isShowingActiveStoresDetail = false

    private var globalStore: Store {
        Store(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000000") ?? UUID(),
            name: viewModel.displayCountry == "All Global" ? "Global Sales" : "\(viewModel.displayCountry) Sales",
            address: nil, locale: "en_IN", currencyCode: "INR", timezone: nil,
            phone: nil, managerID: nil, isWarehouse: false, status: .active,
            latitude: nil, longitude: nil, city: nil, country: nil,
            imageURL: nil
        )
    }

    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                        .padding(.top, 16)

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

                    if viewModel.isLoading && viewModel.kpis == nil {
                        VStack {
                            Spacer()
                            ProgressView("Loading Dashboard...")
                                .tint(RSMSColors.burgundy)
                                .padding()
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, minHeight: 300)
                    } else {
                        VStack(alignment: .leading, spacing: RSMSSpacing.xl) {
                            kpiSection

                            RevenueBarChart(
                                data: viewModel.revenueChartData,
                                maxValue: viewModel.revenueMaxValue,
                                timeRange: $viewModel.revenueTimeRange
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { isShowingSalesDetail = true }

                            ProductSalesChart(
                                data: viewModel.productChartData,
                                maxValue: viewModel.productMaxValue,
                                timeRange: $viewModel.productTimeRange
                            )
                            .contentShape(Rectangle())
                            .onTapGesture { isShowingProductsDetail = true }

                            TopLocationsChartView(revenueByCountry: viewModel.byCountry, selectedCountry: viewModel.selectedCountry)
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.top, RSMSSpacing.xxl)
                        .padding(.bottom, RSMSSpacing.xxl)
                    }
                }
            }
            .refreshable {
                await viewModel.load()
            }
            .onAppear {
                Task { await viewModel.load() }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
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
        .fullScreenCover(isPresented: $isShowingActiveStoresDetail) {
            NavigationStack {
                storeDashView()
            }
        }
    }

    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("Dashboard")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(RSMSColors.primaryText)

            Spacer()

            Menu {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        viewModel.selectedCountry = nil
                    }
                } label: {
                    Text("🌍 All Global")
                }
                ForEach(viewModel.countries, id: \.self) { country in
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            viewModel.selectedCountry = country
                        }
                    } label: {
                        Text("\(countryFlag(for: country)) \(country)")
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(RSMSColors.burgundy.opacity(0.1))
                        .frame(width: 44, height: 44)

                    if let selected = viewModel.selectedCountry {
                        Text(countryFlag(for: selected))
                            .font(.system(size: 22))
                    } else {
                        Text("🌍")
                            .font(.system(size: 22))
                    }
                }
            }
            .accessibilityLabel("Country filter")

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

    private func countryFlag(for country: String) -> String {
        let map: [String: String] = [
            "United States":        "🇺🇸",
            "USA":                  "🇺🇸",
            "United Kingdom":       "🇬🇧",
            "UK":                   "🇬🇧",
            "Canada":               "🇨🇦",
            "Australia":            "🇦🇺",
            "Germany":              "🇩🇪",
            "France":               "🇫🇷",
            "Japan":                "🇯🇵",
            "India":                "🇮🇳",
            "Singapore":            "🇸🇬",
            "United Arab Emirates": "🇦🇪",
            "UAE":                  "🇦🇪",
        ]
        return map[country] ?? "🌍"
    }

    private var kpiSection: some View {
        VStack(spacing: RSMSSpacing.md) {
            HeroRevenueCard(
                title: "This Year Revenue",
                value: viewModel.formattedRevenue,
                trend: viewModel.yearlyRevenueTrendText,
                sparklineValues: viewModel.yearlyRevenuePoints
            ) {
                isShowingSalesDetail = true
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: RSMSSpacing.sm) {
                FlatKPICard(
                    title: "Store Leaderboard",
                    value: viewModel.activeStoresText,
                    icon: "building.2.fill",
                    color: RSMSColors.burgundy
                ){
                    isShowingActiveStoresDetail = true
                }
                FlatKPICard(
                    title: "Pending Transfers",
                    value: viewModel.pendingTransfersText,
                    icon: "arrow.left.arrow.right.circle.fill",
                    color: Color(hex: "E76F51")
                )
                FlatKPICard(
                    title: "Low-Stock Alerts",
                    value: viewModel.lowStockText,
                    icon: "exclamationmark.triangle.fill",
                    color: Color(hex: "D4A017")
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.selectedCountry)
    }
}

#Preview {
    NavigationStack {
        AdminDashboardView()
            .environment(SessionStore())
    }
}
