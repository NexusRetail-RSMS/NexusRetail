import SwiftUI

struct EventDetailsView: View {
    @Environment(AppTheme.self) private var theme
    @Bindable var viewModel: EventsViewModel
    let eventId: UUID
    @Environment(\.dismiss) private var dismiss

    @State private var showingEditEvent = false
    @State private var showingInviteGuests = false
    @State private var showingDeleteAlert = false

    private var heroCream: Color { theme.background }
    private var cardCream: Color { theme.cardBackground }
    private var burgundy: Color { theme.burgundy }
    private var burgundyDim: Color { theme.burgundy.opacity(0.15) }
    private var blackText: Color { theme.primaryText }
    private var blackSecondary: Color { theme.primaryText }
    private var blackTertiary: Color { theme.tertiaryText }
    private var hairline: Color { theme.divider }

    var event: SupabaseEvent? {
        viewModel.events.first { $0.id == eventId }
    }

    private var isPastEvent: Bool {
        guard let event = event else { return false }
        let end = event.endTime ?? event.startTime
        return end < Date()
    }

    private var formattedDate: String {
        guard let event = event else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM yyyy"
        return formatter.string(from: event.eventDate)
    }

    private var formattedTime: String {
        guard let event = event else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let start = formatter.string(from: event.startTime)
        let end = formatter.string(from: event.endTime ?? event.startTime)
        return "\(start) – \(end)"
    }

    var body: some View {
        Group {
            if let event = event {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        heroSection(for: event)
                        contentSection(for: event)
                    }
                }
                .background(heroCream.ignoresSafeArea())
                .ignoresSafeArea(edges: .top)
                .toolbar(.hidden, for: .navigationBar)
                .sheet(isPresented: $showingEditEvent) {
                    CreateEventView(viewModel: viewModel, eventToEdit: event)
                }
                .sheet(isPresented: $showingInviteGuests) {
                    InviteGuestsView(viewModel: viewModel, eventId: event.id)
                }
                .alert("Delete event", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteEvent(id: event.id, storeID: event.storeID)
                            dismiss()
                        }
                    } label: {
                        Text("Delete")
                    }
                } message: {
                    Text("Are you sure you want to delete this event? This action cannot be undone.")
                }
            } else {
                Text("Event not found")
                    .foregroundColor(theme.secondaryText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(theme.background.ignoresSafeArea())
            }
        }
    }

    @ViewBuilder
    private func heroSection(for event: SupabaseEvent) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Group {
                    if let urlString = event.bannerImageURL, !urlString.isEmpty {
                        CachedAsyncImage(
                            url: URL(string: urlString),
                            content: { $0.resizable().aspectRatio(contentMode: .fill) },
                            placeholder: { cardCream }
                        )
                    } else {
                        Rectangle()
                            .fill(cardCream)
                            .overlay(
                                Image(systemName: "photo.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(blackTertiary)
                            )
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()

                LinearGradient(
                    stops: [
                        .init(color: heroCream.opacity(0.55), location: 0),
                        .init(color: heroCream.opacity(0.05), location: 0.22),
                        .init(color: heroCream.opacity(0.15), location: 0.5),
                        .init(color: heroCream, location: 0.92)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.title.bold())
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .foregroundColor(blackText)
                        .lineLimit(2)

                    Text(event.venueStr)
                        .font(.system(size: 16, weight: .bold))
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .foregroundColor(burgundy)
                        .padding(.bottom, 6)

                    Text("\(event.eventType ?? "Event") · \(formattedDate) · \(event.status.rawValue)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(blackSecondary)
                        .padding(.bottom, 20)

                    HStack(spacing: 12) {
                        Button {
                            showingInviteGuests = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "person.2.fill")
                                    .font(.system(size: 17))
                                Text("Invite guests")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(isPastEvent ? burgundy.opacity(0.35) : burgundy)
                            .foregroundColor(heroCream)
                            .clipShape(Capsule())
                        }
                        .disabled(isPastEvent)

                        Menu {
                            Button {
                                showingEditEvent = true
                            } label: {
                                Label("Edit event", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete event", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 18))
                                .foregroundColor(blackText)
                                .frame(width: 46, height: 46)
                                .background(burgundy.opacity(0.18))
                                .clipShape(Circle())
                        }
                    }

                    if isPastEvent {
                        Text("This event has already happened")
                            .font(.system(size: 12))
                            .foregroundColor(blackTertiary)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 26)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .overlay(alignment: .top) {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundColor(blackText)
                    }
                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.top, geo.safeAreaInsets.top + 70)
            }
        }
        .frame(height: 480)
    }

    @ViewBuilder
    private func contentSection(for event: SupabaseEvent) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 15))
                Text(event.venueStr)
                    .font(.system(size: 13))
            }
            .foregroundColor(blackSecondary)
            .padding(.bottom, 20)

            if let desc = event.description, !desc.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("About")
                        .font(.system(size: 16, weight: .heavy))
                        .textCase(.uppercase)
                        .tracking(0.5)
                        .foregroundColor(blackText.opacity(0.9))
                    Text(desc)
                        .font(.system(size: 14))
                        .foregroundColor(blackSecondary)
                        .lineSpacing(4)
                }
                .padding(.bottom, 22)
            }

            HStack(spacing: 10) {
                EventStatCard(
                    value: "\(event.invitedCount)",
                    suffix: "/\(event.maximumGuests)",
                    label: "Guests invited",
                    cardColor: cardCream,
                    valueColor: blackText,
                    suffixColor: blackTertiary,
                    labelColor: blackTertiary
                )
                EventStatCard(
                    value: "\(event.maximumGuests)",
                    suffix: nil,
                    label: "Max capacity",
                    cardColor: cardCream,
                    valueColor: blackText,
                    suffixColor: blackTertiary,
                    labelColor: blackTertiary
                )
            }
            .padding(.bottom, 22)

            VStack(alignment: .leading, spacing: 0) {
                Text("Guest list")
                    .font(.system(size: 13, weight: .medium))
                    .textCase(.uppercase)
                    .tracking(0.5)
                    .foregroundColor(blackText.opacity(0.9))
                    .padding(.bottom, 12)

                if event.eventGuests?.isEmpty ?? true {
                    Text("No guests invited yet.")
                        .font(.system(size: 13))
                        .foregroundColor(blackSecondary)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(event.eventGuests ?? [], id: \.self) { eventGuest in
                            if let guest = eventGuest.client {
                                GuestRow(
                                    guest: guest,
                                    burgundy: burgundy,
                                    burgundyDim: burgundyDim,
                                    nameColor: blackText,
                                    emailColor: blackTertiary,
                                    iconColor: blackTertiary
                                ) {
                                    Task {
                                        await viewModel.removeGuest(
                                            eventId: event.id,
                                            guestId: guest.id,
                                            storeID: event.storeID
                                        )
                                    }
                                }
                                if eventGuest != (event.eventGuests ?? []).last {
                                    Rectangle()
                                        .fill(hairline)
                                        .frame(height: 0.5)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.top, 16)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(hairline)
                    .frame(height: 0.5)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 28)
        .background(heroCream)
    }
}

private struct EventStatCard: View {
    let value: String
    let suffix: String?
    let label: String
    let cardColor: Color
    let valueColor: Color
    let suffixColor: Color
    let labelColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(valueColor)
                if let suffix = suffix {
                    Text(suffix)
                        .font(.system(size: 14))
                        .foregroundColor(suffixColor)
                }
            }
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(labelColor)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardColor)
        .cornerRadius(14)
    }
}

private struct GuestRow: View {
    let guest: SupabaseClientModel
    let burgundy: Color
    let burgundyDim: Color
    let nameColor: Color
    let emailColor: Color
    let iconColor: Color
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(burgundyDim)
                    .frame(width: 40, height: 40)
                Text(guest.avatarName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(burgundy)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(guest.name ?? "Unknown")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(nameColor)
                Text(guest.email ?? "No email")
                    .font(.system(size: 12))
                    .foregroundColor(emailColor)
            }

            Spacer()

            Menu {
                Button(role: .destructive, action: onRemove) {
                    Label("Remove guest", systemImage: "person.crop.circle.badge.minus")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(iconColor)
            }
        }
        .padding(.vertical, 10)
    }
}

private func makeMockEventDetailsPreview() -> some View {
    let theme = AppTheme()
    let mockEventID = UUID()

    let guest1 = SupabaseClientModel(
        id: UUID(),
        name: "Maya Rodriguez",
        phone: "+1 (415) 555-0172",
        email: "m.rodriguez@acme.com"
    )
    let guest2 = SupabaseClientModel(
        id: UUID(),
        name: "James Okafor",
        phone: "+1 (415) 555-0134",
        email: "j.okafor@acme.com"
    )

    let eventGuest1 = EventGuest(
        id: UUID(),
        eventID: mockEventID,
        clientID: guest1.id,
        status: "invited",
        createdAt: Date(),
        client: guest1
    )
    let eventGuest2 = EventGuest(
        id: UUID(),
        eventID: mockEventID,
        clientID: guest2.id,
        status: "invited",
        createdAt: Date(),
        client: guest2
    )

    let pastDate = Date().addingTimeInterval(-3600 * 24)

    let mockEvent = SupabaseEvent(
        id: mockEventID,
        storeID: UUID(),
        name: "Store anniversary",
        description: "Celebrating one year of the flagship store with guest appearances, exclusive product drops, and a champagne toast at closing.",
        scheduledAt: pastDate,
        venue: "NexusRetail flagship launch",
        launchSkuID: nil,
        eventType: "Event",
        endTime: pastDate.addingTimeInterval(3600 * 3),
        maxGuests: 50,
        bannerImageURL: "https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=800",
        eventGuests: [eventGuest1, eventGuest2]
    )

    let viewModel = EventsViewModel()
    viewModel.events = [mockEvent]

    return NavigationStack {
        EventDetailsView(viewModel: viewModel, eventId: mockEvent.id)
    }
    .environment(theme)
}

#Preview {
    makeMockEventDetailsPreview()
}
