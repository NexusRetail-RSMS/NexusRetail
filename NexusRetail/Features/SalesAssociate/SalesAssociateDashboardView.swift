import SwiftUI

struct SalesAssociateDashboardView: View {
    @Environment(SessionStore.self) private var sessionStore

    @State private var searchText = ""
    @State private var clientName = ""
    @State private var clientPhone = ""
    @State private var stylePreferences = ""
    @State private var hasConsent = true
    @State private var isNewClientPresented = false
    @State private var isProfilePresented = false
    @State private var contentAppeared = false

    @State private var clients: [AssociateClient] = [
        AssociateClient(name: "Ananya Rao",   phone: "+91 98765 43210", email: "ananya.rao@example.com", preferences: "Minimal gold, silk sarees", purchasePattern: "Frequent"),
        AssociateClient(name: "Kabir Mehta",  phone: "+91 98111 22009", email: "kabir.mehta@example.com", preferences: "Tailored jackets, navy tones", purchasePattern: "Regular"),
        AssociateClient(name: "Mira Kapoor",  phone: "+91 90000 77123", email: "mira.kapoor@example.com", preferences: "Statement earrings, emerald", purchasePattern: "Occasional")
    ]

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

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                headerBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 20)

                VStack(spacing: 24) {
                    clientsSection
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
                NavigationLink {
                    ClientDetailView(client: client)
                } label: {
                    clientRow(client)
                }
                .buttonStyle(.plain)
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

    private func saveClientCard() {
        let name = clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = clientPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefs = stylePreferences.trimmingCharacters(in: .whitespacesAndNewlines)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
            clients.insert(AssociateClient(name: name, phone: phone, email: "new@example.com", preferences: prefs.isEmpty ? "Preferences to be captured" : prefs, purchasePattern: "None"), at: 0)
        }
        isNewClientPresented = false
        clientName = ""; clientPhone = ""; stylePreferences = ""; hasConsent = true
    }

    private func initials(for name: String?) -> String {
        guard let name, !name.isEmpty else { return "SA" }
        let parts = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if parts.count >= 2 { return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased() }
        return String((parts.first ?? "SA").prefix(2)).uppercased()
    }
}
