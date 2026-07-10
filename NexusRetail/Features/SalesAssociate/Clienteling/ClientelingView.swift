import SwiftUI
import Supabase

struct ClientelingView: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(AppTheme.self) private var theme

    @State private var searchText = ""
    @State private var contentAppeared = false

    // Appointment State
    @State private var isNewAppointmentPresented = false
    @State private var appointmentClientName = ""
    @State private var appointmentClientPhone = ""
    @State private var appointmentClientEmail = ""

    @State private var selectedFilter = "All Clients"
    @State private var clients: [AssociateClient] = []

    private var filteredClients: [AssociateClient] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return clients }
        return clients.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            $0.phone.localizedCaseInsensitiveContains(q)
        }
    }

    // MARK: - Accent helpers
    private var accent: Color { theme.isDarkMode ? theme.antiqueGold : theme.burgundy }
    private var cardBg: Color { theme.isDarkMode ? Color(hex: "1E1209") : Color.white }
    private var avatarBg: Color { theme.isDarkMode ? Color(hex: "2C1800") : theme.burgundy.opacity(0.08) }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: 20) {
                    searchBar
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                .background(theme.background.ignoresSafeArea(edges: .top))
                .zIndex(1)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        clientsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 56)
                }
            }
            .safeAreaInset(edge: .top) {
                headerBar
                    .fadingMaterialHeader()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.82).delay(0.05)) {
                contentAppeared = true
            }
        }
        .sheet(isPresented: $isNewAppointmentPresented) { newAppointmentSheet }
        .task { await loadClients() }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Clients")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(theme.primaryText)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 8)
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : -12)
        .animation(.spring(response: 0.55, dampingFraction: 0.82), value: contentAppeared)
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(theme.secondaryText)
            TextField("Search clients…", text: $searchText)
                .font(.system(size: 15))
                .foregroundStyle(theme.primaryText)
                .tint(accent)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(theme.secondaryText)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(theme.isDarkMode ? Color(hex: "1C1C1C") : Color.black.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(accent.opacity(theme.isDarkMode ? 0.18 : 0.0), lineWidth: 1)
        )
        .opacity(contentAppeared ? 1 : 0)
        .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.1), value: contentAppeared)
    }

    // MARK: - Clients List
    private var clientsSection: some View {
        VStack(spacing: 12) {
            if filteredClients.isEmpty && !clients.isEmpty {
                Text("No results for \"\(searchText)\"")
                    .font(.system(size: 14))
                    .foregroundStyle(theme.secondaryText)
                    .padding(.top, 32)
            } else {
                ForEach(Array(filteredClients.enumerated()), id: \.element.id) { index, client in
                    NavigationLink {
                        ClientDetailView(client: client)
                    } label: {
                        clientRow(client)
                    }
                    .buttonStyle(.plain)
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 20)
                    .animation(
                        .spring(response: 0.55, dampingFraction: 0.82).delay(0.12 + Double(index) * 0.04),
                        value: contentAppeared
                    )
                }
            }
        }
    }

    // MARK: - Client Row Card (flashy, pops out)
    private func clientRow(_ client: AssociateClient) -> some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(theme.burgundy)
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                Text(initials(for: client.name))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 1)
            }

            // Name + phone
            VStack(alignment: .leading, spacing: 4) {
                Text(client.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(theme.primaryText)
                Text(client.phone)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.secondaryText)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(accent.opacity(0.5))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }

    // MARK: - Helpers
    private func initials(for name: String?) -> String {
        guard let name, !name.isEmpty else { return "SA" }
        let parts = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if parts.count >= 2 { return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased() }
        return String((parts.first ?? "SA").prefix(2)).uppercased()
    }

    // MARK: - New Appointment Sheet (kept for compatibility)
    private var newAppointmentSheet: some View {
        NavigationStack {
            Form {
                Section("Client Details") {
                    TextField("Contact Number", text: $appointmentClientPhone)
                        .foregroundColor(theme.secondaryText).disabled(true)
                    TextField("Full Name", text: $appointmentClientName)
                        .foregroundColor(theme.secondaryText).disabled(true)
                    TextField("Email Address", text: $appointmentClientEmail)
                        .foregroundColor(theme.secondaryText).disabled(true)
                }
                Section("Appointment") {
                    HStack {
                        Text("Date"); Spacer()
                        Text("2 Jul 2026").padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1)).cornerRadius(16)
                    }
                    HStack {
                        Text("Time"); Spacer()
                        Text("5:09 PM").padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1)).cornerRadius(16)
                    }
                    TextField("Product / Notes", text: .constant("")).foregroundColor(theme.secondaryText)
                }
            }
            .navigationTitle("New Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isNewAppointmentPresented = false }
                        .foregroundColor(accent)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { isNewAppointmentPresented = false }
                        .bold().foregroundColor(theme.secondaryText).disabled(true)
                }
            }
        }
        .presentationDetents([.fraction(0.9), .large])
    }

    private func loadClients() async {
        do {
            struct FetchClient: Decodable {
                let id: UUID
                let name: String
                let phone: String
                let email: String?
            }
            let fetched: [FetchClient] = try await SupabaseManager.shared.client
                .rpc("get_my_clients")
                .execute()
                .value
            await MainActor.run {
                self.clients = fetched.map { c in
                    AssociateClient(
                        dbId: c.id,
                        name: c.name,
                        phone: c.phone,
                        email: c.email ?? "",
                        preferences: "Preferences to be captured",
                        purchasePattern: "New Client"
                    )
                }
            }
        } catch {
            print("Error fetching clients: \(error)")
        }
    }
}
