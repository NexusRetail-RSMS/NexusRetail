//
//  AdminManagersView.swift
//  NexusRetail
//

import SwiftUI

// MARK: - Data Model

struct DisplayManager: Identifiable, Hashable {
    let id: UUID
    var name: String
    var storeName: String
    var country: String
    var performanceScore: Int
    var revenue: String
    var imageUrl: String?
    // Contact info
    var phone: String = ""
    var email: String = ""
    var address: String = ""
    // Stats
    var productsSold: Int = 0
    var createdAt: Date = Date()
    var isActive: Bool = true
    
    init(id: UUID, name: String, storeName: String, country: String, performanceScore: Int, revenue: String, imageUrl: String? = nil, phone: String = "", email: String = "", address: String = "", productsSold: Int = 0, createdAt: Date = Date(), isActive: Bool = true) {
        self.id = id
        self.name = name
        self.storeName = storeName
        self.country = country
        self.performanceScore = performanceScore
        self.revenue = revenue
        self.imageUrl = imageUrl
        self.phone = phone
        self.email = email
        self.address = address
        self.productsSold = productsSold
        self.createdAt = createdAt
        self.isActive = true
    }

    init(rpc: ManagerStatsRPC) {
        self.id = rpc.id
        self.name = rpc.name ?? "Unknown"
        self.storeName = rpc.storeName ?? "Unassigned"
        self.country = rpc.country ?? "Unknown"
        self.performanceScore = rpc.performanceScore ?? 0
        self.imageUrl = rpc.imageUrl
        self.phone = rpc.phone ?? ""
        self.email = rpc.email ?? ""
        self.address = rpc.storeName ?? ""
        self.productsSold = rpc.productsSold ?? 0
        
        self.revenue = formatIndianCurrency(rpc.revenue ?? 0)

        var parsedDate = Date()
        if let dateStr = rpc.createdAt {
            let iso1 = ISO8601DateFormatter()
            iso1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = iso1.date(from: dateStr) {
                parsedDate = date
            } else {
                let iso2 = ISO8601DateFormatter()
                if let date = iso2.date(from: dateStr) {
                    parsedDate = date
                }
            }
        }
        self.createdAt = parsedDate
        self.isActive = true
    }
}

// Removed ManagersStore

// MARK: - Helpers

func flagEmoji(for country: String) -> String {
    let map: [String: String] = [
        "United States":        "🇺🇸",
        "United Kingdom":       "🇬🇧",
        "Canada":               "🇨🇦",
        "Australia":            "🇦🇺",
        "Germany":              "🇩🇪",
        "France":               "🇫🇷",
        "Japan":                "🇯🇵",
        "India":                "🇮🇳",
        "Singapore":            "🇸🇬",
        "United Arab Emirates": "🇦🇪",
    ]
    return map[country] ?? "🌍"
}

func performanceColor(for score: Int) -> Color {
    let theme = AppTheme()
    if score >= 90 { return theme.success }
    if score >= 75 { return theme.warning }
    return theme.error
}

// MARK: - Bookmark Badge Shape

struct BookmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        let notch = h * 0.28
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: w, y: 0))
        p.addLine(to: CGPoint(x: w, y: h))
        p.addLine(to: CGPoint(x: w / 2, y: h - notch))
        p.addLine(to: CGPoint(x: 0, y: h))
        p.closeSubpath()
        return p
    }
}

// MARK: - Filter State

enum PerformanceSortOrder: String, CaseIterable {
    case none       = "None"
    case topToLow   = "Highest Performance"
    case lowToTop   = "Lowest Performance"
    }

// MARK: - Main View

struct AdminManagersView: View {
    @Environment(AppTheme.self) private var theme
    @Binding var isAddManagerPresented: Bool
    @Binding var searchText: String
    @Environment(AdminNavigationStore.self) private var navStore
    @State private var viewModel = ManagersViewModel()
    @State private var topPerformerPage = 0
    @State private var scrolledID: Int?
    @State private var selectedCountryFilter = "All"
    @State private var selectedPerformanceSort: PerformanceSortOrder = .none
    @State private var editingManager: DisplayManager? = nil
    @State private var isRecentlyAddedSort = false
    @State private var managerToDelete: DisplayManager? = nil

    private let topCount = 3

    private var allCountries: [String] {
        let names = viewModel.managers.map { $0.country }
        return Array(Set(names)).sorted()
    }

    var filteredManagers: [DisplayManager] {
        var result = viewModel.managers.filter { manager in
            let matchesSearch = searchText.isEmpty
                || manager.name.localizedCaseInsensitiveContains(searchText)
                || manager.storeName.localizedCaseInsensitiveContains(searchText)
            let matchesCountry = selectedCountryFilter == "All"
                || manager.country == selectedCountryFilter
            return matchesSearch && matchesCountry
        }
        if isRecentlyAddedSort {
            result.sort { $0.createdAt > $1.createdAt }
        } else {
            switch selectedPerformanceSort {
            case .topToLow: result.sort { $0.performanceScore > $1.performanceScore }
            case .lowToTop: result.sort { $0.performanceScore < $1.performanceScore }
            case .none: break
            }
        }
        return result
    }

    var isFiltered: Bool {
        selectedCountryFilter != "All" || selectedPerformanceSort != .none || isRecentlyAddedSort
    }

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: RSMSSpacing.xl) {
                    // MARK: Top Performers
                    VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
                        Text("Top Performers")
                            .font(RSMSFonts.headline)
                            .foregroundColor(theme.darkBrown)
                            .padding(.horizontal, RSMSSpacing.lg)

                        let topManagers = Array(viewModel.managers.prefix(topCount).enumerated())
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: RSMSSpacing.md) {
                                ForEach(topManagers, id: \.offset) { index, manager in
                                    TopPerformanceCard(
                                        manager: manager,
                                        rank: index + 1,
                                        onEdit: {
                                            editingManager = manager
                                        },
                                        onDelete: {
                                            managerToDelete = manager
                                        },
                                        onResetPassword: { newPassword in
                                            return await viewModel.resetPassword(for: manager.id, email: manager.email, newPassword: newPassword)
                                        },
                                        onUpdate: { updatedManager, newImage in
                                            return await viewModel.updateManager(updatedManager, newImage: newImage)
                                        }
                                    )
                                }
                            }
                            .scrollTargetLayout()
                            .padding(.horizontal, RSMSSpacing.lg)
                        }
                        .frame(height: 175)
                        .scrollTargetBehavior(.viewAligned)
                        .scrollPosition(id: $scrolledID)
                        .onChange(of: scrolledID) { _, newIndex in
                            if let newIndex = newIndex {
                                topPerformerPage = newIndex
                            }
                        }

                        // Page dots (synced with actual count of top managers)
                        let actualTopCount = min(topCount, viewModel.managers.count)
                        HStack(spacing: 6) {
                            ForEach(0..<actualTopCount, id: \.self) { i in
                                Circle()
                                    .fill(i == topPerformerPage ? theme.burgundy : theme.cardBorder)
                                    .frame(width: i == topPerformerPage ? 8 : 6,
                                           height: i == topPerformerPage ? 8 : 6)
                                    .animation(.spring(response: 0.3), value: topPerformerPage)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, RSMSSpacing.xs)
                    }


                    // MARK: All Managers Header
                    HStack(alignment: .center) {
                        Text("All Managers")
                            .font(RSMSFonts.headline)
                            .foregroundColor(theme.darkBrown)
                        Spacer()
                        Menu {
                            Picker(selection: $selectedCountryFilter) {
                                Text("All Countries").tag("All")
                                ForEach(allCountries, id: \.self) { country in
                                    Text(country).tag(country)
                                }
                            } label: {
                                Label("Country", systemImage: "globe")
                            }
                            .pickerStyle(.menu)
                            
                            Picker(selection: $selectedPerformanceSort) {
                                ForEach(PerformanceSortOrder.allCases, id: \.self) { option in
                                    Text(LocalizedStringKey(option.rawValue)).tag(option)
                                }
                            } label: {
                                Label("Performance", systemImage: "chart.bar.fill")
                            }
                            .pickerStyle(.menu)
                            
                            Button {
                                isRecentlyAddedSort.toggle()
                            } label: {
                                Label(isRecentlyAddedSort ? "✓ Recently Added" : "Recently Added", systemImage: "clock")
                            }

                            if isFiltered {
                                Divider()
                                Button(role: .destructive) {
                                    selectedCountryFilter = "All"
                                    selectedPerformanceSort = .none
                                    isRecentlyAddedSort = false
                                } label: {
                                    Label("Reset Filters", systemImage: "trash")
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(isFiltered ? theme.burgundy : theme.primaryText)
                                .frame(width: 40, height: 40)
                                .background(isFiltered
                                    ? theme.burgundy.opacity(0.12)
                                    : Color.black.opacity(0.05))
                                .clipShape(Circle())
                        }
                        .id("\(selectedCountryFilter)_\(selectedPerformanceSort.rawValue)")
                    }
                    .padding(.horizontal, RSMSSpacing.lg)

                    // MARK: Manager List
                    if filteredManagers.isEmpty {
                        VStack(spacing: RSMSSpacing.md) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 44))
                                .foregroundColor(theme.secondaryText)
                            Text("Not Present")
                                .font(RSMSFonts.headline)
                                .foregroundColor(theme.primaryText)
                            Text("No manager or store matches '\(searchText)'.")
                                .font(RSMSFonts.subheadline)
                                .foregroundColor(theme.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                        .padding(.horizontal, RSMSSpacing.xxxl)
                    } else {
                        VStack(spacing: RSMSSpacing.md) {
                            ForEach(filteredManagers) { manager in
                                ManagerListCard(
                                    manager: manager,
                                    onEdit: {
                                        editingManager = manager
                                    },
                                    onDelete: {
                                        managerToDelete = manager
                                    },
                                    onResetPassword: { newPassword in
                                        return await viewModel.resetPassword(for: manager.id, email: manager.email, newPassword: newPassword)
                                    },
                                    onUpdate: { updatedManager, newImage in
                                        return await viewModel.updateManager(updatedManager, newImage: newImage)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.bottom, RSMSSpacing.xl)
                    }
                }
                .padding(.top, RSMSSpacing.sm)
            }
            .safeAreaInset(edge: .top) {
                VStack(spacing: RSMSSpacing.md) {
                    HStack {
                        Text("Managers")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(theme.primaryText)

                        Spacer()

                        AddCircleButton(accessibilityLabel: "Add new manager") {
                            isAddManagerPresented = true
                        }
                    }

                    NexusSearchBar(text: $searchText, placeholder: "Search managers, stores…")
                }
                .padding(.horizontal, RSMSSpacing.lg)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .fadingMaterialHeader()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $isAddManagerPresented) {
            NewManagerSheet(onCreate: { email, password, name, phone, storeName, address, country, image in
                return await viewModel.createManager(
                    email: email,
                    password: password,
                    name: name,
                    phone: phone,
                    storeName: storeName,
                    address: address,
                    country: country,
                    image: image
                )
            })
        }
        .sheet(item: $editingManager) { mgr in
            if let idx = viewModel.managers.firstIndex(where: { $0.id == mgr.id }) {
                EditManagerSheet(
                    manager: Binding(
                        get: { viewModel.managers[idx] },
                        set: { newMgr in
                            viewModel.managers[idx] = newMgr
                        }
                    ),
                    onSave: { updatedManager, newImage in
                        return await viewModel.updateManager(updatedManager, newImage: newImage)
                    }
                )
            } else {
                EditManagerSheet(
                    manager: .constant(mgr),
                    onSave: { updatedManager, newImage in
                        return await viewModel.updateManager(updatedManager, newImage: newImage)
                    }
                )
            }
        }
        .onChange(of: selectedPerformanceSort) { _, newVal in
            if newVal != .none { isRecentlyAddedSort = false }
        }
        .onChange(of: isRecentlyAddedSort) { _, newVal in
            if newVal { selectedPerformanceSort = .none }
        }
        .task {
            await viewModel.loadManagers()
        }
        .onChange(of: navStore.selectedTab) { _, newTab in
            if newTab == .managers {
                Task {
                    await viewModel.loadManagers()
                }
            }
        }
        .refreshable {
            await viewModel.loadManagers()
        }
        .alert("Archive Manager", isPresented: Binding(
            get: { managerToDelete != nil },
            set: { if !$0 { managerToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                managerToDelete = nil
            }
            Button("Archive", role: .destructive) {
                if let manager = managerToDelete {
                    Task {
                        _ = await viewModel.deleteManager(id: manager.id)
                    }
                    managerToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to archive this manager? Their access will be revoked but their records will remain.")
        }
    }
}

// MARK: - Top Performance Card

struct TopPerformanceCard: View {
    @Environment(AppTheme.self) private var theme
    let manager: DisplayManager
    let rank: Int
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var onResetPassword: ((String) async -> Bool)? = nil
    var onUpdate: ((DisplayManager, UIImage?) async -> String?)? = nil

    private var rankColor: Color {
        switch rank {
        case 1:  return Color(hex: "D4A017")  // gold
        case 2:  return Color(hex: "8B8B8D")  // silver
        default: return Color(hex: "A0522D")  // bronze
        }
    }

    var body: some View {
        NavigationLink(destination: ManagerDetailView(manager: manager, onResetPassword: onResetPassword, onDelete: onDelete, onUpdate: onUpdate)) {
            ZStack(alignment: .topLeading) {
                // Rank-colored gradient card background
                RoundedRectangle(cornerRadius: RSMSRadius.extraLarge)
                    .fill(
                        LinearGradient(
                            colors: [
                                rankColor.opacity(0.18),
                                rankColor.opacity(0.04),
                                theme.cardBackground
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: RSMSRadius.extraLarge)
                            .stroke(rankColor.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(color: rankColor.opacity(0.12), radius: 10, x: 0, y: 4)

                VStack(spacing: 0) {
                    // Middle: Avatar + Name + Store
                    HStack(alignment: .center, spacing: RSMSSpacing.md) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(theme.burgundy.opacity(0.1))
                                .frame(width: 75, height: 75)
                            if let urlString = manager.imageUrl, let url = URL(string: urlString) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 75, height: 75)
                                        .clipShape(Circle())
                                } placeholder: {
                                    ProgressView()
                                        .frame(width: 75, height: 75)
                                }
                            } else {
                                Image(systemName: "person.fill")
                                    .foregroundColor(theme.burgundy)
                                    .font(.system(size: 24))
                            }
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(manager.name.components(separatedBy: " ").first ?? manager.name)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(theme.primaryText)
                                .lineLimit(1)

                            Text(manager.storeName)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.secondaryText)
                                .lineLimit(1)
                                
                            Text(manager.country)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(theme.secondaryText.opacity(0.8))
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .padding(.top, RSMSSpacing.sm)

                    Spacer(minLength: RSMSSpacing.sm)

                    // Bottom Row: Revenue
                    HStack(alignment: .bottom) {
                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Revenue")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(theme.secondaryText)
                            Text(manager.revenue)
                                .font(.system(size: 19, weight: .bold, design: .rounded))
                                .foregroundColor(theme.primaryText)
                        }
                    }
                }
                .padding(16)
            }
            .frame(width: 300, height: 170)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onEdit?()
            } label: {
                Label {
                    Text("Edit")
                } icon: {
                    Image(systemName: "square.and.pencil")
                        .renderingMode(.template)
                        .foregroundColor(theme.primaryText)
                }
            }
            .tint(.black)

            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label {
                    Text("Archive")
                } icon: {
                    Image(systemName: "archivebox")
                        .renderingMode(.template)
                        .foregroundColor(.red)
                }
            }
            .tint(.red)
        }
        .tint(.black)
    }
}

// MARK: - Manager List Card

struct ManagerListCard: View {
    @Environment(AppTheme.self) private var theme
    let manager: DisplayManager
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil
    var onResetPassword: ((String) async -> Bool)? = nil
    var onUpdate: ((DisplayManager, UIImage?) async -> String?)? = nil

    var body: some View {
        NavigationLink(destination: ManagerDetailView(manager: manager, onResetPassword: onResetPassword, onDelete: onDelete, onUpdate: onUpdate)) {
            HStack(spacing: RSMSSpacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(theme.burgundy.opacity(0.1))
                        .frame(width: 55, height: 55)
                    if let urlString = manager.imageUrl, let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 55, height: 55)
                                .clipShape(Circle())
                        } placeholder: {
                            ProgressView()
                                .frame(width: 55, height: 55)
                        }
                    } else {
                        Image(systemName: "person.fill")
                            .foregroundColor(theme.burgundy)
                            .font(.system(size: 22))
                    }
                }

                // Text info
                VStack(alignment: .leading, spacing: 4) {
                    Text(manager.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(theme.primaryText)
                    Text("\(manager.storeName), \(manager.country)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.secondaryText)
                }

                Spacer()

                if !manager.isActive {
                    Text("Archived")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gray)
                        .cornerRadius(6)
                } else {
                    // Chevron
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.secondaryText)
                }
            }
            .padding(16)
            .frame(minHeight: 85)
            .background(theme.cardBackground)
            .cornerRadius(RSMSRadius.extraLarge)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: RSMSRadius.large)
                    .stroke(theme.cardBorder, lineWidth: 1)
            )
            .opacity(manager.isActive ? 1.0 : 0.6)
            .grayscale(manager.isActive ? 0.0 : 0.8)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onEdit?()
            } label: {
                Label {
                    Text("Edit")
                } icon: {
                    Image(systemName: "square.and.pencil")
                        .renderingMode(.template)
                        .foregroundColor(theme.primaryText)
                }
            }
            .tint(.black)

            Button(role: .destructive) {
                onDelete?()
            } label: {
                Label {
                    Text("Archive")
                } icon: {
                    Image(systemName: "archivebox")
                        .renderingMode(.template)
                        .foregroundColor(.red)
                }
            }
            .tint(.red)
        }
        .tint(.black)
    }
}

#Preview {
    AdminManagersView(
        isAddManagerPresented: .constant(false),
        searchText: .constant("")
    )
    .environment(AdminNavigationStore())
}
