//
//  AdminProfileSheet.swift
//  NexusRetail
//

import SwiftUI

struct AdminProfileSheet: View {
    @Environment(SessionStore.self) private var sessionStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 16) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(Color.nexusRed)
                                .frame(width: 60, height: 60)
                            
                            Text(initials(for: sessionStore.currentUser?.name))
                                .font(.title2.bold())
                                .foregroundColor(Color.nexusGold)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sessionStore.currentUser?.name ?? "Admin User")
                                .font(.headline)
                            
                            if let email = sessionStore.currentUser?.email {
                                Text(email)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Role: \(sessionStore.currentRole?.displayName ?? "Admin")")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.nexusGold.opacity(0.2))
                                .foregroundColor(Color.nexusRed)
                                .cornerRadius(8)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section(header: Text("Store Settings")) {
                    NavigationLink(destination: AdminStorePaymentSelectorView()) {
                        HStack(spacing: 12) {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(RSMSColors.burgundy)
                                .font(.system(size: 18))
                            Text("Payment Configuration")
                                .foregroundColor(RSMSColors.primaryText)
                                .font(RSMSFonts.body)
                        }
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        Task {
                            dismiss()
                            try? await sessionStore.signOut()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .accessibilityHint("Signs you out of your account and returns to the login screen")
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func initials(for name: String?) -> String {
        guard let name = name, !name.isEmpty else { return "AD" }
        let components = name.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        if components.count >= 2 {
            let first = components[0].prefix(1)
            let last = components[1].prefix(1)
            return "\(first)\(last)".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "AD"
    }
}

// MARK: - Store Selector for Payment Configuration
struct AdminStorePaymentSelectorView: View {
    @State private var stores: [Store] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            Group {
                if isLoading {
                    ProgressView("Loading stores...")
                        .tint(RSMSColors.burgundy)
                        .frame(maxHeight: .infinity)
                } else if let error = errorMessage {
                    VStack(spacing: RSMSSpacing.md) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(RSMSColors.error)
                        Text(error)
                            .font(RSMSFonts.subheadline)
                            .foregroundColor(RSMSColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else if stores.isEmpty {
                    VStack(spacing: RSMSSpacing.md) {
                        Image(systemName: "building.2.crop.circle")
                            .font(.system(size: 64))
                            .foregroundColor(RSMSColors.burgundy)
                        Text("No Stores Found")
                            .font(RSMSFonts.title)
                            .fontWeight(.bold)
                            .foregroundColor(RSMSColors.primaryText)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(stores) { store in
                            NavigationLink(destination: PaymentConfigurationView(isAdmin: true, storeID: store.id)) {
                                HStack(spacing: 12) {
                                    Image(systemName: store.isWarehouse == true ? "shippingbox.fill" : "building.2.fill")
                                        .foregroundColor(RSMSColors.burgundy)
                                        .font(.system(size: 18))
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(store.name)
                                            .font(RSMSFonts.body)
                                            .fontWeight(.semibold)
                                            .foregroundColor(RSMSColors.primaryText)
                                        if let address = store.address {
                                            Text(address)
                                                .font(RSMSFonts.caption)
                                                .foregroundColor(RSMSColors.secondaryText)
                                                .lineLimit(1)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
        }
        .navigationTitle("Select Store")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadStores()
        }
    }
    
    private func loadStores() async {
        isLoading = true
        errorMessage = nil
        do {
            self.stores = try await StoreRepository().fetchStores()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
