import SwiftUI

struct AppointmentsView: View {
    @State private var appointments: [AssociateAppointment] = [
        AssociateAppointment(clientName: "Ananya Rao",  date: Calendar.current.date(bySettingHour: 16, minute: 30, second: 0, of: .now) ?? .now, mode: .inStore),
        AssociateAppointment(clientName: "Kabir Mehta", date: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: .now) ?? .now) ?? .now, mode: .video),
        AssociateAppointment(clientName: "Mira Kapoor", date: Calendar.current.date(byAdding: .day, value: 3, to: Calendar.current.date(bySettingHour: 14, minute: 15, second: 0, of: .now) ?? .now) ?? .now, mode: .inStore),
        AssociateAppointment(clientName: "Rhea Sethi",  date: Calendar.current.date(byAdding: .day, value: 5, to: Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: .now) ?? .now) ?? .now, mode: .video)
    ]
    
    private var sortedAppointments: [AssociateAppointment] {
        appointments.sorted { $0.date < $1.date }
    }

    private var upcomingAppointments: [AssociateAppointment] {
        let cutoff = Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now
        return sortedAppointments.filter { $0.date >= .now && $0.date < cutoff }.dropFirst().map { $0 }
    }

    private var laterAppointments: [AssociateAppointment] {
        let cutoff = Calendar.current.date(byAdding: .day, value: 2, to: .now) ?? .now
        return sortedAppointments.filter { $0.date >= cutoff }
    }
    
    private var allUpcomingAppointments: [AssociateAppointment] {
        sortedAppointments.filter { $0.date >= .now }
    }

    var body: some View {
        NavigationStack {
            List {
                let todayAppts = upcomingAppointments
                let futureAppts = laterAppointments

                if !todayAppts.isEmpty {
                    Section("Today & Tomorrow") {
                        ForEach(todayAppts) { appt in
                            appointmentRow(appt)
                                .listRowInsets(EdgeInsets())
                        }
                    }
                }

                if !futureAppts.isEmpty {
                    Section("Later") {
                        ForEach(futureAppts) { appt in
                            appointmentRow(appt)
                                .listRowInsets(EdgeInsets())
                        }
                    }
                }

                if allUpcomingAppointments.isEmpty {
                    ContentUnavailableView(
                        "No Appointments",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("No upcoming appointments scheduled.")
                    )
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Appointments")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func appointmentRow(_ appt: AssociateAppointment) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(RSMSColors.burgundy.opacity(0.09))
                    .frame(width: 42, height: 42)
                Image(systemName: appt.mode.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(RSMSColors.burgundy)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(appt.clientName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RSMSColors.primaryText)
                Text(appt.time)
                    .font(.system(size: 12))
                    .foregroundStyle(RSMSColors.secondaryText)
            }
            Spacer()
            Text(appt.mode.title)
                .font(.system(size: 10, weight: .bold))
                .kerning(0.2)
                .foregroundStyle(RSMSColors.burgundy)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(RSMSColors.burgundy.opacity(0.09))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }
}
