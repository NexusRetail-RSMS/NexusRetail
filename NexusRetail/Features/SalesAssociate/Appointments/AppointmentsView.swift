import SwiftUI

struct AppointmentsView: View {
    @Environment(SessionStore.self) private var sessionStore
    @State private var viewModel = AppointmentsViewModel()

    @State private var showingNewAppointment = false

    enum FilterMode: String, CaseIterable, Identifiable {
        case inStore = "In Store"
        case video = "Video"
        var id: String { rawValue }
    }
    @State private var selectedFilter: FilterMode = .inStore

    // MARK: - Filtering / Grouping

    private var filtered: [AssociateAppointment] {
        viewModel.appointments
            .filter { appt in
                appt.date >= Calendar.current.startOfDay(for: .now) &&
                ((selectedFilter == .inStore && appt.mode == .inStore) ||
                 (selectedFilter == .video && appt.mode == .video))
            }
            .sorted { $0.date < $1.date }
    }

    private var todayAppointments: [AssociateAppointment] {
        filtered.filter { Calendar.current.isDateInToday($0.date) }
    }

    private var tomorrowAppointments: [AssociateAppointment] {
        filtered.filter { Calendar.current.isDateInTomorrow($0.date) }
    }

    private var upcomingAppointments: [AssociateAppointment] {
        filtered.filter {
            !Calendar.current.isDateInToday($0.date) && !Calendar.current.isDateInTomorrow($0.date)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 22) {
                    HStack(alignment: .center) {
                        Text("Appointments")
                            .font(.largeTitle.weight(.bold))
                        
                        Spacer()
                        
                        Button {
                            showingNewAppointment = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(RSMSColors.burgundy)
                                .frame(width: 44, height: 44)
                                .background(RSMSColors.burgundy.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("New Appointment")
                    }
                    .padding(.top, 4)

                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(FilterMode.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.bottom, 4)

                    if filtered.isEmpty {
                        ContentUnavailableView(
                            "No Appointments",
                            systemImage: "calendar.badge.exclamationmark",
                            description: Text("No upcoming appointments scheduled.")
                        )
                        .padding(.top, 40)
                    } else {
                        if !todayAppointments.isEmpty {
                            sectionBlock(title: "Today", items: todayAppointments)
                        }
                        if !tomorrowAppointments.isEmpty {
                            sectionBlock(title: "Tomorrow", items: tomorrowAppointments)
                        }
                        if !upcomingAppointments.isEmpty {
                            sectionBlock(title: "Upcoming", items: upcomingAppointments)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(RSMSColors.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .task {
                if let associateId = sessionStore.currentUser?.id {
                    await viewModel.fetchAppointments(for: associateId)
                }
            }
            .sheet(isPresented: $showingNewAppointment) {
                NewAppointmentView(viewModel: viewModel)
            }
        }
        .tint(RSMSColors.burgundy)
    }

    // MARK: - Section

    private func sectionBlock(title: String, items: [AssociateAppointment]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .semibold))
                .kerning(0.6)
                .foregroundStyle(.black)
                .padding(.leading, 4)

            VStack(spacing: 14) {
                ForEach(items) { appt in
                    appointmentCard(appt)
                }
            }
        }
    }

    // MARK: - Card

    private func appointmentCard(_ appt: AssociateAppointment) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(appt.time, systemImage: "clock")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(RSMSColors.darkBrown)
                Spacer()
                statusBadge(appt.status)
            }

            Text(appt.clientName)
                .font(.system(size: 19, weight: .bold))
                .foregroundStyle(RSMSColors.darkBrown)

            Text(appt.productOrNote)
                .font(.system(size: 14))
                .foregroundStyle(RSMSColors.secondaryText)

        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(RSMSColors.cardBackground)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        )
    }

    private func statusBadge(_ status: AppointmentStatus) -> some View {
        Label(status.title, systemImage: status.icon)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(status.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(status.color.opacity(0.14))
            .clipShape(Capsule())
    }
}

#Preview {
    AppointmentsView()
}
