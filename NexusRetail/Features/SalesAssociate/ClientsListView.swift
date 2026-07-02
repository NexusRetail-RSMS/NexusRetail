import SwiftUI

struct ClientsListView: View {
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
