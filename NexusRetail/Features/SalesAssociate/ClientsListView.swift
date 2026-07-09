import SwiftUI

struct ClientsListView: View {
    @Binding var clients: [AssociateClient]
    @Environment(AppTheme.self) private var theme
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var accent: Color { theme.isDarkMode ? theme.antiqueGold : theme.burgundy }
    private var cardBg: Color  { theme.isDarkMode ? Color(hex: "1E1209") : Color.white }
    private var avatarBg: Color { theme.isDarkMode ? Color(hex: "2C1800") : theme.burgundy.opacity(0.08) }

    private var filteredClients: [AssociateClient] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return clients }
        return clients.filter {
            $0.name.localizedCaseInsensitiveContains(q) ||
            $0.phone.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            if filteredClients.isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(filteredClients) { client in
                            clientRow(client)
                        }
                        .onDelete { indexSet in
                            let idsToDelete = indexSet.map { filteredClients[$0].id }
                            clients.removeAll { idsToDelete.contains($0.id) }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 32)
                }
            }
        }
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search by name or phone"
        )
        .navigationTitle("Clients")
        .navigationBarTitleDisplayMode(.inline)
        .tint(accent)
    }

    private func clientRow(_ client: AssociateClient) -> some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(avatarBg)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Circle().strokeBorder(accent.opacity(theme.isDarkMode ? 0.35 : 0.20), lineWidth: 1.5)
                    )
                Text(String(client.name.prefix(1)))
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(accent)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(client.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.primaryText)
                Text(client.preferences)
                    .font(.system(size: 12))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text(client.phone)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.secondaryText)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(accent.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    theme.isDarkMode
                        ? LinearGradient(colors: [theme.antiqueGold.opacity(0.20), theme.darkWoodBrown.opacity(0.25)],
                                         startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [theme.burgundy.opacity(0.08), Color.clear],
                                         startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1
                )
        )
        .contentShape(Rectangle())
    }
}
