//
//  AppointmentsViewModel.swift
//  NexusRetail
//
//  ViewModel for the Appointments tab. Owns appointment list state and
//  time-bucketing computed properties.
//

import SwiftUI
import Observation

@Observable
final class AppointmentsViewModel {

    // MARK: - State
    var appointments: [AssociateAppointment] = SalesAssociateSampleData.appointments

    // MARK: - Computed — upcoming in 48 h
    var twoDayAppointments: [AssociateAppointment] {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: 2, to: .now) else { return [] }
        return appointments
            .filter { $0.date >= .now && $0.date < cutoff }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Computed — beyond 48 h
    var laterAppointments: [AssociateAppointment] {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: 2, to: .now) else { return [] }
        return appointments
            .filter { $0.date >= cutoff }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Mutations
    func book(clientName: String, date: Date, mode: AppointmentMode) {
        appointments.append(AssociateAppointment(clientName: clientName, date: date, mode: mode))
    }
}
