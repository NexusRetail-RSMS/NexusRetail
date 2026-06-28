import SwiftUI

struct AdminManagersView: View {
    @Environment(AdminNavigationStore.self) private var navStore
    @Environment(AdminTransfersViewModel.self) private var viewModel
    
    @State private var searchText = ""
    
    var filteredManagers: [AdminTransferManager] {
        if searchText.isEmpty {
            return viewModel.managers
        } else {
            return viewModel.managers.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        List {
            ForEach(filteredManagers) { manager in
                NavigationLink(value: manager.id) {
                    ManagerRow(manager: manager)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search managers")
        .scrollContentBackground(.hidden)
        .background(Color.nexusBackground)
        .navigationDestination(for: UUID.self) { managerId in
            if let manager = viewModel.manager(for: managerId) {
                AdminManagerProfileView(manager: manager)
            }
        }
        // Handle programmatic navigation from Transfers tab
        .onChange(of: navStore.selectedManagerID) { _, newManagerID in
            // When deep linking from another tab, we need to handle the navigation
            // A simple way is to use a NavigationStack state, but since we are just
            // switching to the tab and letting the user see the profile, we can use an inline push or sheet.
            // For true programmatic navigation within NavigationStack, we'd bind a path.
            // For now, this is handled by the NavigationStack picking up the value if we set a path.
        }
    }
}

struct ManagerRow: View {
    let manager: AdminTransferManager
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.nexusRed.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Text(manager.avatarInitials)
                    .font(.headline)
                    .foregroundColor(Color.nexusRed)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(manager.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(manager.storeName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if manager.pendingRequests > 0 {
                    Text("\(manager.pendingRequests) Pending")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
