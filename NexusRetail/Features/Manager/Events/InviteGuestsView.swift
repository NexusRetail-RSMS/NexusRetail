import SwiftUI

struct InviteGuestsView: View {
    @Bindable var viewModel: EventsViewModel
    let eventId: UUID
    @Environment(\.dismiss) private var dismiss
    @Environment(SessionStore.self) private var sessionStore
    
    @State private var searchText = ""
    @State private var selectedGuestIds = Set<UUID>()
    
    private var storeCustomers: [MockGuest] {
        viewModel.storeCustomers
    }
    
    private var currentGuestIds: Set<UUID> {
        let event = viewModel.events.first { $0.id == eventId }
        return Set(event?.guests.map { $0.id } ?? [])
    }
    
    private var availableCustomers: [MockGuest] {
        let available = storeCustomers.filter { !currentGuestIds.contains($0.id) }
        if searchText.isEmpty {
            return available
        } else {
            return available.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.email.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Select All Row
                if !availableCustomers.isEmpty {
                    Button {
                        if selectedGuestIds.count == availableCustomers.count {
                            selectedGuestIds.removeAll()
                        } else {
                            selectedGuestIds = Set(availableCustomers.map { $0.id })
                        }
                    } label: {
                        HStack {
                            Text("Select All")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(RSMSColors.burgundy)
                            Spacer()
                            if selectedGuestIds.count == availableCustomers.count && !availableCustomers.isEmpty {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(RSMSColors.burgundy)
                                    .font(.title3)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray.opacity(0.5))
                                    .font(.title3)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Divider()
                }
                
                // Customer List
                List(availableCustomers) { guest in
                    Button {
                        if selectedGuestIds.contains(guest.id) {
                            selectedGuestIds.remove(guest.id)
                        } else {
                            selectedGuestIds.insert(guest.id)
                        }
                    } label: {
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
                                Text(guest.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(RSMSColors.primaryText)
                                
                                Text(guest.email)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedGuestIds.contains(guest.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(RSMSColors.burgundy)
                                    .font(.title3)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray.opacity(0.5))
                                    .font(.title3)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Invite (\(selectedGuestIds.count))") {
                        viewModel.inviteGuests(to: eventId, guestIds: selectedGuestIds)
                        dismiss()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(selectedGuestIds.isEmpty ? .gray : RSMSColors.burgundy)
                    .disabled(selectedGuestIds.isEmpty)
                }
            }
        }
    }
}
