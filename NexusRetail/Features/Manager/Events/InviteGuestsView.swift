import SwiftUI

struct InviteGuestsView: View {
    @Bindable var viewModel: EventsViewModel
    let eventId: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var sessionStore
    
    @State private var searchText = ""
    @State private var invitingGuestIds = Set<UUID>()
    @State private var failedGuestIds = Set<UUID>()
    @State private var showingInviteSuccess = false
    @State private var invitedGuestName = ""
    
    private var storeCustomers: [SupabaseClientModel] {
        viewModel.storeCustomers
    }
    
    private var currentGuestIds: Set<UUID> {
        guard let event = viewModel.events.first(where: { $0.id == eventId }) else { return [] }
        let eventGuests = event.eventGuests ?? []
        return Set(eventGuests.compactMap { $0.clientID })
    }
    
    private var availableCustomers: [SupabaseClientModel] {
        let available = storeCustomers.filter { !currentGuestIds.contains($0.id) }
        if searchText.isEmpty {
            return available
        } else {
            return available.filter { ($0.name ?? "").localizedCaseInsensitiveContains(searchText) || ($0.email ?? "").localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Customer List
                List(availableCustomers) { guest in
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(RSMSColors.burgundy.opacity(0.1))
                                .frame(width: 44, height: 44)
                            
                            Text(guest.avatarName)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(RSMSColors.burgundy)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(guest.name ?? "Unknown")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(RSMSColors.primaryText)
                            
                            Text(guest.email ?? "No Email")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                            
                            if failedGuestIds.contains(guest.id) {
                                Text("Email failed. Try again.")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            Task {
                                await invite(guest)
                            }
                        } label: {
                            if invitingGuestIds.contains(guest.id) {
                                ProgressView()
                                    .tint(.white)
                                    .frame(width: 58, height: 32)
                            } else {
                                Text(failedGuestIds.contains(guest.id) ? "Retry" : "Invite")
                                    .font(.system(size: 14, weight: .semibold))
                                    .frame(width: 58, height: 32)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(RSMSColors.burgundy)
                        .disabled(!hasValidEmail(guest.email) || invitingGuestIds.contains(guest.id))
                    }
                    .padding(.vertical, 6)
                }
                .listStyle(PlainListStyle())
                .searchable(text: $searchText, prompt: "Search customers")
                
                if availableCustomers.isEmpty && !searchText.isEmpty {
                    VStack {
                        Spacer()
                        Text("No customers found")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else if availableCustomers.isEmpty {
                    VStack {
                        Spacer()
                        Text("All customers are already invited.")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Invite Guests")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.fetchCustomers(for: sessionStore.currentUser?.storeID)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(RSMSColors.burgundy)
                }
            }
            .alert("Invitation Sent", isPresented: $showingInviteSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("The invitation has been sent to \(invitedGuestName).")
            }
        }
    }

    @MainActor
    private func invite(_ guest: SupabaseClientModel) async {
        invitingGuestIds.insert(guest.id)
        failedGuestIds.remove(guest.id)

        let currentUser = sessionStore.currentUser
        let didInvite = await viewModel.inviteGuest(
            guest,
            to: eventId,
            storeID: currentUser?.storeID,
            managerName: currentUser?.name,
            managerEmail: currentUser?.email
        )

        invitingGuestIds.remove(guest.id)
        if !didInvite {
            failedGuestIds.insert(guest.id)
        } else {
            invitedGuestName = guest.name?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? guest.name! : "the client"
            showingInviteSuccess = true
        }
    }

    private func hasValidEmail(_ email: String?) -> Bool {
        guard let email = email?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }
        let regex = #"^\S+@\S+\.\S+$"#
        return email.range(of: regex, options: .regularExpression) != nil
    }
}
