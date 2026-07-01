//
//  NewAppointmentsView.swift
//  NexusRetail


import SwiftUI
import MessageUI

// MARK: - Client Directory (in-memory lookup source)

struct KnownClient: Identifiable {
    let id = UUID()
    let name: String
    let email: String
    let phone: String   // stored digits-only, e.g. "5551234567"
}

enum ClientDirectory {
    static var clients: [KnownClient] = []

    private static var didSeed = false

    /// Strips everything but digits so "(555) 123-4567" and "+91 98765 43210" are comparable.
    static func normalize(_ raw: String) -> String {
        raw.filter(\.isNumber)
    }

    /// Uses the last 10 digits as the match key so numbers with/without a
    /// country code (e.g. "+91 98765 43210" vs "9876543210") still match.
    private static func matchKey(_ raw: String) -> String? {
        let digits = normalize(raw)
        guard digits.count >= 10 else { return nil }
        return String(digits.suffix(10))
    }

    /// Looks up a client by phone number.
    static func lookup(phone: String) -> KnownClient? {
        guard let target = matchKey(phone) else { return nil }
        return clients.first { matchKey($0.phone) == target }
    }

    /// Adds a new client, or updates the existing one if the phone number
    /// already exists in the directory (e.g. name/email correction).
    @discardableResult
    static func upsert(name: String, email: String, phone: String) -> KnownClient? {
        guard let target = matchKey(phone),
              !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            return nil
        }

        if let index = clients.firstIndex(where: { matchKey($0.phone) == target }) {
            let updated = KnownClient(name: name, email: email, phone: phone)
            clients[index] = updated
            return updated
        } else {
            let new = KnownClient(name: name, email: email, phone: phone)
            clients.append(new)
            return new
        }
    }

    /// One-time seed from existing appointment data, so clients who already
    /// have appointments are also autofillable by phone. Safe to call
    /// repeatedly — only runs the first time.
    static func seedIfNeeded(from appointments: [AssociateAppointment]) {
        guard !didSeed else { return }
        didSeed = true
        for appt in appointments {
            upsert(name: appt.clientName, email: appt.clientEmail, phone: appt.clientPhone)
        }
    }
}

struct NewAppointmentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var sessionStore

    var onSave: (AssociateAppointment) -> Void

    @State private var clientName: String = ""
    @State private var clientEmail: String = ""
    @State private var clientPhone: String = ""
    @State private var appointmentDate: Date = .now
    @State private var appointmentTime: Date = .now
    @State private var mode: AppointmentMode = .inStore
    @State private var status: AppointmentStatus = .pending
    @State private var productOrNote: String = ""

    @State private var isSendingEmail = false
    @State private var showingSuccessAlert = false

    // Autofill state
    @State private var matchedClient: KnownClient?

    private var isFormValid: Bool {
        !clientName.trimmingCharacters(in: .whitespaces).isEmpty &&
        isValidEmail(clientEmail) &&
        combinedDateTime() >= Date.now
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Client Details") {
                    TextField("Contact Number", text: $clientPhone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .onChange(of: clientPhone) { _, newValue in
                            handlePhoneChange(newValue)
                        }

                    TextField("Full Name", text: $clientName)
                        .textContentType(.name)

                    TextField("Email Address", text: $clientEmail)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
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

            }
            .navigationTitle("New Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSendingEmail {
                        ProgressView()
                    } else {
                        Button("Save") { prepareAndSendEmail() }
                            .disabled(!isFormValid)
                            .fontWeight(.semibold)
                    }
                }
            }
            .tint(RSMSColors.burgundy)
            .disabled(isSendingEmail)
            .alert("Email Sent", isPresented: $showingSuccessAlert) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("The appointment invitation has been successfully sent to the client.")
            }
        }
    }

    // MARK: - Actions

    private func handlePhoneChange(_ newValue: String) {
        guard let match = ClientDirectory.lookup(phone: newValue) else {
            // No match for the current digits — clear the badge but leave
            // whatever the user has typed in name/email alone.
            matchedClient = nil
            return
        }

        matchedClient = match
        clientName = match.name
        clientEmail = match.email
    }

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

    private func prepareAndSendEmail() {
        let appt = buildAppointment()
        
        Task {
            isSendingEmail = true
            let success = await sendAppointmentEmail(appt: appt)
            
            await MainActor.run {
                isSendingEmail = false
                // Persist the client and the appointment regardless of mail outcome
                ClientDirectory.upsert(name: appt.clientName, email: appt.clientEmail, phone: appt.clientPhone)
                onSave(appt)
                if success {
                    showingSuccessAlert = true
                } else {
                    dismiss()
                }
            }
        }
    }

    private func sendAppointmentEmail(appt: AssociateAppointment) async -> Bool {
        // Using the existing Resend API implementation from the project
        let resendApiKey = "re_3ot8yx3s_BDYPp6FcxJXDcFsSXU6bGW7t"
        
        guard let url = URL(string: "https://api.resend.com/emails") else { return false }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(resendApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var meetingHtml = ""
        if appt.mode == .video {
            let letters = "abcdefghijklmnopqrstuvwxyz"
            let p1 = String((0..<3).map { _ in letters.randomElement()! })
            let p2 = String((0..<4).map { _ in letters.randomElement()! })
            let p3 = String((0..<3).map { _ in letters.randomElement()! })
            let meetLink = "https://meet.google.com/\(p1)-\(p2)-\(p3)"
            meetingHtml = "<p><b>Meeting Link:</b> <a href='\(meetLink)'>\(meetLink)</a></p>"
        }
        let associateName = sessionStore.currentUser?.name ?? "Your Sales Associate"
        
        let htmlBody = """
        <h2>Appointment Confirmation – \(appt.mode.title)</h2>
        <p>Dear \(appt.clientName),</p>
        <p>Your appointment has been scheduled with the following details:</p>
        <ul>
            <li><b>Date:</b> \(appt.date.formatted(date: .long, time: .omitted))</li>
            <li><b>Time:</b> \(appt.time)</li>
            <li><b>Type:</b> \(appt.mode.title)</li>
            \(appt.productOrNote.isEmpty ? "" : "<li><b>Regarding:</b> \(appt.productOrNote)</li>")
        </ul>
        \(meetingHtml)
        <p>We look forward to seeing you.</p>
        <p>Warm regards,<br>\(associateName)</p>
        """
        
        let payload: [String: Any] = [
            "from": "Nexus Admin <admin@updates.nexusretail.tech>",
            "to": [appt.clientEmail],
            "subject": "Appointment Confirmation – \(appt.mode.title)",
            "html": htmlBody
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpRes = response as? HTTPURLResponse, httpRes.statusCode >= 300 {
                print("Failed to send appointment email. Status: \(httpRes.statusCode)")
                print(String(data: data, encoding: .utf8) ?? "")
                return false
            } else {
                print("Successfully dispatched appointment email via Resend to \(appt.clientEmail)!")
                return true
            }
        } catch {
            print("Network error sending appointment email: \(error)")
            return false
        }
    }

    private func isValidEmail(_ email: String) -> Bool {
        let regex = #"^\S+@\S+\.\S+$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }
}



#Preview {
    NewAppointmentView { _ in }
}
