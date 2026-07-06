import SwiftUI
import Supabase

struct ClientelingView: View {
    @Environment(SessionStore.self) private var sessionStore

    @State private var searchText = ""
    @State private var clientName = ""
    @State private var clientPhone = ""
    @State private var stylePreferences = ""
    @State private var hasConsent = true
    @State private var isNewClientPresented = false
    @State private var isProfilePresented = false
    @State private var contentAppeared = false
    
    // Edit & Appointment State
    @State private var isEditingClient = false
    @State private var editingClientId: UUID?
    
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

    private var canCreateClient: Bool {
        !clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !clientPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        hasConsent
    }

    let offWhite = Color(hex: "F8F6F3")
    let maroon = Color(hex: "8B0000")

    var body: some View {
        ZStack {
            offWhite.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerBar
                    searchAndActionSection
                    filterSection
                    clientsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 48)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.82).delay(0.05)) {
                contentAppeared = true
            }
        }
        .sheet(isPresented: $isNewClientPresented) { newClientSheet }
        .sheet(isPresented: $isProfilePresented) { AdminProfileSheet() }
        .sheet(isPresented: $isNewAppointmentPresented) { newAppointmentSheet }
        .task { await loadClients() }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Clients")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.black)
                Text("Manage and view your client information")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            Button { isProfilePresented = true } label: {
                ZStack {
                    Circle()
                        .fill(maroon)
                        .frame(width: 44, height: 44)
                    Text(initials(for: sessionStore.currentUser?.name))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : -12)
        .animation(.spring(response: 0.55, dampingFraction: 0.82), value: contentAppeared)
    }

    // MARK: - Search & Add
    private var searchAndActionSection: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search clients by name or phone", text: $searchText)
                    .font(.system(size: 15))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.15), lineWidth: 1))
            
            Button {
                isEditingClient = false
                editingClientId = nil
                clientName = ""
                clientPhone = ""
                stylePreferences = ""
                hasConsent = true
                isNewClientPresented = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Add Client")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(maroon)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.15), lineWidth: 1))
            }
        }
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : 10)
        .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.1), value: contentAppeared)
    }
    
    // MARK: - Filters
    private var filterSection: some View {
        HStack(spacing: 12) {
            filterChip(title: "All Clients", icon: "person.2.fill", count: clients.count, isSelected: selectedFilter == "All Clients")
            filterChip(title: "Recent", icon: "clock", count: nil, isSelected: selectedFilter == "Recent")
            Spacer()
        }
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : 15)
        .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.15), value: contentAppeared)
    }
    
    private func filterChip(title: String, icon: String, count: Int?, isSelected: Bool) -> some View {
        Button {
            withAnimation {
                selectedFilter = title
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                
                if let count = count {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isSelected ? maroon : .gray)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color.white : Color.gray.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .foregroundColor(isSelected ? .white : .black)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? maroon : Color.white)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(isSelected ? 0 : 0.15), lineWidth: 1)
            )
        }
    }

    // MARK: - Clients List
    private var clientsSection: some View {
        VStack(spacing: 16) {
            ForEach(filteredClients, id: \.id) { client in
                NavigationLink {
                    ClientDetailView(client: client)
                } label: {
                    clientRow(client)
                }
                .buttonStyle(.plain)
            }
        }
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : 20)
        .animation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.2), value: contentAppeared)
    }

    private func clientRow(_ client: AssociateClient) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color(hex: "F9EFEF")) // light maroon/pink
                    .frame(width: 52, height: 52)
                Text(String(client.name.prefix(1)))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(maroon)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(client.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)
                    Spacer()
                    Text(client.phone)
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.gray.opacity(0.6))
                        .padding(.leading, 4)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "bag")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    Text(client.preferences)
                        .font(.system(size: 13))
                        .foregroundStyle(.gray)
                        .lineLimit(1)
                }
                
                HStack {
                    statusBadge(for: client.purchasePattern)
                    Spacer()
                    Menu {
                        Button("Edit Client") {
                            isEditingClient = true
                            editingClientId = client.dbId
                            clientName = client.name
                            clientPhone = client.phone
                            stylePreferences = client.preferences
                            hasConsent = true
                            isNewClientPresented = true
                        }
                        Button("View Purchase History", action: {})
                        Button("Schedule Appointment") {
                            appointmentClientName = client.name
                            appointmentClientPhone = client.phone
                            appointmentClientEmail = client.email
                            isNewAppointmentPresented = true
                        }
                        Button("Delete Client", role: .destructive) {
                            deleteClient(client)
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(maroon)
                            .frame(width: 32, height: 24)
                            .background(Color.red.opacity(0.05))
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 3)
    }
    
    private func statusBadge(for pattern: String) -> some View {
        let isVIP = pattern.contains("VIP")
        let isNew = pattern.contains("New")
        
        let color = isVIP ? maroon : (isNew ? Color.blue : Color(hex: "B8860B")) // Dark goldenrod for regular
        let bgColor = isVIP ? Color.red.opacity(0.1) : (isNew ? Color.blue.opacity(0.1) : Color.yellow.opacity(0.15))
        let icon = isVIP ? "crown" : (isNew ? "sparkles" : "person")
        
        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(pattern)
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(bgColor)
        .clipShape(Capsule())
    }

    // MARK: - New Client Sheet
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
                        .tint(maroon)
                } footer: {
                    Text("Required before saving personal details.")
                }
            }
            .navigationTitle(isEditingClient ? "Edit Client" : "New Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isNewClientPresented = false }
                        .foregroundColor(maroon)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveClientCard() }
                        .bold()
                        .foregroundColor(canCreateClient ? maroon : .gray)
                        .disabled(!canCreateClient)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func saveClientCard() {
        let name = clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = clientPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        let editingId = isEditingClient ? editingClientId : nil

        Task {
            do {
                if let editingId {
                    // Persist an edit as a real UPDATE (previously always inserted a duplicate).
                    struct UpdateClient: Encodable {
                        let name: String
                        let phone: String
                    }
                    try await SupabaseManager.shared.client
                        .from("client")
                        .update(UpdateClient(name: name, phone: phone))
                        .eq("id", value: editingId)
                        .execute()
                } else {
                    struct InsertClient: Encodable {
                        let name: String
                        let phone: String
                        let created_by: UUID?
                    }
                    try await SupabaseManager.shared.client
                        .from("client")
                        .insert(InsertClient(name: name, phone: phone, created_by: sessionStore.currentUser?.id))
                        .execute()
                }
                await loadClients()
            } catch {
                print("Error saving client: \(error)")
            }
        }

        isNewClientPresented = false
        isEditingClient = false
        editingClientId = nil
        clientName = ""
        clientPhone = ""
        stylePreferences = ""
        hasConsent = true
    }

    private func deleteClient(_ client: AssociateClient) {
        // Optimistic removal; reconcile with the DB result below.
        withAnimation { clients.removeAll { $0.id == client.id } }

        guard let dbId = client.dbId else { return } // sample/local-only row
        struct DeleteClientParams: Encodable { let p_client_id: UUID }
        Task {
            do {
                try await SupabaseManager.shared.client
                    .rpc("delete_client", params: DeleteClientParams(p_client_id: dbId))
                    .execute()
                await loadClients()
            } catch {
                print("Error deleting client: \(error)")
                await loadClients() // failed delete → row reappears instead of silently vanishing
            }
        }
    }

    private func initials(for name: String?) -> String {
        guard let name, !name.isEmpty else { return "SA" }
        let parts = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if parts.count >= 2 { return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased() }
        return String((parts.first ?? "SA").prefix(2)).uppercased()
    }

    // MARK: - New Appointment Sheet
    private var newAppointmentSheet: some View {
        NavigationStack {
            Form {
                Section("Client Details") {
                    TextField("Contact Number", text: $appointmentClientPhone)
                        .foregroundColor(.gray)
                        .disabled(true)
                    TextField("Full Name", text: $appointmentClientName)
                        .foregroundColor(.gray)
                        .disabled(true)
                    TextField("Email Address", text: $appointmentClientEmail)
                        .foregroundColor(.gray)
                        .disabled(true)
                }

                Section("Appointment") {
                    HStack {
                        Text("Date")
                        Spacer()
                        Text("2 Jul 2026")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(16)
                    }
                    
                    HStack {
                        Text("Time")
                        Spacer()
                        Text("5:09 PM")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(16)
                    }
                    
                    HStack {
                        Text("Type")
                        Spacer()
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                                Text("In Store")
                            }
                            HStack(spacing: 4) {
                                Image(systemName: "circle").foregroundColor(.gray)
                                Text("Video")
                            }
                        }
                    }
                    
                    TextField("Product / Notes", text: .constant(""))
                        .foregroundColor(.gray)
                }
            }
            .navigationTitle("New Appointment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isNewAppointmentPresented = false }
                        .foregroundColor(maroon)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { isNewAppointmentPresented = false }
                        .bold()
                        .foregroundColor(.gray) // Disabled for mock
                        .disabled(true)
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
            
            // Only this associate's client book (created / sold-to / appointment),
            // matching the performance-attribution definition. Checkout linking
            // still searches all clients so anyone can attach an existing customer.
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
            print("Error fetching clients: \\(error)")
        }
    }
}
