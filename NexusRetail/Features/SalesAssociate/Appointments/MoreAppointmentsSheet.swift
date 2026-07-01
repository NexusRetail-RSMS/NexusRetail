//
//  MoreAppointmentsSheet.swift
//  NexusRetail
//
//  Full-list sheet showing all appointments beyond the 48-hour window.
//

import SwiftUI

struct MoreAppointmentsSheet: View {
    let appointments: [AssociateAppointment]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(appointments) { appointment in
                appointmentRow(appointment)
                    .listRowInsets(EdgeInsets())
            }
            .listStyle(.insetGrouped)
            .navigationTitle("More Appointments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
