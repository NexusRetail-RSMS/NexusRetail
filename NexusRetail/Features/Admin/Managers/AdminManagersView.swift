//
//  AdminManagersView.swift
//  NexusRetail
//

import SwiftUI

// MARK: - Data Model

struct DisplayManager: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var storeName: String
    var country: String
    var performanceScore: Int
    var revenue: String
    var photoData: Data? = nil
    // Contact info
    var phone: String = ""
    var email: String = ""
    var address: String = ""
    // Stats
    var productsSold: Int = 0
    var createdAt: Date = Date()
}

@Observable
class ManagersStore {
    static let shared = ManagersStore()

    var managers: [DisplayManager] = [
        DisplayManager(name: "Harman Singh",  storeName: "Nexus Flagship Store", country: "United States",  performanceScore: 98, revenue: "$152K", phone: "+1 (555) 234-5678", email: "harman@nexusretail.com",  address: "123 Main St, San Francisco, CA", productsSold: 1240, createdAt: Date().addingTimeInterval(-86400 * 5)),
        DisplayManager(name: "Sarah Jenkins", storeName: "Downtown Plaza",       country: "United Kingdom", performanceScore: 92, revenue: "$134K", phone: "+44 20 7946 0958",   email: "sarah@nexusretail.com",   address: "45 Oxford St, London, UK",          productsSold: 980, createdAt: Date().addingTimeInterval(-86400 * 4)),
        DisplayManager(name: "Michael Chang", storeName: "Metro Mall Store",     country: "Canada",         performanceScore: 87, revenue: "$118K", phone: "+1 (416) 555-0173", email: "michael@nexusretail.com", address: "200 King St W, Toronto, ON",       productsSold: 820, createdAt: Date().addingTimeInterval(-86400 * 3)),
        DisplayManager(name: "Jessica Lee",   storeName: "Westfield Outlet",     country: "Australia",      performanceScore: 76, revenue: "$97K",  phone: "+61 2 9876 5432",   email: "jessica@nexusretail.com", address: "500 George St, Sydney, NSW",     productsSold: 640, createdAt: Date().addingTimeInterval(-86400 * 2)),
        DisplayManager(name: "Elena Rostova", storeName: "Westside Boutique",    country: "Germany",        performanceScore: 65, revenue: "$84K",  phone: "+49 30 12345678",   email: "elena@nexusretail.com",   address: "Kurfürstendamm 12, Berlin",      productsSold: 510, createdAt: Date().addingTimeInterval(-86400 * 1)),
    ]

    func add(manager: DisplayManager) {
        managers.append(manager)
        managers.sort { $0.performanceScore > $1.performanceScore }
    }

    func update(manager: DisplayManager) {
        if let idx = managers.firstIndex(where: { $0.id == manager.id }) {
            managers[idx] = manager
            managers.sort { $0.performanceScore > $1.performanceScore }
        }
    }

    func delete(manager: DisplayManager) {
        managers.removeAll(where: { $0.id == manager.id })
    }
}

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
    if score >= 90 { return RSMSColors.success }
    if score >= 75 { return RSMSColors.warning }
    return RSMSColors.error
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
    case topToLow   = "Top to Low"
    case lowToTop   = "Low to Top"
    }

// MARK: - Main View

struct AdminManagersView: View {
    @State private var searchText = ""
    @State private var topPerformerPage = 0
    @State private var scrolledID: UUID?
    @State private var selectedCountryFilter = "All"
    @State private var selectedPerformanceSort: PerformanceSortOrder = .none
    @State private var editingManager: DisplayManager? = nil
    @State private var isRecentlyAddedSort = false

    private let topCount = 3

    private var allCountries: [String] {
        let names = ManagersStore.shared.managers.map { $0.country }
        return Array(Set(names)).sorted()
    }

    var filteredManagers: [DisplayManager] {
        var result = ManagersStore.shared.managers.filter { manager in
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
            RSMSColors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: RSMSSpacing.xl) {

                    // MARK: Search Bar
                    HStack(spacing: RSMSSpacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(RSMSColors.secondaryText)
                        TextField("Search managers, stores...", text: $searchText)
                            .font(RSMSFonts.body)
                            .foregroundColor(RSMSColors.primaryText)
                        if !searchText.isEmpty {
                            Button { searchText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(RSMSColors.secondaryText)
                            }
                        }
                    }
                    .padding(RSMSSpacing.sm)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(RSMSRadius.small)
                    .padding(.horizontal, RSMSSpacing.lg)

                    // MARK: Top Performers
                    VStack(alignment: .leading, spacing: RSMSSpacing.sm) {
                        Text("Top Performers")
                            .font(RSMSFonts.headline)
                            .foregroundColor(RSMSColors.darkBrown)
                            .padding(.horizontal, RSMSSpacing.lg)

                        let topManagers = Array(ManagersStore.shared.managers.prefix(topCount).enumerated())
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: RSMSSpacing.md) {
                                ForEach(topManagers, id: \.element.id) { index, manager in
                                    TopPerformanceCard(manager: manager, rank: index + 1) {
                                        editingManager = manager
                                    }
                                }
                            }
                            .scrollTargetLayout()
                            .padding(.horizontal, RSMSSpacing.lg)
                        }
                        .scrollTargetBehavior(.viewAligned)
                        .scrollPosition(id: $scrolledID)
                        .onChange(of: scrolledID) { _, newID in
                            if let newID = newID, let idx = topManagers.firstIndex(where: { $0.element.id == newID }) {
                                topPerformerPage = idx
                            }
                        }

                        // Page dots
                        HStack(spacing: 6) {
                            ForEach(0..<topCount, id: \.self) { i in
                                Circle()
                                    .fill(i == topPerformerPage ? RSMSColors.burgundy : RSMSColors.cardBorder)
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
                            .foregroundColor(RSMSColors.darkBrown)
                        Spacer()
                        Menu {
                            Picker(selection: $selectedCountryFilter) {
                                Text("All Countries").tag("All")
                                ForEach(allCountries, id: \.self) { country in
                                    Text("\(country) \(flagEmoji(for: country))").tag(country)
                                }
                            } label: {
                                Label("Country", systemImage: "globe")
                            }
                            .pickerStyle(.menu)
                            
                            Picker(selection: $selectedPerformanceSort) {
                                ForEach(PerformanceSortOrder.allCases, id: \.self) { option in
                                    Text(option.rawValue).tag(option)
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
                                .foregroundColor(isFiltered ? RSMSColors.burgundy : RSMSColors.primaryText)
                                .frame(width: 40, height: 40)
                                .background(isFiltered
                                    ? RSMSColors.burgundy.opacity(0.12)
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
                                .foregroundColor(RSMSColors.secondaryText)
                            Text("Not Present")
                                .font(RSMSFonts.headline)
                                .foregroundColor(RSMSColors.primaryText)
                            Text("No manager or store matches '\(searchText)'.")
                                .font(RSMSFonts.subheadline)
                                .foregroundColor(RSMSColors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                        .padding(.horizontal, RSMSSpacing.xxxl)
                    } else {
                        VStack(spacing: RSMSSpacing.md) {
                            ForEach(filteredManagers) { manager in
                                ManagerListCard(manager: manager) {
                                    editingManager = manager
                                }
                            }
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.bottom, RSMSSpacing.xl)
                    }
                }
                .padding(.top, RSMSSpacing.sm)
            }
        }
        .sheet(item: $editingManager) { mgr in
            if let idx = ManagersStore.shared.managers.firstIndex(where: { $0.id == mgr.id }) {
                EditManagerSheet(manager: Binding(
                    get: { ManagersStore.shared.managers[idx] },
                    set: { newMgr in
                        ManagersStore.shared.update(manager: newMgr)
                    }
                ))
            } else {
                EditManagerSheet(manager: .constant(mgr))
            }
        }
        .onChange(of: selectedPerformanceSort) { _, newVal in
            if newVal != .none { isRecentlyAddedSort = false }
        }
        .onChange(of: isRecentlyAddedSort) { _, newVal in
            if newVal { selectedPerformanceSort = .none }
        }
    }
}

// MARK: - Top Performance Card

struct TopPerformanceCard: View {
    let manager: DisplayManager
    let rank: Int
    var onEdit: (() -> Void)? = nil

    private var rankColor: Color {
        switch rank {
        case 1:  return Color(hex: "D4A017")  // gold
        case 2:  return Color(hex: "8B8B8D")  // silver
        default: return Color(hex: "A0522D")  // bronze
        }
    }

    var body: some View {
        NavigationLink(destination: ManagerDetailView(manager: manager)) {
            ZStack(alignment: .topLeading) {
                // Card background
                RoundedRectangle(cornerRadius: RSMSRadius.large)
                    .fill(RSMSColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: RSMSRadius.large)
                            .stroke(RSMSColors.cardBorder, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)

                VStack(spacing: 0) {
                    // Top Row: Performance Score badge
                    HStack {
                        Spacer()
                        Text("\(manager.performanceScore)%")
                            .font(RSMSFonts.caption.weight(.semibold))
                            .foregroundColor(performanceColor(for: manager.performanceScore))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(performanceColor(for: manager.performanceScore).opacity(0.12))
                            .cornerRadius(RSMSRadius.small)
                    }

                    // Middle: Avatar + Name + Store
                    HStack(alignment: .center, spacing: RSMSSpacing.md) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(RSMSColors.burgundy.opacity(0.1))
                                .frame(width: 44, height: 44)
                            if let data = manager.photoData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 44, height: 44)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .foregroundColor(RSMSColors.burgundy)
                                    .font(.system(size: 18))
                            }
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(manager.name)
                                .font(RSMSFonts.headline)
                                .foregroundColor(RSMSColors.primaryText)
                                .lineLimit(1)

                            Text(manager.storeName)
                                .font(RSMSFonts.caption)
                                .foregroundColor(RSMSColors.secondaryText)
                                .lineLimit(1)
                        }

                        Spacer()
                    }
                    .padding(.top, RSMSSpacing.xs)

                    Spacer(minLength: RSMSSpacing.sm)

                    // Bottom Row: Country & Revenue
                    HStack(alignment: .bottom) {
                        HStack(spacing: 4) {
                            Text(flagEmoji(for: manager.country))
                                .font(RSMSFonts.caption)
                            Text(manager.country)
                                .font(RSMSFonts.caption)
                                .foregroundColor(RSMSColors.secondaryText)
                                .lineLimit(1)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 1) {
                            Text("Revenue")
                                .font(.system(size: 10))
                                .foregroundColor(RSMSColors.secondaryText)
                            Text(manager.revenue)
                                .font(RSMSFonts.headline)
                                .foregroundColor(RSMSColors.primaryText)
                        }
                    }
                }
                .padding(RSMSSpacing.md)
                .frame(height: 140)

                // Bookmark badge (top-left)
                ZStack {
                    BookmarkShape()
                        .fill(rankColor)
                        .frame(width: 24, height: 32)
                        .shadow(color: rankColor.opacity(0.3), radius: 3, x: 0, y: 2)
                    Text("\(rank)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .offset(y: -2)
                }
                .offset(x: 24, y: 0)
            }
            .frame(width: 280)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onEdit?()
            } label: {
                Label("Edit", systemImage: "square.and.pencil")
            }
            Button(role: .destructive) {
                ManagersStore.shared.delete(manager: manager)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Manager List Card

struct ManagerListCard: View {
    let manager: DisplayManager
    var onEdit: (() -> Void)? = nil

    var body: some View {
        NavigationLink(destination: ManagerDetailView(manager: manager)) {
            HStack(spacing: RSMSSpacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(RSMSColors.burgundy.opacity(0.1))
                        .frame(width: 48, height: 48)
                    if let data = manager.photoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .foregroundColor(RSMSColors.burgundy)
                            .font(.system(size: 20))
                    }
                }

                // Text info
                VStack(alignment: .leading, spacing: 3) {
                    Text(manager.storeName)
                        .font(RSMSFonts.subheadline.weight(.semibold))
                        .foregroundColor(RSMSColors.primaryText)
                    Text(manager.name)
                        .font(RSMSFonts.subheadline)
                        .foregroundColor(RSMSColors.secondaryText)
                    HStack(spacing: 4) {
                        Text(flagEmoji(for: manager.country))
                            .font(RSMSFonts.caption)
                        Text(manager.country)
                            .font(RSMSFonts.caption)
                            .foregroundColor(RSMSColors.secondaryText)
                    }
                }

                Spacer()

                // Performance badge
                Text("\(manager.performanceScore)%")
                    .font(RSMSFonts.caption.weight(.semibold))
                    .foregroundColor(performanceColor(for: manager.performanceScore))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(performanceColor(for: manager.performanceScore).opacity(0.12))
                    .cornerRadius(RSMSRadius.small)

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            .padding(RSMSSpacing.lg)
            .background(RSMSColors.cardBackground)
            .cornerRadius(RSMSRadius.large)
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: RSMSRadius.large)
                    .stroke(RSMSColors.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onEdit?()
            } label: {
                Label("Edit", systemImage: "square.and.pencil")
            }
            Button(role: .destructive) {
                ManagersStore.shared.delete(manager: manager)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
