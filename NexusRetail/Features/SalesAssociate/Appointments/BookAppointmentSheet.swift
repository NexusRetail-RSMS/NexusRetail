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
        self.clients = clients
        self.viewModel = viewModel
        _selectedClientName = State(initialValue: clients.first?.name ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {

                // MARK: Client
                Section("Client") {
                    Picker("Select Client", selection: $selectedClientName) {
                        ForEach(clients) { client in
                            Text(client.name)
                                .tag(client.name)
                        }
                    }
                }

                // MARK: Appointment Details
                Section("Appointment Details") {

                    DatePicker(
                        "Date",
                        selection: $appointmentDate,
                        in: Date.now...,
                        displayedComponents: .date
                    )

                    DatePicker(
                        "Time",
                        selection: $appointmentDate,
                        displayedComponents: .hourAndMinute
                    )

                    VStack(alignment: .leading, spacing: 16) {

                        Text("Appointment Type")
                            .font(.headline)

                        Button {
                            mode = .inStore
                        } label: {
                            HStack {
                                Image(systemName:
                                        mode == .inStore
                                        ? "largecircle.fill.circle"
                                        : "circle")
                                    .foregroundColor(RSMSColors.burgundy)

                                Label("In Store",
                                      systemImage: "building.2")

                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)

                        Button {
                            mode = .video
                        } label: {
                            HStack {
                                Image(systemName:
                                        mode == .video
                                        ? "largecircle.fill.circle"
                                        : "circle")
                                    .foregroundColor(RSMSColors.burgundy)

                                Label("Video Consultation",
                                      systemImage: "video")

                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 4)
                }

                // MARK: Confirm Button
                Section {
                    Button {

                        viewModel.book(
                            clientName: selectedClientName,
                            date: appointmentDate,
                            mode: mode
                        )

                        dismiss()

                    } label: {
                        HStack {
                            Spacer()

                            Label(
                                "Confirm Booking",
                                systemImage: "calendar.badge.plus"
                            )
                            .fontWeight(.semibold)

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
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
