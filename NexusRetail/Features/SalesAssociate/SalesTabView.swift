import SwiftUI

struct SalesTabView: View {
    var body: some View {
        NavigationStack {
            SalesAssociateDashboardView()
        }
        .tint(RSMSColors.burgundy)
    }
}

struct SalesAssociateDashboardView: View {
    @Environment(SessionStore.self) private var sessionStore

    @State private var searchText = ""
    @State private var clientName = ""
    @State private var clientPhone = ""
    @State private var stylePreferences = ""
    @State private var hasConsent = true
    @State private var selectedAppointmentClient = "Ananya Rao"
    @State private var appointmentMode = AppointmentMode.inStore
    @State private var appointmentDate = Calendar.current.date(byAdding: .hour, value: 3, to: .now) ?? .now
    @State private var isNewClientPresented = false
    @State private var isBookingPresented = false
    @State private var isMoreAppointmentsPresented = false
    @State private var isProfilePresented = false
    @State private var contentAppeared = false

    @State private var clients: [AssociateClient] = [
        AssociateClient(name: "Ananya Rao",   phone: "+91 98765 43210", preferences: "Minimal gold, silk sarees"),
        AssociateClient(name: "Kabir Mehta",  phone: "+91 98111 22009", preferences: "Tailored jackets, navy tones"),
        AssociateClient(name: "Mira Kapoor",  phone: "+91 90000 77123", preferences: "Statement earrings, emerald")
    ]
    @State private var appointments: [AssociateAppointment] = [
        AssociateAppointment(clientName: "Ananya Rao",  date: Calendar.current.date(bySettingHour: 16, minute: 30, second: 0, of: .now) ?? .now, mode: .inStore),
        AssociateAppointment(clientName: "Kabir Mehta", date: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: .now) ?? .now) ?? .now, mode: .video),
        AssociateAppointment(clientName: "Mira Kapoor", date: Calendar.current.date(byAdding: .day, value: 3, to: Calendar.current.date(bySettingHour: 14, minute: 15, second: 0, of: .now) ?? .now) ?? .now, mode: .inStore),
        AssociateAppointment(clientName: "Rhea Sethi",  date: Calendar.current.date(byAdding: .day, value: 5, to: Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: .now) ?? .now) ?? .now, mode: .video)
    ]

    private var filteredClients: [AssociateClient] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return clients }
        return clients.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            $0.phone.localizedCaseInsensitiveContains(q)
        }
    }

    private var sortedAppointments: [AssociateAppointment] {
        appointments.sorted { $0.date < $1.date }
    }

    private var nextAppointment: AssociateAppointment? {
        sortedAppointments.first { $0.date >= .now }
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

    private var canCreateClient: Bool {
        !clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !clientPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        hasConsent
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 20)

                VStack(spacing: 24) {
                    nextAppointmentBanner

                    if !upcomingAppointments.isEmpty || !laterAppointments.isEmpty {
                        thisWeekSection
                    }

                    clientsSection
                    bookingTrigger
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
        }
        .background(RSMSColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.82).delay(0.05)) {
                contentAppeared = true
            }
        }
        .sheet(isPresented: $isNewClientPresented) { newClientSheet }
        .sheet(isPresented: $isBookingPresented) { bookingSheet }
        .sheet(isPresented: $isMoreAppointmentsPresented) { moreAppointmentsSheet }
        .sheet(isPresented: $isProfilePresented) { SalesProfileSheet() }
    }

    private var headerBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(sessionStore.currentUser?.name?.components(separatedBy: " ").first ?? "Clienteling")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(RSMSColors.primaryText)
            }

            Spacer()

            HStack(spacing: 10) {
                Button { isProfilePresented = true } label: {
                    ZStack {
                        Circle()
                            .fill(RSMSColors.burgundy)
                            .frame(width: 40, height: 40)
                        Text(initials(for: sessionStore.currentUser?.name))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(BounceButtonStyle())
            }
        }
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : -12)
        .animation(.spring(response: 0.55, dampingFraction: 0.82), value: contentAppeared)
    }

    private var nextAppointmentBanner: some View {
        Group {
            if let appt = nextAppointment {
                Button {} label: {
                    HStack(spacing: 16) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(RSMSColors.burgundy)
                                .frame(width: 52, height: 52)
                            Image(systemName: appt.mode.icon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 5) {
                                Text("NEXT UP")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(RSMSColors.burgundy)
                                    .kerning(1.3)
                                Text("·")
                                    .font(.system(size: 9))
                                    .foregroundStyle(RSMSColors.secondaryText.opacity(0.5))
                                Text(appt.mode.title.uppercased())
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(RSMSColors.burgundy)
                                    .kerning(1.3)
                            }
                            Text(appt.clientName)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(RSMSColors.primaryText)
                            Text(appt.time)
                                .font(.system(size: 13))
                                .foregroundStyle(RSMSColors.secondaryText)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(RSMSColors.secondaryText.opacity(0.35))
                    }
                    .padding(18)
                    .background(RSMSColors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(RSMSColors.cardBorder, lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 6)
                }
                .buttonStyle(BounceButtonStyle())
            } else {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.secondary.opacity(0.1))
                            .frame(width: 44, height: 44)
                        Image(systemName: "calendar")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.secondary)
                    }
                    Text("No upcoming appointments")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(RSMSColors.secondaryText)
                    Spacer()
                }
                .padding(18)
                .background(RSMSColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(RSMSColors.cardBorder, lineWidth: 0.5)
                )
            }
        }
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : 16)
        .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.05), value: contentAppeared)
    }

    private var thisWeekSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("This Week")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(RSMSColors.darkBrown)
                Spacer()
                if !laterAppointments.isEmpty {
                    Button("View All") { isMoreAppointmentsPresented = true }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(RSMSColors.burgundy)
                }
            }
            .padding(.horizontal, 2)

            VStack(spacing: 0) {
                let items = Array((upcomingAppointments + laterAppointments).prefix(3).enumerated())
                ForEach(items, id: \.element.id) { index, appt in
                    appointmentRow(appt)
                    if index < items.count - 1 {
                        Rectangle()
                            .fill(Color.black.opacity(0.055))
                            .frame(height: 0.5)
                            .padding(.leading, 72)
                    }
                }
            }
            .background(RSMSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(RSMSColors.cardBorder, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 5)
        }
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : 20)
        .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.1), value: contentAppeared)
    }

    private var clientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Clients")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(RSMSColors.darkBrown)
                Spacer()
                Button {
                    isNewClientPresented = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(RSMSColors.burgundy)
                        .frame(width: 30, height: 30)
                        .background(RSMSColors.burgundy.opacity(0.09))
                        .clipShape(Circle())
                }
                .buttonStyle(BounceButtonStyle())
            }
            .padding(.horizontal, 2)

            clientListPreview
        }
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : 20)
        .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.15), value: contentAppeared)
    }

    @ViewBuilder
    private var clientListPreview: some View {
        VStack(spacing: 0) {
            let preview = Array(clients.prefix(3).enumerated())
            ForEach(preview, id: \.element.id) { index, client in
                clientRow(client)
                if index < preview.count - 1 {
                    Rectangle()
                        .fill(Color.black.opacity(0.055))
                        .frame(height: 0.5)
                        .padding(.leading, 72)
                }
            }
            if clients.count > 3 {
                Rectangle()
                    .fill(Color.black.opacity(0.055))
                    .frame(height: 0.5)
                    .padding(.leading, 20)
                NavigationLink {
                    ClientsListView(clients: $clients)
                } label: {
                    HStack {
                        Text("See all \(clients.count) clients")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(RSMSColors.burgundy)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(RSMSColors.burgundy.opacity(0.5))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                }
            }
        }
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(RSMSColors.cardBorder, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 14, x: 0, y: 5)
    }

    private var bookingTrigger: some View {
        Button { isBookingPresented = true } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.22))
                        .frame(width: 44, height: 44)
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Book Appointment")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("In-store or video consultation")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.65))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [RSMSColors.burgundy, Color(red: 0.35, green: 0.03, blue: 0.08)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: RSMSColors.burgundy.opacity(0.3), radius: 16, x: 0, y: 7)
        }
        .buttonStyle(BounceButtonStyle())
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : 20)
        .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.25), value: contentAppeared)
    }

    private func clientRow(_ client: AssociateClient) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(RSMSColors.burgundy.opacity(0.1))
                    .frame(width: 46, height: 46)
                Text(String(client.name.prefix(1)))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(RSMSColors.burgundy)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(client.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RSMSColors.primaryText)
                Text(client.preferences)
                    .font(.system(size: 12))
                    .foregroundStyle(RSMSColors.secondaryText)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(client.phone)
                    .font(.system(size: 11))
                    .foregroundStyle(RSMSColors.secondaryText)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(RSMSColors.secondaryText.opacity(0.28))
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
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

    private var newClientSheet: some View {
        NavigationStack {
            Form {
                Section("Client Details") {
                    TextField("Full Name", text: $clientName)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                    TextField("Phone Number", text: $clientPhone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }

                Section("Style Preferences") {
                    TextField("Colors, fits, fabrics, occasions…", text: $stylePreferences, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Toggle("Client consent received", isOn: $hasConsent)
                        .tint(RSMSColors.burgundy)
                } footer: {
                    Text("Required before saving personal details.")
                }
            }
            .navigationTitle("New Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isNewClientPresented = false }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveClientCard() }
                        .bold()
                        .disabled(!canCreateClient)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var bookingSheet: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    Picker("Client", selection: $selectedAppointmentClient) {
                        ForEach(clients) { c in Text(c.name).tag(c.name) }
                    }
                    DatePicker(
                        "Date & Time",
                        selection: $appointmentDate,
                        in: Date.now...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .tint(RSMSColors.burgundy)
                }

                Section("Type") {
                    Picker("Appointment Type", selection: $appointmentMode) {
                        ForEach(AppointmentMode.allCases) { mode in
                            Label(mode.title, systemImage: mode.icon).tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                    .tint(RSMSColors.burgundy)
                }

                Section {
                    Button {
                        bookAppointment()
                        isBookingPresented = false
                    } label: {
                        HStack {
                            Spacer()
                            Label("Confirm Booking", systemImage: "calendar.badge.plus")
                                .font(.headline)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Book Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isBookingPresented = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var moreAppointmentsSheet: some View {
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
            .navigationTitle("All Appointments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { isMoreAppointmentsPresented = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func saveClientCard() {
        let name = clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = clientPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefs = stylePreferences.trimmingCharacters(in: .whitespacesAndNewlines)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
            clients.insert(AssociateClient(name: name, phone: phone, preferences: prefs.isEmpty ? "Preferences to be captured" : prefs), at: 0)
        }
        selectedAppointmentClient = name
        isNewClientPresented = false
        clientName = ""; clientPhone = ""; stylePreferences = ""; hasConsent = true
    }

    private func bookAppointment() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
            appointments.insert(AssociateAppointment(clientName: selectedAppointmentClient, date: appointmentDate, mode: appointmentMode), at: 0)
        }
    }

    private func initials(for name: String?) -> String {
        guard let name, !name.isEmpty else { return "SA" }
        let parts = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if parts.count >= 2 { return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased() }
        return String((parts.first ?? "SA").prefix(2)).uppercased()
    }
}

fileprivate struct ClientsListView: View {
    @Binding var clients: [AssociateClient]
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var filteredClients: [AssociateClient] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return clients }
        return clients.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            $0.phone.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        List {
            ForEach(filteredClients) { client in
                clientRow(client)
                    .listRowInsets(EdgeInsets())
            }
            .onDelete { indexSet in
                let idsToDelete = indexSet.map { filteredClients[$0].id }
                clients.removeAll { idsToDelete.contains($0.id) }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by name or phone")
        .navigationTitle("Clients")
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if filteredClients.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    private func clientRow(_ client: AssociateClient) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(RSMSColors.burgundy.opacity(0.1))
                    .frame(width: 46, height: 46)
                Text(String(client.name.prefix(1)))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(RSMSColors.burgundy)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(client.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(RSMSColors.primaryText)
                Text(client.preferences)
                    .font(.system(size: 12))
                    .foregroundStyle(RSMSColors.secondaryText)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(client.phone)
                    .font(.system(size: 11))
                    .foregroundStyle(RSMSColors.secondaryText)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}

fileprivate struct BounceButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

fileprivate struct AssociateClient: Identifiable {
    let id = UUID()
    let name: String
    let phone: String
    let preferences: String
}

fileprivate struct AssociateAppointment: Identifiable {
    let id = UUID()
    let clientName: String
    let date: Date
    let mode: AppointmentMode
    var time: String { date.formatted(date: .abbreviated, time: .shortened) }
}

fileprivate enum AppointmentMode: String, CaseIterable, Identifiable {
    case inStore, video
    var id: String { rawValue }
    var title: String { self == .inStore ? "In-store" : "Video" }
    var icon: String { self == .inStore ? "bag.fill" : "video.fill" }
}

struct SalesSettingsView: View {
    @Environment(SessionStore.self) private var sessionStore

    var body: some View {
        Form {
            Section("Preferences") {
                NavigationLink("Notifications") { Text("Notifications") }
                NavigationLink("Language") { Text("Language") }
            }

            Section {
                Button(role: .destructive) {
                    Task { try? await sessionStore.signOut() }
                } label: {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SalesProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var sessionStore
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ZStack {
                                Circle().fill(RSMSColors.burgundy.opacity(0.1)).frame(width: 80, height: 80)
                                Image(systemName: "person.crop.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundStyle(RSMSColors.burgundy)
                                    .symbolEffect(.bounce, value: appeared)
                            }
                            .scaleEffect(appeared ? 1 : 0.72)
                            .opacity(appeared ? 1 : 0)
                            .animation(.spring(response: 0.5, dampingFraction: 0.72), value: appeared)

                            Text(sessionStore.currentUser?.name ?? "Sales Associate")
                                .font(.system(size: 20, weight: .bold, design: .rounded))

                            Text("Sales Associate")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(RSMSColors.burgundy)
                                .padding(.horizontal, 14).padding(.vertical, 6)
                                .background(RSMSColors.burgundy.opacity(0.09))
                                .clipShape(Capsule())
                        }
                        .padding(.vertical, 16)
                        Spacer()
                    }
                }

                Section {
                    Button(role: .destructive) {
                        dismiss()
                        Task { try? await sessionStore.signOut() }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .onAppear { appeared = true }
        .presentationDragIndicator(.visible)
    }
}

struct SalesPlaceholderView: View {
    let title: String
    let message: String
    let icon: String
    @State private var appeared = false

    var body: some View {
        ZStack {
            RSMSColors.background.ignoresSafeArea()
            VStack(spacing: 24) {
                Image(systemName: icon)
                    .font(.system(size: 60))
                    .foregroundStyle(RSMSColors.burgundy)
                    .symbolEffect(.pulse, isActive: appeared)
                Text(title).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundStyle(RSMSColors.primaryText)
                Text(message).font(.system(size: 15)).foregroundStyle(RSMSColors.secondaryText).multilineTextAlignment(.center).padding(.horizontal, 32)
                Text("Coming Soon")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(RSMSColors.burgundy)
                    .clipShape(Capsule())
            }
        }
        .onAppear { appeared = true }
    }
}

struct SalesToolbarModifier: ViewModifier {
    let title: String
    @Environment(SessionStore.self) private var sessionStore
    @State private var isProfilePresented = false

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { isProfilePresented = true } label: {
                        ZStack {
                            Circle().fill(RSMSColors.burgundy).frame(width: 32, height: 32)
                            Text(initials(for: sessionStore.currentUser?.name))
                                .font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                        }
                    }
                }
            }
            .sheet(isPresented: $isProfilePresented) { SalesProfileSheet() }
    }

    private func initials(for name: String?) -> String {
        guard let name, !name.isEmpty else { return "SA" }
        let parts = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if parts.count >= 2 { return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased() }
        return String((parts.first ?? "SA").prefix(2)).uppercased()
    }
}

#Preview {
    SalesTabView().environment(SessionStore())
}
