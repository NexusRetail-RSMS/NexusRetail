import SwiftUI

struct EventsView: View {
    @State private var viewModel = EventsViewModel()
    @State private var showingCreateEvent = false
    @State private var searchText = ""
    
    private var filteredEvents: [MockEvent] {
        let sorted = viewModel.events.sorted { $0.startDate < $1.startDate }
        if searchText.isEmpty {
            return sorted
        } else {
            return sorted.filter { event in
                event.title.localizedCaseInsensitiveContains(searchText) ||
                event.eventType.rawValue.localizedCaseInsensitiveContains(searchText) ||
                event.venue.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Fixed Header
                    headerRow
                    
                    // Fixed Search Bar
                    searchBar
                        .padding(.horizontal, RSMSSpacing.lg)
                        .padding(.bottom, 16)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            if filteredEvents.isEmpty {
                                if searchText.isEmpty {
                                    emptyState
                                        .padding(.top, 60)
                                } else {
                                    emptySearchState
                                        .padding(.top, 60)
                                }
                            } else {
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
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingCreateEvent) {
                CreateEventView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Header
    
    private var headerRow: some View {
        HStack(alignment: .center) {
            Text("Events")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(RSMSColors.primaryText)
            
            Spacer()
            
            Button {
                showingCreateEvent = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(RSMSColors.burgundy)
                    .frame(width: 44, height: 44)
                    .background(RSMSColors.burgundy.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, RSMSSpacing.sm)
        .padding(.bottom, 8)
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField("Search events...", text: $searchText)
                .font(.body)
                .foregroundColor(RSMSColors.primaryText)
            
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
        .animation(.easeInOut, value: searchText)
    }
    
    // MARK: - Empty States
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(RSMSColors.burgundy.opacity(0.5))
                .padding(.bottom, 8)
            
            Text("No Events Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(RSMSColors.primaryText)
            
            Text("Create your first store event to invite customers and showcase new products.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showingCreateEvent = true
            } label: {
                Text("Create Event")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(RSMSColors.burgundy)
                    .cornerRadius(25)
            }
            .padding(.horizontal, 40)
            .padding(.top, 16)
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
                .foregroundColor(RSMSColors.primaryText)
            
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
    let event: MockEvent
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
        return formatter.string(from: event.startDate)
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: event.startDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Banner Placeholder
            ZStack(alignment: .topLeading) {
                ZStack(alignment: .bottomLeading) {
                    Group {
                        if let imageData = event.bannerImageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
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
                    Text(event.status.rawValue)
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
                        .foregroundColor(RSMSColors.burgundy)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white)
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
                        .foregroundColor(RSMSColors.primaryText)
                        .lineLimit(1)
                    
                    Text(event.eventType.rawValue)
                        .font(.system(size: 14))
                        .foregroundColor(RSMSColors.burgundy)
                }
                
                // Date & Time
                HStack(spacing: 16) {
                    Label(formattedDate, systemImage: "calendar")
                    Label(formattedTime, systemImage: "clock")
                }
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                
                // Venue
                Label(event.venue, systemImage: "mappin.and.ellipse")
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
                            .foregroundColor(RSMSColors.primaryText)
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
                    .fill(Color.white)
                
                if isNextEvent {
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(RSMSColors.burgundy.opacity(0.3), lineWidth: 1)
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(
            color: isNextEvent ? RSMSColors.burgundy.opacity(0.15) : Color.black.opacity(0.05),
            radius: isNextEvent ? 12 : 8,
            x: 0,
            y: isNextEvent ? 4 : 2
        )
        .animation(.easeInOut, value: isNextEvent)
    }
}
