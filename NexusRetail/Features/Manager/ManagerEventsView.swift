import SwiftUI

struct ManagerEventsView: View {
    @State private var isShowingCreateForm = false
    @State private var viewModel = EventsViewModel()
    
    var body: some View {
        ZStack {
            RSMSColors.background.ignoresSafeArea()
            ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Main Card
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: RSMSRadius.large)
                        .fill(
                            LinearGradient(
                                colors: [
                                    RSMSColors.primaryText.opacity(0.02),
                                    RSMSColors.burgundy.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 16) {
                            // Badge
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.caption.bold())
                                Text("Coming Soon")
                                    .font(RSMSFonts.caption)
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(RSMSColors.burgundy)
                            .cornerRadius(RSMSRadius.small)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Store Events")
                                    .font(RSMSFonts.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(RSMSColors.primaryText)
                                
                                Text("Track and organize upcoming promotional events and product launches.")
                                    .font(RSMSFonts.body)
                                    .foregroundColor(RSMSColors.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            
                            Button {
                                // Notify Me action
                            } label: {
                                HStack {
                                    Image(systemName: "bell.fill")
                                    Text("Notify Me")
                                        .fontWeight(.semibold)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(RSMSColors.burgundy)
                                .cornerRadius(RSMSRadius.small)
                            }
                            .padding(.top, 8)
                        }
                        .padding(24)
                        
                        Spacer()
                        
                        // Decorative elements right side
                        ZStack {
                            Image(systemName: "calendar")
                                .font(.system(size: 80))
                                .foregroundColor(RSMSColors.burgundy.opacity(0.8))
                                .rotationEffect(.degrees(-10))
                                .offset(x: -20, y: -20)
                            
                            Image(systemName: "megaphone.fill")
                                .font(.system(size: 40))
                                .foregroundColor(RSMSColors.burgundy)
                                .rotationEffect(.degrees(15))
                                .offset(x: 20, y: 30)
                        }
                        .frame(width: 120)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // What you can do section
                VStack(alignment: .leading, spacing: 16) {
                    Text("What you can do")
                        .font(RSMSFonts.headline)
                        .fontWeight(.bold)
                        .foregroundColor(RSMSColors.primaryText)
                    
                    HStack(spacing: 16) {
                        EventActionCard(
                            icon: "envelope",
                            title: "Send Invites",
                            description: "Send digital invitations to selected guests."
                        )
                        EventActionCard(
                            icon: "list.clipboard",
                            title: "Track RSVPs",
                            description: "Accept, decline or pending responses."
                        )
                    }
                }
                
                // Upcoming Events section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Upcoming Events")
                            .font(RSMSFonts.headline)
                            .fontWeight(.bold)
                            .foregroundColor(RSMSColors.primaryText)
                        
                        Spacer()
                        
                        Button(action: {}) {
                            HStack(spacing: 4) {
                                Text("View All")
                                    .font(RSMSFonts.body)
                                    .fontWeight(.bold)
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                            }
                            .foregroundColor(RSMSColors.burgundy)
                        }
                    }
                    
                    VStack(spacing: 16) {
                        if viewModel.isLoading && viewModel.upcomingEvents.isEmpty {
                            ProgressView()
                                .padding()
                        } else {
                            ForEach(viewModel.upcomingEvents) { event in
                                UpcomingEventRow(event: event)
                            }
                        }
                    }
                }
            }
            .padding(20)
            .padding(.top, 16) // Extra padding for the header
        }
        .safeAreaInset(edge: .top) {
            headerSection
                .background(.ultraThinMaterial)
        }
        .sheet(isPresented: $isShowingCreateForm) {
            CreateEventSheet { title, date in
                Task {
                    await viewModel.addEvent(title: title, date: date)
                }
            }
        }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private var headerSection: some View {
        HStack {
            Text("Events")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(RSMSColors.primaryText)
            
            Spacer()
            
            Button {
                isShowingCreateForm = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(RSMSColors.burgundy)
                    .frame(width: 44, height: 44)
                    .background(RSMSColors.burgundy.opacity(0.1))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Create new event")
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

struct CreateEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var date = Date()
    var onAdd: (String, Date) -> Void
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Event Title", text: $title)
                    DatePicker("Date", selection: $date, in: Date()..., displayedComponents: .date)
                    DatePicker("Time", selection: $date, in: Date()..., displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(RSMSColors.burgundy)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onAdd(title, date)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(RSMSColors.burgundy)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}

struct EventActionCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(RSMSColors.burgundy.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(RSMSColors.burgundy)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(RSMSFonts.body)
                    .fontWeight(.bold)
                    .foregroundColor(RSMSColors.primaryText)
                
                Text(description)
                    .font(RSMSFonts.caption)
                    .foregroundColor(RSMSColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, minHeight: 180)
        .background(Color.white)
        .cornerRadius(RSMSRadius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct UpcomingEvent: Identifiable {
    let id: UUID
    let title: String
    let date: String
    let time: String
    let location: String
    let imageColor: Color
    let icon: String
}

struct UpcomingEventRow: View {
    let event: UpcomingEvent
    
    var body: some View {
        HStack(spacing: 16) {
            // Image Placeholder
            RoundedRectangle(cornerRadius: RSMSRadius.small)
                .fill(event.imageColor)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: event.icon)
                        .foregroundColor(.white)
                        .font(.system(size: 30))
                )
            
            VStack(alignment: .leading, spacing: 8) {
                Text(event.title)
                    .font(RSMSFonts.body)
                    .fontWeight(.bold)
                    .foregroundColor(RSMSColors.primaryText)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10))
                        Text(event.date)
                            .font(RSMSFonts.caption)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                        Text(event.time)
                            .font(RSMSFonts.caption)
                    }
                }
                .foregroundColor(RSMSColors.secondaryText)
                
                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 10))
                    Text(event.location)
                        .font(RSMSFonts.caption)
                }
                .foregroundColor(RSMSColors.secondaryText)
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(RSMSColors.secondaryText)
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(RSMSRadius.medium)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    NavigationStack {
        ManagerEventsView()
    }
}
