//
//  ManagerReturnsView.swift
//  NexusRetail
//

import SwiftUI
import Supabase
import Combine
import Foundation

struct AfterSalesTicketModel: Identifiable, Decodable {
    let id: UUID
    let type: String
    let warranty_status: String
    let stage: String
    let item_name: String
    let issue_description: String
    let created_at: Date
    
    // In PostgREST, join on app_user by foreign key
    let app_user: SpecialistInfo?
    
    struct SpecialistInfo: Decodable {
        let name: String?
    }
}

@MainActor
class ManagerReturnsViewModel: ObservableObject {
    @Published var tickets: [AfterSalesTicketModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchReturns(storeID: UUID?) async {
        guard let storeID = storeID else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response: [AfterSalesTicketModel] = try await SupabaseManager.shared.client
                .from("after_sales_ticket")
                .select("id, type, warranty_status, stage, item_name, issue_description, created_at, app_user(name)")
                .eq("store_id", value: storeID.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.tickets = response
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct ManagerReturnsView: View {
    @Environment(AppTheme.self) private var theme
    @StateObject private var viewModel = ManagerReturnsViewModel()
    @Environment(SessionStore.self) private var sessionStore
    
    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .tint(theme.burgundy)
            } else if let error = viewModel.errorMessage {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text(error)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            } else if viewModel.tickets.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    Text("No After-Sales Tickets")
                        .font(.headline)
                    Text("There are no returns or repairs logged for this store.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.tickets) { ticket in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(LocalizedStringKey(ticket.type.capitalized))
                                        .font(.system(size: 12, weight: .bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(ticket.type.lowercased() == "return" ? Color.red.opacity(0.1) : Color.blue.opacity(0.1))
                                        .foregroundColor(ticket.type.lowercased() == "return" ? .red : .blue)
                                        .clipShape(Capsule())
                                    
                                    Spacer()
                                    
                                    Text(LocalizedStringKey(ticket.stage.capitalized))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(theme.secondaryText)
                                }
                                
                                Text(ticket.item_name)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(theme.primaryText)
                                
                                Text(ticket.issue_description)
                                    .font(.system(size: 14))
                                    .foregroundColor(theme.secondaryText)
                                
                                Divider()
                                
                                HStack {
                                    Label(ticket.app_user?.name ?? "Unassigned", systemImage: "person.crop.circle")
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.primaryText)
                                    
                                    Spacer()
                                    
                                    Text(ticket.created_at, style: .date)
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.secondaryText)
                                }
                            }
                            .padding()
                            .background(theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            await viewModel.fetchReturns(storeID: sessionStore.currentUser?.storeID)
        }
    }
}
