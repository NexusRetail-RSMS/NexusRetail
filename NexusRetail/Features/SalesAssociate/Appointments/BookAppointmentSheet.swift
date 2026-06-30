//
//  BookAppointmentSheet.swift
//  NexusRetail
//
//  Modal form for booking a new client appointment.
//

import SwiftUI

struct BookAppointmentSheet: View {
    let clients: [AssociateClient]
    var viewModel: AppointmentsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedClientName: String
    @State private var appointmentDate = Calendar.current.date(byAdding: .hour, value: 3, to: .now) ?? .now
    @State private var mode: AppointmentMode = .inStore

    init(clients: [AssociateClient], viewModel: AppointmentsViewModel) {
        self.clients   = clients
        self.viewModel = viewModel
        _selectedClientName = State(initialValue: clients.first?.name ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    Picker("Client", selection: $selectedClientName) {
                        ForEach(clients) { client in
                            Text(client.name).tag(client.name)
                        }
                    }
                }

                Section("Appointment") {
                    DatePicker(
                        "Date & Time",
                        selection: $appointmentDate,
                        in: Date.now...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    Picker("Type", selection: $mode) {
                        ForEach(AppointmentMode.allCases) { m in
                            Label(m.title, systemImage: m.icon).tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button {
                        viewModel.book(clientName: selectedClientName, date: appointmentDate, mode: mode)
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Confirm Booking", systemImage: "calendar.badge.plus")
                            Spacer()
                        }
                    }
                    .disabled(selectedClientName.isEmpty)
                }
            }
            .tint(RSMSColors.burgundy)
            .navigationTitle("Book Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
