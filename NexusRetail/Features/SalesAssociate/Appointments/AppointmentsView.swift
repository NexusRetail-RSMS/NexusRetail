//
//  AppointmentsView.swift
//  NexusRetail
//
//  Appointments tab — shows upcoming appointments and a "Book" CTA.
//  Driven by AppointmentsViewModel.
//

import SwiftUI

struct AppointmentsView: View {
    @State private var viewModel = AppointmentsViewModel()
    @State private var isBookingPresented = false
    @State private var isMorePresented    = false

    // Clienteling VM is passed in so we can read the client list for the booking picker.
    let clients: [AssociateClient]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                bookAppointmentButton
                upcomingAppointmentsCard
            }
            .screenPadding()
        }
        .background(RSMSColors.background.ignoresSafeArea())
        .navigationTitle("Appointments")
        .sheet(isPresented: $isBookingPresented) {
            BookAppointmentSheet(clients: clients, viewModel: viewModel)
        }
        .sheet(isPresented: $isMorePresented) {
            MoreAppointmentsSheet(appointments: viewModel.laterAppointments)
        }
    }

    // MARK: - Hero CTA
    private var bookAppointmentButton: some View {
        Button {
            isBookingPresented = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(.white.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Book Appointment")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Video or in-store consultation")
                        .font(RSMSFonts.subheadline)
                        .foregroundStyle(.white.opacity(0.74))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.55))
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Upcoming Card
    private var upcomingAppointmentsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Upcoming Appointments")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(RSMSColors.primaryText)
                Spacer()
                if !viewModel.laterAppointments.isEmpty {
                    Button("View More") {
                        isMorePresented = true
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(RSMSColors.burgundy)
                }
            }

            VStack(spacing: 0) {
                if viewModel.twoDayAppointments.isEmpty {
                    emptyStateRow(title: "No appointments in the next 2 days", icon: "calendar")
                } else {
                    ForEach(Array(viewModel.twoDayAppointments.enumerated()), id: \.element.id) { index, appt in
                        appointmentRow(appt)
                        if index < viewModel.twoDayAppointments.count - 1 {
                            Divider().padding(.leading, 72)
                        }
                    }
                }
            }
        }
        .padding(20)
        .luxuryCard()
    }
}
