import SwiftUI

struct AppointmentsView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(AppTheme.self) private var theme
    @State private var viewModel = AppointmentsViewModel()
    @State private var showingNewAppointment = false
    @State private var contentAppeared = false

    enum FilterMode: String, CaseIterable, Identifiable {
        case inStore = "In Store"
        case video   = "Video"
        var id: String { rawValue }
    }
    @State private var selectedFilter: FilterMode = .inStore

    // MARK: - Accent helpers
    private var accent: Color { theme.isDarkMode ? theme.antiqueGold : theme.burgundy }
    private var cardBg: Color {
        theme.isDarkMode ? Color(hex: "1A1009") : Color.white
    }

    // MARK: - Filtering / Grouping
    private var filtered: [AssociateAppointment] {
        viewModel.appointments
            .filter { appt in
                appt.date >= Calendar.current.startOfDay(for: .now) &&
                ((selectedFilter == .inStore && appt.mode == .inStore) ||
                 (selectedFilter == .video   && appt.mode == .video))
            }
            .sorted { $0.date < $1.date }
    }

    private var todayAppointments:    [AssociateAppointment] { filtered.filter {  Calendar.current.isDateInToday($0.date) } }
    private var tomorrowAppointments: [AssociateAppointment] { filtered.filter {  Calendar.current.isDateInTomorrow($0.date) } }
    private var upcomingAppointments: [AssociateAppointment] { filtered.filter { !Calendar.current.isDateInToday($0.date) && !Calendar.current.isDateInTomorrow($0.date) } }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        headerSection
                        filterToggle
                        contentSection
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
            .task {
                if let associateId = sessionStore.currentUser?.id {
                    await viewModel.fetchAppointments(for: associateId)
                }
                withAnimation(.spring(response: 0.65, dampingFraction: 0.82).delay(0.05)) {
                    contentAppeared = true
                }
            }
            .sheet(isPresented: $showingNewAppointment) {
                NewAppointmentView(viewModel: viewModel)
            }
        }
        .tint(accent)
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Appointments")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(theme.primaryText)
                if !viewModel.appointments.isEmpty {
                    Text("\(viewModel.appointments.count) scheduled")
                        .font(.system(size: 13))
                        .foregroundStyle(theme.secondaryText)
                }
            }
            Spacer()
            Button {
                showingNewAppointment = true
            } label: {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.14))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .strokeBorder(accent.opacity(0.25), lineWidth: 1)
                        )
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(accent)
                }
            }
            .buttonStyle(BounceButtonStyle())
            .accessibilityLabel("New Appointment")
        }
        .padding(.top, 4)
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : -12)
        .animation(.spring(response: 0.55, dampingFraction: 0.82), value: contentAppeared)
    }

    // MARK: - Native segmented filter (consistent with the rest of the app)
    private var filterToggle: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(FilterMode.allCases) { mode in
                Text(localized: mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .opacity(contentAppeared ? 1 : 0)
        .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.08), value: contentAppeared)
    }

    // MARK: - Content
    @ViewBuilder
    private var contentSection: some View {
        if filtered.isEmpty {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.10))
                        .frame(width: 72, height: 72)
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundStyle(accent)
                }
                Text("No Appointments")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(theme.primaryText)
                Text("No upcoming \(selectedFilter.rawValue.lowercased()) appointments scheduled.")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 60)
            .opacity(contentAppeared ? 1 : 0)
            .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.15), value: contentAppeared)
        } else {
            if !todayAppointments.isEmpty    { sectionBlock(title: "Today",    items: todayAppointments,    startDelay: 0.10) }
            if !tomorrowAppointments.isEmpty { sectionBlock(title: "Tomorrow", items: tomorrowAppointments, startDelay: 0.16) }
            if !upcomingAppointments.isEmpty  { sectionBlock(title: "Upcoming", items: upcomingAppointments, startDelay: 0.22) }
        }
    }

    // MARK: - Section block
    private func sectionBlock(title: String, items: [AssociateAppointment], startDelay: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                // Accent bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(accent)
                    .frame(width: 3, height: 14)
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .kerning(1.2)
                    .foregroundStyle(accent)
            }
            .padding(.leading, 2)

            VStack(spacing: 12) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, appt in
                    appointmentCard(appt)
                        .opacity(contentAppeared ? 1 : 0)
                        .offset(y: contentAppeared ? 0 : 16)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.78).delay(startDelay + Double(index) * 0.06),
                            value: contentAppeared
                        )
                }
            }
        }
    }

    // MARK: - Appointment Card (flashy, pops out)
    private func appointmentCard(_ appt: AssociateAppointment) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                // Time pill
                HStack(spacing: 5) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(accent)
                    Text(appt.time)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.primaryText)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(accent.opacity(0.10))
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(accent.opacity(0.20), lineWidth: 1))

                Spacer()
                statusBadge(appt.status)
            }

            Text(appt.clientName)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(theme.primaryText)

            if !appt.productOrNote.isEmpty {
                Text(appt.productOrNote)
                    .font(.system(size: 13))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(2)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(cardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    theme.isDarkMode
                        ? LinearGradient(
                            colors: [theme.antiqueGold.opacity(0.30), theme.darkWoodBrown.opacity(0.25)],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(
                            colors: [theme.burgundy.opacity(0.12), Color.clear],
                            startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
        .shadow(
            color: theme.isDarkMode
                ? theme.antiqueGold.opacity(0.08)
                : Color.black.opacity(0.06),
            radius: theme.isDarkMode ? 14 : 8,
            x: 0, y: theme.isDarkMode ? 8 : 4
        )
    }

    // MARK: - Status Badge
    private func statusBadge(_ status: AppointmentStatus) -> some View {
        Label {
            Text(localized: status.title)
        } icon: {
            Image(systemName: status.icon)
        }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(status.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(status.color.opacity(0.14))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(status.color.opacity(0.22), lineWidth: 1))
    }
}

#Preview {
    AppointmentsView()
        .environment(SessionStore())
        .environment(AppTheme())
}
