//
//  NewAppointmentsView.swift
//  NexusRetail
//
//  Created by Mahak on 30/06/26.
//

import SwiftUI
import MessageUI

struct NewAppointmentView: View {
    @Environment(\.dismiss) private var dismiss

    var onSave: (AssociateAppointment) -> Void

    @State private var clientName: String = ""
    @State private var clientEmail: String = ""
    @State private var clientPhone: String = ""
    @State private var appointmentDate: Date = .now
    @State private var appointmentTime: Date = .now
    @State private var mode: AppointmentMode = .inStore
    @State private var productOrNote: String = ""
    @State private var status: AppointmentStatus = .pending

    @State private var showingMailComposer = false
    @State private var showingMailUnavailableAlert = false
    @State private var generatedSubject = ""
    @State private var generatedBody = ""

    private var isFormValid: Bool {
        !clientName.trimmingCharacters(in: .whitespaces).isEmpty &&
        isValidEmail(clientEmail) &&
        combinedDateTime() >= Date.now
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Client Details") {
                    TextField("Full Name", text: $clientName)
                        .textContentType(.name)

                    TextField("Email Address", text: $clientEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    TextField("Contact Number", text: $clientPhone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }

                Section("Appointment") {
                    DatePicker("Date", selection: $appointmentDate, in: Date.now..., displayedComponents: .date)
                    DatePicker("Time", selection: $appointmentTime, displayedComponents: .hourAndMinute)

                    HStack(spacing: 20) {
                        Text("Type")
                        Spacer()
                        Button {
                            mode = .inStore
                        } label: {
                            HStack {
                                Image(systemName: mode == .inStore ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(mode == .inStore ? .green : .secondary)
                                Text("In Store")
                            }
                        }
                        .buttonStyle(.plain)

                        Button {
                            mode = .video
                        } label: {
                            HStack {
                                Image(systemName: mode == .video ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(mode == .video ? .green : .secondary)
                                Text("Video")
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    TextField("Product / Notes", text: $productOrNote, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section {
                    Button {
                        prepareAndSendEmail()
                    } label: {
                        Label("Generate & Send Email to Client", systemImage: "envelope.fill")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .disabled(!isFormValid)
                } footer: {
                    Text("Sends a confirmation email with the appointment details to the client's email address.")
                }
            }
            .navigationTitle("New Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isFormValid)
                        .fontWeight(.semibold)
                }
            }
            .tint(RSMSColors.burgundy)
            .sheet(isPresented: $showingMailComposer) {
                MailComposerView(
                    recipient: clientEmail,
                    subject: generatedSubject,
                    body: generatedBody
                )
            }
            .alert("Mail Not Configured", isPresented: $showingMailUnavailableAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("No mail account is set up on this device. The appointment was still saved; you can email the client manually.")
            }
        }
    }

    // MARK: - Actions

    private func combinedDateTime() -> Date {
        let cal = Calendar.current
        let timeComps = cal.dateComponents([.hour, .minute], from: appointmentTime)
        return cal.date(
            bySettingHour: timeComps.hour ?? 0,
            minute: timeComps.minute ?? 0,
            second: 0,
            of: appointmentDate
        ) ?? appointmentDate
    }

    private func buildAppointment() -> AssociateAppointment {
        AssociateAppointment(
            clientName: clientName,
            clientEmail: clientEmail,
            clientPhone: clientPhone,
            date: combinedDateTime(),
            mode: mode,
            status: status,
            productOrNote: productOrNote.isEmpty ? "Appointment" : productOrNote
        )
    }

    private func save() {
        onSave(buildAppointment())
        dismiss()
    }

    private func prepareAndSendEmail() {
        let appt = buildAppointment()
        generatedSubject = "Appointment Confirmation – \(appt.mode.title)"
        var meetingLink = ""
        if appt.mode == .video {
            meetingLink = "\nMeeting Link: https://meet.google.com/abc-defg-hij\n"
        }

        generatedBody = """
        Dear \(appt.clientName),

        Your appointment has been scheduled with the following details:

        Date: \(appt.date.formatted(date: .long, time: .omitted))
        Time: \(appt.time)
        Type: \(appt.mode.title)
        \(appt.productOrNote.isEmpty ? "" : "Regarding: \(appt.productOrNote)\n")\(meetingLink)
        We look forward to seeing you. If you need to reschedule, please contact us at your earliest convenience.

        Warm regards,
        Your Sales Associate
        """

        if MFMailComposeViewController.canSendMail() {
            showingMailComposer = true
        } else if let mailtoURL = mailtoURL() {
            UIApplication.shared.open(mailtoURL)
        } else {
            showingMailUnavailableAlert = true
        }

        // Persist the appointment regardless of mail outcome
        onSave(appt)
    }

    private func mailtoURL() -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = clientEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: generatedSubject),
            URLQueryItem(name: "body", value: generatedBody)
        ]
        return components.url
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = #"^\S+@\S+\.\S+$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }
}

// MARK: - Mail Composer Wrapper

struct MailComposerView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.setToRecipients([recipient])
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        composer.mailComposeDelegate = context.coordinator
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss)
    }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            dismiss()
        }
    }
}

#Preview {
    NewAppointmentView { _ in }
}
