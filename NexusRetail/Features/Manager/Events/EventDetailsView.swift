import SwiftUI

struct EventDetailsView: View {
    @Bindable var viewModel: EventsViewModel
    let eventId: UUID
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingEditEvent = false
    @State private var showingInviteGuests = false
    @State private var showingDeleteAlert = false
    
    var event: MockEvent? {
        viewModel.events.first { $0.id == eventId }
    }
    
    private var statusColor: Color {
        switch event?.status {
        case .upcoming: return .blue
        case .today: return .orange
        case .completed: return .green
        case .none: return .gray
        }
    }
    
    private var formattedDate: String {
        guard let event = event else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM yyyy"
        return formatter.string(from: event.startDate)
    }
    
    private var formattedTime: String {
        guard let event = event else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        let start = formatter.string(from: event.startDate)
        let end = formatter.string(from: event.endDate)
        return "\(start) - \(end)"
    }
    
    var body: some View {
        Group {
            if let event = event {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Banner Image
                        ZStack(alignment: .bottomLeading) {
                            Group {
                                if let imageData = event.bannerImageData, let uiImage = UIImage(data: imageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(height: 200)
                                        .clipped()
                                } else {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(height: 200)
                                        .overlay(
                                            Image(systemName: "photo.fill")
                                                .font(.system(size: 60))
                                                .foregroundColor(.gray.opacity(0.3))
                                        )
                                }
                            }
                            
                            HStack {
                                Text(event.eventType.rawValue)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(RSMSColors.burgundy)
                                    .cornerRadius(12)
                                
                                Text(event.status.rawValue)
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(statusColor)
                                    .cornerRadius(12)
                            }
                            .padding(16)
                        }
                        
                        // Event Details
                        VStack(alignment: .leading, spacing: 20) {
                            Text(event.title)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(RSMSColors.primaryText)
                            
                            HStack(alignment: .top, spacing: 16) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Label(formattedDate, systemImage: "calendar")
                                    Label(formattedTime, systemImage: "clock")
                                    Label(event.venue, systemImage: "mappin.and.ellipse")
                                }
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                            }
                            
                            if !event.description.isEmpty {
                                Text("About")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(RSMSColors.primaryText)
                                
                                Text(event.description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .lineSpacing(4)
                            }
                        }
                        .padding(20)
                        
                        Divider()
                        
                        // Guest Statistics
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Guests")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(RSMSColors.primaryText)
                            }
                                
                            HStack(spacing: 12) {
                                StatBox(title: "Guests Invited", value: "\(event.invitedCount)", icon: "person.2.fill")
                                StatBox(title: "Maximum Capacity", value: "\(event.maximumGuests)", icon: "building.2.fill")
                            }
                            
                            HStack(spacing: 12) {
                                StatBox(title: "Category", value: event.eventType.rawValue, icon: "tag.fill")
                                StatBox(title: "Status", value: event.status.rawValue, icon: "info.circle.fill")
                            }
                            
                            Button {
                                showingInviteGuests = true
                            } label: {
                                Text("Invite Guests")
                                    .font(.system(size: 16, weight: .semibold))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(RSMSColors.burgundy)
                                    .foregroundColor(.white)
                                    .cornerRadius(25)
                            }
                            .padding(.top, 8)
                        }
                        .padding(20)
                        
                        Divider()
                        
                        // Guest List
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Guest List")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(RSMSColors.primaryText)
                                .padding(20)
                            
                            if event.guests.isEmpty {
                                Text("No guests invited yet.")
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 40)
                            } else {
                                LazyVStack(spacing: 0) {
                                    ForEach(event.guests) { guest in
                                        GuestRow(guest: guest) {
                                            viewModel.removeGuest(eventId: event.id, guestId: guest.id)
                                        }
                                        Divider()
                                            .padding(.leading, 70)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button {
                                showingEditEvent = true
                            } label: {
                                Label("Edit Event", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                Label("Delete Event", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 18))
                                .foregroundColor(RSMSColors.burgundy)
                        }
                    }
                }
                .sheet(isPresented: $showingEditEvent) {
                    CreateEventView(viewModel: viewModel, eventToEdit: event)
                }
                .sheet(isPresented: $showingInviteGuests) {
                    InviteGuestsView(viewModel: viewModel, eventId: event.id)
                }
                .alert("Delete Event", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        viewModel.deleteEvent(id: event.id)
                        dismiss()
                    }
                } message: {
                    Text("Are you sure you want to delete this event? This action cannot be undone.")
                }
            } else {
                Text("Event not found")
                    .foregroundColor(.secondary)
            }
        }
        .background(RSMSColors.background.ignoresSafeArea())
    }
}

// MARK: - StatBox

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(RSMSColors.burgundy)
                .padding(.bottom, 4)
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(RSMSColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - GuestRow

struct GuestRow: View {
    let guest: MockGuest
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(RSMSColors.burgundy.opacity(0.1))
                    .frame(width: 44, height: 44)
                
                Text(guest.avatarName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(RSMSColors.burgundy)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(guest.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(RSMSColors.primaryText)
                
                Text(guest.email)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                Menu {
                    Button(role: .destructive, action: onRemove) {
                        Label("Remove Guest", systemImage: "person.crop.circle.badge.minus")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gray)
                        .padding(.horizontal, 4)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white)
    }
}
