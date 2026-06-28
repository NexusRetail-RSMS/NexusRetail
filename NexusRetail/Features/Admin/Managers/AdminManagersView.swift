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
    if score >= 90 { return Color(red: 0.13, green: 0.77, blue: 0.37) }
    if score >= 75 { return Color(red: 1.0,  green: 0.60, blue: 0.0)  }
    return Color(red: 0.95, green: 0.27, blue: 0.27)
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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search managers, stores...", text: $searchText)
                        .foregroundColor(.primary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(Color(UIColor.systemGray6))
                .cornerRadius(24)
                .padding(.horizontal)

                // MARK: Top Performers
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Top Performers")
                            .font(.title2.bold())
                    }
                    .padding(.horizontal)

                    let topManagers = Array(ManagersStore.shared.managers.prefix(topCount).enumerated())
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(topManagers, id: \.element.id) { index, manager in
                                TopPerformanceCard(manager: manager, rank: index + 1) {
                                    editingManager = manager
                                }
                            }
                        }
                        .scrollTargetLayout()
                        .padding(.horizontal)
                        .padding(.vertical, 2)  // reduced vertical padding to decrease gap
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
                                .fill(i == topPerformerPage ? Color.blue : Color(UIColor.systemGray4))
                                .frame(width: i == topPerformerPage ? 8 : 6,
                                       height: i == topPerformerPage ? 8 : 6)
                                .animation(.spring(response: 0.3), value: topPerformerPage)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
                }


                // MARK: All Managers Header
                HStack(alignment: .center) {
                    Text("All Managers")
                        .font(.title2.bold())
                    Spacer()
                    Menu {
                        Picker(selection: $selectedCountryFilter) {
                            Text("All Countries").tag("All")
                            ForEach(allCountries, id: \.self) { country in
                                Text("\(country) \(flagEmoji(for: country))").tag(country)
                            }
                        } label: {
                            Label {
                                Text("Country\n").font(.system(size: 16, weight: .medium)) + Text(selectedCountryFilter == "All" ? "All" : selectedCountryFilter).font(.system(size: 9)).foregroundColor(.secondary)
                            } icon: {
                                Image(systemName: "globe")
                            }
                        }
                        .pickerStyle(.menu)
                        
                        Picker(selection: $selectedPerformanceSort) {
                            ForEach(PerformanceSortOrder.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        } label: {
                            Label {
                                Text("Performance\n").font(.system(size: 16, weight: .medium)) + Text(selectedPerformanceSort.rawValue).font(.system(size: 9)).foregroundColor(.secondary)
                            } icon: {
                                Image(systemName: "chart.bar.fill")
                            }
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
                            .foregroundColor(isFiltered ? .blue : .primary)
                            .frame(width: 40, height: 40)
                            .background(isFiltered
                                ? Color.blue.opacity(0.12)
                                : Color(UIColor.systemGray6))
                            .clipShape(Circle())
                    }
                    .id("\(selectedCountryFilter)_\(selectedPerformanceSort.rawValue)")
                }
                .padding(.horizontal)

                // MARK: Manager List
                if filteredManagers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 44))
                            .foregroundColor(.secondary)
                        Text("Not Present")
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                        Text("No manager or store matches '\(searchText)'.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                    .padding(.horizontal, 32)
                } else {
                    VStack(spacing: 10) {
                        ForEach(filteredManagers) { manager in
                            ManagerListCard(manager: manager) {
                                editingManager = manager
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .padding(.top, 8)
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
        case 1:  return Color(red: 1.00, green: 0.72, blue: 0.16)  // gold
        case 2:  return Color(red: 0.72, green: 0.72, blue: 0.75)  // silver
        default: return Color(red: 0.80, green: 0.55, blue: 0.30)  // bronze
        }
    }

    var body: some View {
        NavigationLink(destination: ManagerDetailView(manager: manager)) {
            ZStack(alignment: .topLeading) {
                // Card
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(UIColor.systemBackground))
                    // shadow removed as requested
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(UIColor.systemGray5), lineWidth: 1)
                    )

                VStack(spacing: 0) {
                    // Top Row: Performance Score (Top Right)
                    HStack {
                        Spacer()
                        Text("\(manager.performanceScore)%")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(performanceColor(for: manager.performanceScore))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(performanceColor(for: manager.performanceScore).opacity(0.13))
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    // Middle Row: Profile, Name, and Store Name vertically aligned at center of card
                    HStack(alignment: .center, spacing: 16) {
                        // Avatar (Left Center)
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.12))
                                .frame(width: 52, height: 52)
                            if let data = manager.photoData, let uiImage = UIImage(data: data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 52, height: 52)
                                    .clipShape(Circle())
                            } else {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 22))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(manager.name)
                                .font(.title3.bold())
                                .foregroundColor(.primary)
                            
                            Text(manager.storeName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    // Bottom Row: Country & Revenue
                    HStack(alignment: .bottom) {
                        HStack(spacing: 4) {
                            Text(flagEmoji(for: manager.country))
                                .font(.caption)
                            Text(manager.country)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("Revenue")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(manager.revenue)
                                .font(.title3.weight(.bold))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(16)
                .frame(height: 160)

                // Bookmark badge (top-left)
                ZStack {
                    BookmarkShape()
                        .fill(rankColor)
                        .frame(width: 26, height: 36)
                        .shadow(color: rankColor.opacity(0.4), radius: 4, x: 0, y: 2)
                    Text("\(rank)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .offset(y: -2)
                }
                .offset(x: 29, y: 0)
            }
            .frame(width: 300)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onEdit?()
            } label: {
                Label("Edit", systemImage: "square.and.pencil")
            }
            .tint(.black)
            .foregroundStyle(.black)
            Button(role: .destructive) {
                ManagersStore.shared.delete(manager: manager)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
    }
}

// MARK: - Manager List Card

struct ManagerListCard: View {
    let manager: DisplayManager
    var onEdit: (() -> Void)? = nil

    var body: some View {
        NavigationLink(destination: ManagerDetailView(manager: manager)) {
            HStack(spacing: 14) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 50, height: 50)
                    if let data = manager.photoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 50)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 22))
                    }
                }

                // Text info
                VStack(alignment: .leading, spacing: 3) {
                    Text(manager.storeName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Text(manager.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Text(flagEmoji(for: manager.country))
                            .font(.caption)
                        Text(manager.country)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Performance badge
                Text("\(manager.performanceScore)%")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(performanceColor(for: manager.performanceScore))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(performanceColor(for: manager.performanceScore).opacity(0.12))
                    .cornerRadius(12)

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(18)
            .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onEdit?()
            } label: {
                Label("Edit", systemImage: "square.and.pencil")
            }
            .tint(.black)
            .foregroundStyle(.black)
            Button(role: .destructive) {
                ManagersStore.shared.delete(manager: manager)
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
    }
}
