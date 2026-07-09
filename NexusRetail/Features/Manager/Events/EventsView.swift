import SwiftUI

struct EventsView: View {
    @Environment(AppTheme.self) private var theme
    @State private var viewModel = EventsViewModel()
    @State private var showingCreateEvent = false
    @State private var searchText = ""
    @State private var selectedFilter: EventFilter = .all
    @Environment(SessionStore.self) private var sessionStore
    
    private var filteredEvents: [SupabaseEvent] {
        // Sort all events by date and time (earliest first)
        let sorted = viewModel.events.sorted { 
            if $0.eventDate == $1.eventDate {
                return $0.startTime < $1.startTime
            }
            return $0.eventDate < $1.eventDate 
        }
        
        // Group by status in the required order: Today -> Upcoming -> Completed
        let today = sorted.filter { $0.status == .today }
        let upcoming = sorted.filter { $0.status == .upcoming }
        let completed = sorted.filter { $0.status == .completed }
        
        var orderedEvents = today + upcoming + completed
        
        // Apply filter
        if selectedFilter != .all {
            orderedEvents = orderedEvents.filter {
                switch selectedFilter {
                case .all: return true
                case .today: return $0.status == .today
                case .upcoming: return $0.status == .upcoming
                case .completed: return $0.status == .completed
                }
            }
        }
        
        // Apply search
        if !searchText.isEmpty {
            orderedEvents = orderedEvents.filter { event in
                event.title.localizedCaseInsensitiveContains(searchText) ||
                (event.eventType ?? "").localizedCaseInsensitiveContains(searchText) ||
                (event.venueStr).localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return orderedEvents
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Fixed Header
                    headerRow
                    
                    // Fixed Search Bar
                    searchBar
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.bottom, 16)
                    
                    if filteredEvents.isEmpty {
                        Spacer()
                        if searchText.isEmpty {
                            emptyState
                        } else {
                            emptySearchState
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 24) {
                                // Event List
                                LazyVStack(spacing: 16) {
                                    ForEach(Array(filteredEvents.enumerated()), id: \.element.id) { index, event in
                                        let isNext = (index == filteredEvents.firstIndex(where: { $0.status == .upcoming }))
                                        
                                        NavigationLink(destination: EventDetailsView(viewModel: viewModel, eventId: event.id)) {
                                            EventCard(event: event, isNextEvent: isNext)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, RSMSSpacing.lg)
                            }
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCreateEvent) {
                CreateEventView(viewModel: viewModel)
            }
            .task {
                let storeID = sessionStore.currentUser?.storeID
                await viewModel.fetchEvents(for: storeID)
                await viewModel.fetchCustomers(for: storeID)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerRow: some View {
        HStack(alignment: .center) {
            Text("Events")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(theme.primaryText)
            
            Spacer()
            
            Button {
                showingCreateEvent = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(theme.burgundy)
                    .frame(width: 44, height: 44)
                    .background(theme.burgundy.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, RSMSSpacing.sm)
        .padding(.bottom, 8)
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            NexusSearchBar(text: $searchText, placeholder: "Search events...")
            
            Menu {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(EventFilter.allCases, id: \.self) { filter in
                        Text(localized: filter.rawValue).tag(filter)
                    }
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(theme.burgundy.opacity(0.08))
                        .frame(width: 48, height: 48)

                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(theme.burgundy)
                }
            }
        }
    }
    
    // MARK: - Empty States
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(theme.burgundy.opacity(0.5))
                .padding(.bottom, 8)
            
            Text("No Events Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.primaryText)
        }
    }
    
    private var emptySearchState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.bottom, 8)
            
            Text("No Events Found")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.primaryText)
            
            Text("Try searching using a different event name or category.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

// MARK: - Event Card

struct EventCard: View {
    @Environment(AppTheme.self) private var theme
    let event: SupabaseEvent
    var isNextEvent: Bool = false
    
    private var statusColor: Color {
        switch event.status {
        case .upcoming: return .blue
        case .today: return .orange
        case .completed: return .green
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: event.eventDate)
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let start = formatter.string(from: event.startTime)
        let end = formatter.string(from: event.endTime ?? event.startTime)
        return "\(start) – \(end)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Banner Placeholder
            ZStack(alignment: .topLeading) {
                ZStack(alignment: .bottomLeading) {
                    Group {
                        if let urlString = event.bannerImageURL, let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray.opacity(0.1)
                            }
                            .frame(height: 120)
                            .clipped()
                        } else {
                            Rectangle()
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: 120)
                                .overlay(
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.gray.opacity(0.3))
                                )
                        }
                    }
                    
                    // Status Badge
                    Text(localized: event.status.rawValue)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(statusColor)
                        .cornerRadius(8)
                        .padding(12)
                }
                
                // Next Event Badge
                if isNextEvent {
                    Text("Next Event")
                        .font(.system(size: 11, weight: .heavy))
                        .foregroundColor(theme.burgundy)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(theme.cardBackground)
                        .cornerRadius(6)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .padding(12)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // Event Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(theme.primaryText)
                        .lineLimit(1)
                    
                    Text(localized: event.eventType ?? "Custom")
                        .font(.system(size: 14))
                        .foregroundColor(theme.burgundy)
                }
                
                // Date & Time
                HStack(spacing: 16) {
                    Label(formattedDate, systemImage: "calendar")
                    Label(formattedTime, systemImage: "clock")
                }
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                
                // Venue
                Label(event.venueStr, systemImage: "mappin.and.ellipse")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Divider()
                    .padding(.vertical, 4)
                
                // Bottom Row
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Invited")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("\(event.invitedCount) Guests")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.primaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray.opacity(0.5))
                        .padding(.leading, 8)
                }
            }
            .padding(16)
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(theme.cardBackground)
                
                if isNextEvent {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(theme.burgundy.opacity(0.3), lineWidth: 1)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(
            color: isNextEvent ? theme.burgundy.opacity(0.15) : Color.black.opacity(0.05),
            radius: isNextEvent ? 12 : 8,
            x: 0,
            y: isNextEvent ? 4 : 2
        )
        .animation(.easeInOut, value: isNextEvent)
    }
}
