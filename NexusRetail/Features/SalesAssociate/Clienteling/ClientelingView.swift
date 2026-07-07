import SwiftUI
import Supabase

struct ClientelingView: View {
    @Environment(SessionStore.self) private var sessionStore

    @State private var searchText = ""
    @State private var isProfilePresented = false
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



    let offWhite = Color(hex: "F8F6F3")
    let maroon = Color(hex: "8B0000")

    var body: some View {
        ZStack {
            offWhite.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    headerBar
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
            }
            Spacer()
        }
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : -12)
        .animation(.spring(response: 0.55, dampingFraction: 0.82), value: contentAppeared)
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
        HStack(alignment: .center, spacing: 16) {
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
            VStack(alignment: .leading, spacing: 4) {
                Text(client.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.black)
                Text(client.phone)
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.gray.opacity(0.6))
                .padding(.leading, 4)
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
