//
//  ManagerRequestsView.swift
//  NexusRetail
//

import SwiftUI
import Supabase
import Combine
import Foundation

struct TransferRequestModel: Identifiable, Decodable {
    let id: UUID
    let requesting_store_id: UUID?
    let source_store_id: UUID?
    let quantity: Int?
    let urgency: String?
    let status: String?
    let created_at: Date?
    let products: ProductInfo?
    
    struct ProductInfo: Decodable {
        let item_name: String?
        let image_url: String?
    }
}

@MainActor
class ManagerRequestsViewModel: ObservableObject {
    @Published var requests: [TransferRequestModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchRequests(storeID: UUID?) async {
        guard let storeID = storeID else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response: [TransferRequestModel] = try await SupabaseManager.shared.client
                .from("transfer_request")
                .select("id, requesting_store_id, source_store_id, quantity, urgency, status, created_at, products(item_name, image_url)")
                .or("source_store_id.eq.\(storeID.uuidString),requesting_store_id.eq.\(storeID.uuidString)")
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.requests = response
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct ManagerRequestsView: View {
    @Environment(AppTheme.self) private var theme
    @StateObject private var viewModel = ManagerRequestsViewModel()
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
            } else {
                let pendingRequests = viewModel.requests.filter { ($0.status ?? "pending").lowercased() == "pending" }
                
                if pendingRequests.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(theme.secondaryText)
                        Text("No Pending Requests")
                            .font(.headline)
                        Text("There are currently no store transfer requests.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(pendingRequests) { request in
                            HStack(spacing: 16) {
                                if let urlString = request.products?.image_url, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Color.gray.opacity(0.2)
                                    }
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                        .overlay(Image(systemName: "shippingbox").foregroundColor(.gray))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(request.products?.item_name ?? "Unknown Item")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(theme.primaryText)
                                        .lineLimit(1)
                                    
                                    HStack {
                                        Text("Qty: \(request.quantity ?? 0)")
                                            .font(.system(size: 12, weight: .bold))
                                        
                                        Text("•")
                                            .font(.system(size: 12))
                                            .foregroundColor(theme.secondaryText)
                                            
                                        Text((request.urgency ?? "Normal").capitalized)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor((request.urgency ?? "") == "high" ? .red : theme.secondaryText)
                                    }
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text((request.status ?? "Pending").capitalized)
                                        .font(.system(size: 12, weight: .bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background((request.status ?? "pending") == "pending" ? Color.orange.opacity(0.2) : Color.green.opacity(0.2))
                                        .foregroundColor((request.status ?? "pending") == "pending" ? .orange : .green)
                                        .clipShape(Capsule())
                                    
                                    if let date = request.created_at {
                                        Text(date, style: .date)
                                            .font(.system(size: 10))
                                            .foregroundColor(theme.secondaryText)
                                    }
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
        }
        .task {
            await viewModel.fetchRequests(storeID: sessionStore.currentUser?.storeID)
        }
    }
}
