//
//  ManagerLowStockView.swift
//  NexusRetail
//

import SwiftUI
import Supabase
import Combine
import Foundation

struct LowStockItemModel: Identifiable, Decodable {
    let id: UUID
    let on_hand: Int
    let reorder_threshold: Int
    let products: ProductInfo?
    
    struct ProductInfo: Decodable {
        let item_name: String?
        let sku_code: String?
        let image_url: String?
    }
}

@MainActor
class ManagerLowStockViewModel: ObservableObject {
    @Published var items: [LowStockItemModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func fetchLowStockItems(storeID: UUID?) async {
        guard let storeID = storeID else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response: [LowStockItemModel] = try await SupabaseManager.shared.client
                .from("inventory_item")
                .select("id, on_hand, reorder_threshold, products(item_name, sku_code, image_url)")
                .eq("store_id", value: storeID.uuidString)
                .lte("on_hand", value: 10)
                .order("on_hand", ascending: true)
                .execute()
                .value
            
            self.items = response.filter { $0.on_hand <= $0.reorder_threshold }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

struct ManagerLowStockView: View {
    @Environment(AppTheme.self) private var theme
    @StateObject private var viewModel = ManagerLowStockViewModel()
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
            } else if viewModel.items.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    Text("Stock Levels Healthy")
                        .font(.headline)
                    Text("No items are currently below their reorder threshold.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.items) { item in
                            HStack(spacing: 16) {
                                if let urlString = item.products?.image_url, let url = URL(string: urlString) {
                                    AsyncImage(url: url) { image in
                                        image.resizable().scaledToFill()
                                    } placeholder: {
                                        Color.gray.opacity(0.2)
                                    }
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 60, height: 60)
                                        .overlay(Image(systemName: "photo").foregroundColor(theme.secondaryText))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.products?.item_name ?? "Unknown Item")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(theme.primaryText)
                                        .lineLimit(1)
                                    
                                    Text("SKU: \(item.products?.sku_code ?? "N/A")")
                                        .font(.system(size: 12))
                                        .foregroundColor(theme.secondaryText)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("\(item.on_hand) Left")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.red)
                                    
                                    Text("Min: \(item.reorder_threshold)")
                                        .font(.system(size: 11))
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
            await viewModel.fetchLowStockItems(storeID: sessionStore.currentUser?.storeID)
        }
    }
}
