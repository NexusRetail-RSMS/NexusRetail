import SwiftUI

struct EventsView: View {
    @Environment(AppTheme.self) private var theme
    @State private var viewModel = EventsViewModel()
    @State private var showingCreateEvent = false
    @State private var searchText = ""
    @State private var selectedFilter: EventFilter = .all
    @Environment(SessionStore.self) private var sessionStore

    private var filteredEvents: [SupabaseEvent] {
        let sorted = viewModel.events.sorted {
            if $0.eventDate == $1.eventDate {
                return $0.startTime < $1.startTime
            }
            return $0.eventDate < $1.eventDate
        }

        let today = sorted.filter { $0.status == .today }
        let upcoming = sorted.filter { $0.status == .upcoming }
        let completed = sorted.filter { $0.status == .completed }

        var orderedEvents = today + upcoming + completed

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

        if !searchText.isEmpty {
            orderedEvents = orderedEvents.filter { event in
                event.title.localizedCaseInsensitiveContains(searchText) ||
                (event.eventType ?? "").localizedCaseInsensitiveContains(searchText) ||
                event.venueStr.localizedCaseInsensitiveContains(searchText)
            }
        }

        return orderedEvents
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                headerRow

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
                        LazyVStack(spacing: 18) {
                            ForEach(filteredEvents) { event in
                                NavigationLink(destination: EventDetailsView(viewModel: viewModel, eventId: event.id)) {
                                    EventCard(event: event)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
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

            // Paint instantly from whatever we last saved to disk, so the list
            // never opens blank while the network call is in flight.
            if let storeID = storeID,
               let cached = await PersistentCache.shared.load(
                   [SupabaseEvent].self,
                   forKey: "events-\(storeID.uuidString)"
               ) {
                viewModel.events = cached
                await ImageCache.shared.prefetch(cached.compactMap { $0.bannerImageURL })
            }

            // Then quietly refresh from Supabase and re-cache the fresh result.
            await viewModel.fetchEvents(for: storeID)
            await viewModel.fetchCustomers(for: storeID)

            if let storeID = storeID {
                await PersistentCache.shared.save(
                    viewModel.events,
                    forKey: "events-\(storeID.uuidString)"
                )
                await ImageCache.shared.prefetch(viewModel.events.compactMap { $0.bannerImageURL })
            }
        }
    }

    private var headerRow: some View {
        HStack(alignment: .center) {
            Text("Events")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(theme.primaryText)

            Spacer()

            HStack(spacing: 12) {
                Menu {
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(EventFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.burgundy)
                        .frame(width: 44, height: 44)
                }

                Button {
                    showingCreateEvent = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.burgundy)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Create event")
            }
            .background(theme.burgundy.opacity(0.08))
            .clipShape(Capsule())
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, RSMSSpacing.sm)
        .padding(.bottom, 8)
    }

    private var searchBar: some View {
        NexusSearchBar(text: $searchText, placeholder: "Search events...")
    }

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

struct EventCard: View {
    @Environment(AppTheme.self) private var theme
    let event: SupabaseEvent

    private var monthAbbreviation: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: event.eventDate).capitalized
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
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
            ZStack(alignment: .bottom) {
                Group {
                    if let urlString = event.bannerImageURL, !urlString.isEmpty {
                        CachedAsyncImage(
                            url: URL(string: urlString),
                            content: { $0.resizable().aspectRatio(contentMode: .fill) },
                            placeholder: { theme.elevatedSurface }
                        )
                    } else {
                        Rectangle()
                            .fill(theme.elevatedSurface)
                            .overlay(
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(theme.tertiaryText)
                            )
                    }
                }
                .frame(height: 180)
                .clipped()

                LinearGradient(
                    colors: [Color.black.opacity(0), Color.black.opacity(0.55)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: 160)

                VStack(alignment: .leading, spacing: 2) {
                    Text(event.eventType ?? "Custom")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.75))

                    Text(event.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
            .overlay(alignment: .topLeading) {
                HStack(alignment: .center, spacing: 4) {
                    Text(monthAbbreviation)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.primaryText)
                    Text(dayNumber)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.primaryText)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding(12)
            }

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Label(formattedTime, systemImage: "clock")
                    Label(event.venueStr, systemImage: "mappin.and.ellipse")
                        .lineLimit(1)
                }
                .font(.system(size: 13))
                .foregroundColor(theme.primaryText)

                Divider()
                    .background(theme.divider)

                HStack {
                    if event.invitedCount > 0 {
                        HStack(alignment: .center, spacing: 6) {
                            Text("\(event.invitedCount)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(theme.primaryText)

                            Text("guests invited")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundColor(theme.tertiaryText)
                        }
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("View details")
                        Image(systemName: "arrow.right")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.accent)
                }
            }
            .padding(16)
        }
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.cardBorder, lineWidth: 0.5)
        )
    }
}

#Preview("Event Card") {
    EventCard(
        event: SupabaseEvent(
            id: UUID(),
            storeID: UUID(),
            name: "Spring Bridal Trunk Show",
            description: "A curated preview event.",
            scheduledAt: .now,
            venue: "Flagship Store — 5th Ave",
            launchSkuID: nil,
            eventType: "VIP Event",
            endTime: Calendar.current.date(byAdding: .hour, value: 3, to: .now),
            maxGuests: 60,
            bannerImageURL: "https://images.unsplash.com/photo-1519741497674-611481863552?w=800&q=80",
            eventGuests: []
        )
    )
    .environment(AppTheme())
    .padding()
}

#Preview("Events View") {
    NavigationStack {
        EventsView()
            .environment(AppTheme())
            .environment(SessionStore())
    }
}
