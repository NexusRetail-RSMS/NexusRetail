//
//  SalesTabView.swift
//  NexusRetail
//

import Charts
import SwiftUI

struct SalesTabView: View {
    @State private var clients = SalesAssociateSampleData.clients
    @State private var appointments = SalesAssociateSampleData.appointments

    var body: some View {
        TabView {
            SalesDashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2.fill")
                }

            NavigationStack {
                AssociateClientsTab(clients: $clients)
            }
            .tabItem {
                Label("Clients", systemImage: "person.2.fill")
            }

            NavigationStack {
                AssociateAppointmentsTab(clients: clients, appointments: $appointments)
            }
            .tabItem {
                Label("Appointments", systemImage: "calendar.badge.clock")
            }
        }
        .tint(RSMSColors.burgundy)
    }
}

// MARK: - Dashboard

private struct AssociateDashboardTab: View {
    @Environment(SessionStore.self) private var sessionStore
    @State private var chartFilter = RevenueFilter.month
    @State private var isScannerPresented = false
    @State private var isProfilePresented = false

    private var chartData: [RevenuePoint] {
        chartFilter == .month ? SalesAssociateSampleData.monthRevenue : SalesAssociateSampleData.weekRevenue
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                dashboardHeader
                metricGrid
                barcodeCard
                revenueChartCard
                topProductsCard
            }
            .screenPadding()
        }
        .background(RSMSColors.background.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $isScannerPresented) {
            BarcodeScannerPlaceholder()
        }
        .sheet(isPresented: $isProfilePresented) {
            SalesProfileSheet()
        }
    }

    private var dashboardHeader: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Dashboard")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(RSMSColors.primaryText)

                Text("Sales Associate")
                    .font(RSMSFonts.body)
                    .foregroundStyle(RSMSColors.secondaryText)
            }

            Spacer()

            Button {
                isScannerPresented = true
            } label: {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(RSMSColors.darkBurgundy)
                    .frame(width: 54, height: 54)
                    .background(RSMSColors.darkBurgundy.opacity(0.08))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Scan barcode")

            Button {
                isProfilePresented = true
            } label: {
                Text(initials(for: sessionStore.currentUser?.name))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(RSMSColors.burgundy)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Profile")
        }
    }

    private var metricGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            metricCard(title: "Total Revenue", value: "₹5.1Cr", icon: "indianrupeesign", tint: Color.teal)
            metricCard(title: "Assisted Sales", value: "128", icon: "bag.fill", tint: RSMSColors.burgundy)
            metricCard(title: "Appointments", value: "12", icon: "calendar", tint: Color.orange)
            metricCard(title: "Conversion", value: "41%", icon: "chart.line.uptrend.xyaxis", tint: Color.yellow)
        }
    }

    private var barcodeCard: some View {
        Button {
            isScannerPresented = true
        } label: {
            HStack(spacing: 16) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(.white.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Barcode Scan")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Scan products for checkout, lookup, or client recommendations")
                        .font(RSMSFonts.subheadline)
                        .foregroundStyle(.white.opacity(0.74))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
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
            .shadow(color: RSMSColors.burgundy.opacity(0.24), radius: 16, x: 0, y: 8)
        }
        .buttonStyle(.plain)
    }

    private var revenueChartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center) {
                Text("Store Revenue")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(RSMSColors.primaryText)

                Spacer()

                Picker("Revenue filter", selection: $chartFilter) {
                    ForEach(RevenueFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 178)
            }

            Chart(chartData) { point in
                BarMark(
                    x: .value("Period", point.label),
                    y: .value("Revenue", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [RSMSColors.burgundy, RSMSColors.chartBar],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(7)
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                        .foregroundStyle(RSMSColors.divider)
                    AxisValueLabel()
                        .foregroundStyle(RSMSColors.secondaryText)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption)
                        .foregroundStyle(RSMSColors.secondaryText)
                }
            }
            .frame(height: 250)

            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(RSMSColors.burgundy)
                    .frame(width: 24, height: 12)
                Text("Revenue in ₹ Lakhs")
                    .font(RSMSFonts.subheadline)
                    .foregroundStyle(RSMSColors.secondaryText)
            }
        }
        .padding(20)
        .luxuryCard()
    }

    private var topProductsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Sales Cards")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(RSMSColors.primaryText)
                Spacer()
                Text("Today")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(RSMSColors.burgundy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(RSMSColors.burgundy.opacity(0.08))
                    .clipShape(Capsule())
            }

            ForEach(SalesAssociateSampleData.salesCards) { card in
                HStack(spacing: 14) {
                    Image(systemName: card.icon)
                        .foregroundStyle(RSMSColors.burgundy)
                        .frame(width: 42, height: 42)
                        .background(RSMSColors.burgundy.opacity(0.08))
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text(card.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(RSMSColors.primaryText)
                        Text(card.subtitle)
                            .font(RSMSFonts.subheadline)
                            .foregroundStyle(RSMSColors.secondaryText)
                    }
                    Spacer()
                    Text(card.value)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(RSMSColors.primaryText)
                }
                .padding(.vertical, 4)
            }
        }
        .padding(20)
        .luxuryCard()
    }

    private func metricCard(title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 56, height: 56)
                .background(tint.opacity(0.16))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(RSMSColors.primaryText)
                    .minimumScaleFactor(0.75)
                    .lineLimit(1)

                Text(title)
                    .font(RSMSFonts.subheadline)
                    .foregroundStyle(RSMSColors.secondaryText)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(minHeight: 128)
        .background(RSMSColors.cardBackground.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(tint.opacity(0.22), lineWidth: 1)
        )
    }
}

// MARK: - Clients

private struct AssociateClientsTab: View {
    @Binding var clients: [AssociateClient]
    @State private var searchText = ""
    @State private var isNewClientPresented = false

    private var filteredClients: [AssociateClient] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return clients }
        return clients.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.phone.localizedCaseInsensitiveContains(query) ||
            $0.preferences.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        List {
            Section {
                ForEach(filteredClients) { client in
                    NavigationLink {
                        ClientCardDetailView(client: client)
                    } label: {
                        clientListRow(client)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(RSMSColors.background.ignoresSafeArea())
        .navigationTitle("Clients")
        .searchable(text: $searchText, prompt: "Search clients")
        .sheet(isPresented: $isNewClientPresented) {
            NewClientSheet(clients: $clients)
        }
    }

    private func clientListRow(_ client: AssociateClient) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(RSMSColors.burgundy.opacity(0.1))
                .frame(width: 48, height: 48)
                .overlay {
                    Text(client.initials)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(RSMSColors.burgundy)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(client.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(RSMSColors.primaryText)
                Text(client.preferences)
                    .font(RSMSFonts.subheadline)
                    .foregroundStyle(RSMSColors.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Text(client.tier)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(RSMSColors.burgundy)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RSMSColors.burgundy.opacity(0.08))
                .clipShape(Capsule())
        }
        .padding(.vertical, 6)
    }
}

private struct ClientCardDetailView: View {
    let client: AssociateClient

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Circle()
                        .fill(RSMSColors.burgundy)
                        .frame(width: 68, height: 68)
                        .overlay {
                            Text(client.initials)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }

                    Text(client.name)
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(RSMSColors.primaryText)
                    Text(client.phone)
                        .font(RSMSFonts.body)
                        .foregroundStyle(RSMSColors.secondaryText)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .luxuryCard()

                infoRow(title: "Style Preferences", value: client.preferences, icon: "sparkles")
                infoRow(title: "Purchase Pattern", value: client.purchasePattern, icon: "chart.line.uptrend.xyaxis")
                infoRow(title: "Recommended Next", value: client.recommendedNext, icon: "bag.badge.plus")
            }
            .screenPadding()
        }
        .background(RSMSColors.background.ignoresSafeArea())
        .navigationTitle("Client Card")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct NewClientSheet: View {
    @Binding var clients: [AssociateClient]
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var preferences = ""
    @State private var hasConsent = true

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !phone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        hasConsent
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Consented Details") {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                    TextField("Phone Number", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Style Preferences", text: $preferences, axis: .vertical)
                        .lineLimit(3...5)
                }

                Section {
                    Toggle("Client consent received", isOn: $hasConsent)
                        .tint(RSMSColors.burgundy)
                } footer: {
                    Text("Consent is required before saving client details.")
                }
            }
            .navigationTitle("New Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        clients.insert(
                            AssociateClient(
                                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                                phone: phone.trimmingCharacters(in: .whitespacesAndNewlines),
                                preferences: preferences.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Preferences to be captured" : preferences.trimmingCharacters(in: .whitespacesAndNewlines),
                                tier: "New",
                                purchasePattern: "New client. Purchase pattern will appear after assisted selling history is available.",
                                recommendedNext: "Discovery edit"
                            ),
                            at: 0
                        )
                        dismiss()
                    }
                    .bold()
                    .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Appointments

private struct AssociateAppointmentsTab: View {
    let clients: [AssociateClient]
    @Binding var appointments: [AssociateAppointment]
    @State private var isBookingPresented = false
    @State private var isMorePresented = false

    private var twoDayAppointments: [AssociateAppointment] {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: 2, to: .now) else { return [] }
        return appointments
            .filter { $0.date >= .now && $0.date < cutoff }
            .sorted { $0.date < $1.date }
    }

    private var laterAppointments: [AssociateAppointment] {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: 2, to: .now) else { return [] }
        return appointments
            .filter { $0.date >= cutoff }
            .sorted { $0.date < $1.date }
    }

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
            BookAppointmentSheet(clients: clients, appointments: $appointments)
        }
        .sheet(isPresented: $isMorePresented) {
            MoreAppointmentsSheet(appointments: laterAppointments)
        }
    }

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

    private var upcomingAppointmentsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Upcoming Appointments")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(RSMSColors.primaryText)

                Spacer()

                if !laterAppointments.isEmpty {
                    Button("View More") {
                        isMorePresented = true
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(RSMSColors.burgundy)
                }
            }

            VStack(spacing: 0) {
                if twoDayAppointments.isEmpty {
                    emptyStateRow(title: "No appointments in the next 2 days", icon: "calendar")
                } else {
                    ForEach(Array(twoDayAppointments.enumerated()), id: \.element.id) { index, appointment in
                        appointmentRow(appointment)
                        if index < twoDayAppointments.count - 1 {
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

private struct BookAppointmentSheet: View {
    let clients: [AssociateClient]
    @Binding var appointments: [AssociateAppointment]
    @Environment(\.dismiss) private var dismiss

    @State private var selectedClient: String
    @State private var appointmentDate = Calendar.current.date(byAdding: .hour, value: 3, to: .now) ?? .now
    @State private var mode = AppointmentMode.inStore

    init(clients: [AssociateClient], appointments: Binding<[AssociateAppointment]>) {
        self.clients = clients
        self._appointments = appointments
        self._selectedClient = State(initialValue: clients.first?.name ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    Picker("Client", selection: $selectedClient) {
                        ForEach(clients) { client in
                            Text(client.name).tag(client.name)
                        }
                    }
                }

                Section("Appointment") {
                    DatePicker("Date & Time", selection: $appointmentDate, in: Date.now..., displayedComponents: [.date, .hourAndMinute])
                    Picker("Type", selection: $mode) {
                        ForEach(AppointmentMode.allCases) { mode in
                            Label(mode.title, systemImage: mode.icon).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    Button {
                        appointments.append(AssociateAppointment(clientName: selectedClient, date: appointmentDate, mode: mode))
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Label("Confirm Booking", systemImage: "calendar.badge.plus")
                            Spacer()
                        }
                    }
                    .disabled(selectedClient.isEmpty)
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

private struct MoreAppointmentsSheet: View {
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

// MARK: - Shared UI

private func salesHero(title: String, subtitle: String, systemImage: String) -> some View {
    HStack(alignment: .top, spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(RSMSFonts.body)
                .foregroundStyle(.white.opacity(0.78))
                .fixedSize(horizontal: false, vertical: true)
        }

        Spacer()

        Image(systemName: systemImage)
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 48, height: 48)
            .background(.white.opacity(0.16))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .padding(20)
    .background(
        LinearGradient(
            colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    .shadow(color: RSMSColors.burgundy.opacity(0.24), radius: 18, x: 0, y: 10)
}

private func infoRow(title: String, value: String, icon: String) -> some View {
    HStack(alignment: .top, spacing: 14) {
        Image(systemName: icon)
            .foregroundStyle(RSMSColors.burgundy)
            .frame(width: 42, height: 42)
            .background(RSMSColors.burgundy.opacity(0.08))
            .clipShape(Circle())

        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(RSMSColors.primaryText)
            Text(value)
                .font(RSMSFonts.subheadline)
                .foregroundStyle(RSMSColors.secondaryText)
        }

        Spacer()
    }
    .padding(18)
    .luxuryCard()
}

private func emptyStateRow(title: String, icon: String) -> some View {
    HStack(spacing: 12) {
        Image(systemName: icon)
            .foregroundStyle(RSMSColors.burgundy)
            .frame(width: 42, height: 42)
            .background(RSMSColors.burgundy.opacity(0.08))
            .clipShape(Circle())
        Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(RSMSColors.secondaryText)
        Spacer()
    }
    .padding(16)
}

private func appointmentRow(_ appointment: AssociateAppointment) -> some View {
    HStack(spacing: 14) {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(RSMSColors.burgundy.opacity(0.09))
            .frame(width: 46, height: 46)
            .overlay {
                Image(systemName: appointment.mode.icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(RSMSColors.burgundy)
            }

        VStack(alignment: .leading, spacing: 4) {
            Text(appointment.clientName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(RSMSColors.primaryText)
            Text(appointment.time)
                .font(RSMSFonts.subheadline)
                .foregroundStyle(RSMSColors.secondaryText)
        }

        Spacer()

        Text(appointment.mode.title)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(RSMSColors.burgundy)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(RSMSColors.burgundy.opacity(0.08))
            .clipShape(Capsule())
    }
    .padding(14)
}

private func initials(for name: String?) -> String {
    guard let name, !name.isEmpty else { return "SA" }
    let parts = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    if parts.count >= 2 {
        return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
    }
    return String((parts.first ?? "SA").prefix(2)).uppercased()
}

private struct LuxuryCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(RSMSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: .black.opacity(0.045), radius: 18, x: 0, y: 8)
    }
}

private extension View {
    func luxuryCard() -> some View {
        modifier(LuxuryCardModifier())
    }

    func screenPadding() -> some View {
        padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 34)
    }
}

// MARK: - Data

private enum RevenueFilter: String, CaseIterable, Identifiable {
    case week
    case month

    var id: String { rawValue }
    var title: String { self == .week ? "Weekly" : "Monthly" }
}

private enum SalesAssociateSampleData {
    static let clients = [
        AssociateClient(
            name: "Ananya Rao",
            phone: "+91 98765 43210",
            preferences: "Minimal gold, silk sarees",
            tier: "VIP",
            purchasePattern: "Buys festive wear every 5-6 weeks, prefers warm gold accents.",
            recommendedNext: "Kundan choker and ivory silk dupatta"
        ),
        AssociateClient(
            name: "Kabir Mehta",
            phone: "+91 98111 22009",
            preferences: "Tailored jackets, navy tones",
            tier: "Gold",
            purchasePattern: "Often buys structured workwear and premium accessories.",
            recommendedNext: "Navy linen blazer and leather card case"
        ),
        AssociateClient(
            name: "Mira Kapoor",
            phone: "+91 90000 77123",
            preferences: "Statement earrings, emerald",
            tier: "Silver",
            purchasePattern: "Responds well to limited-drop jewelry recommendations.",
            recommendedNext: "Emerald drop earrings and velvet evening clutch"
        )
    ]

    static let appointments = [
        AssociateAppointment(clientName: "Ananya Rao", date: Calendar.current.date(bySettingHour: 16, minute: 30, second: 0, of: .now) ?? .now, mode: .inStore),
        AssociateAppointment(clientName: "Kabir Mehta", date: Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: .now) ?? .now) ?? .now, mode: .video),
        AssociateAppointment(clientName: "Mira Kapoor", date: Calendar.current.date(byAdding: .day, value: 3, to: Calendar.current.date(bySettingHour: 14, minute: 15, second: 0, of: .now) ?? .now) ?? .now, mode: .inStore),
        AssociateAppointment(clientName: "Rhea Sethi", date: Calendar.current.date(byAdding: .day, value: 5, to: Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: .now) ?? .now) ?? .now, mode: .video)
    ]

    static let monthRevenue = [
        RevenuePoint(label: "Jul", value: 3),
        RevenuePoint(label: "Aug", value: 2),
        RevenuePoint(label: "Sep", value: 2),
        RevenuePoint(label: "Oct", value: 2),
        RevenuePoint(label: "Nov", value: 1),
        RevenuePoint(label: "Dec", value: 22),
        RevenuePoint(label: "Jan", value: 78),
        RevenuePoint(label: "Feb", value: 68),
        RevenuePoint(label: "Mar", value: 124),
        RevenuePoint(label: "Apr", value: 74),
        RevenuePoint(label: "May", value: 77),
        RevenuePoint(label: "Jun", value: 52)
    ]

    static let weekRevenue = [
        RevenuePoint(label: "Mon", value: 18),
        RevenuePoint(label: "Tue", value: 24),
        RevenuePoint(label: "Wed", value: 21),
        RevenuePoint(label: "Thu", value: 36),
        RevenuePoint(label: "Fri", value: 42),
        RevenuePoint(label: "Sat", value: 54),
        RevenuePoint(label: "Sun", value: 31)
    ]

    static let salesCards = [
        SalesSummaryCard(title: "Premium Sarees", subtitle: "Top assisted category", value: "₹42L", icon: "sparkles"),
        SalesSummaryCard(title: "Clienteling Sales", subtitle: "From appointments", value: "₹18L", icon: "person.2.fill"),
        SalesSummaryCard(title: "Cross-sell Attach", subtitle: "Cart add-ons", value: "31%", icon: "bag.badge.plus")
    ]
}

private struct AssociateClient: Identifiable {
    let id = UUID()
    let name: String
    let phone: String
    let preferences: String
    let tier: String
    let purchasePattern: String
    let recommendedNext: String

    var initials: String {
        name
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }
}

private struct AssociateAppointment: Identifiable {
    let id = UUID()
    let clientName: String
    let date: Date
    let mode: AppointmentMode
    var time: String { date.formatted(date: .abbreviated, time: .shortened) }
}

private enum AppointmentMode: String, CaseIterable, Identifiable {
    case inStore
    case video

    var id: String { rawValue }
    var title: String { self == .inStore ? "In-store" : "Video" }
    var icon: String { self == .inStore ? "bag.fill" : "video.fill" }
}

private struct RevenuePoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

private struct SalesSummaryCard: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let value: String
    let icon: String
}

private struct BarcodeScannerPlaceholder: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 72, weight: .semibold))
                    .foregroundStyle(RSMSColors.burgundy)
                Text("Barcode Scanner")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                Text("Camera integration can plug in here for product lookup and checkout.")
                    .font(RSMSFonts.body)
                    .foregroundStyle(RSMSColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(RSMSColors.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SalesProfileSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var sessionStore

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Circle()
                    .fill(RSMSColors.burgundy.opacity(0.1))
                    .frame(width: 86, height: 86)
                    .overlay {
                        Text(initials(for: sessionStore.currentUser?.name))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(RSMSColors.burgundy)
                    }

                Text(sessionStore.currentUser?.name ?? "Sales Associate")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(RSMSColors.primaryText)

                Text("Sales Associate")
                    .font(RSMSFonts.subheadline)
                    .foregroundStyle(RSMSColors.secondaryText)

                Spacer()
            }
            .padding(24)
            .background(RSMSColors.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    let sessionStore = SessionStore()
    return SalesTabView()
        .environment(sessionStore)
}
