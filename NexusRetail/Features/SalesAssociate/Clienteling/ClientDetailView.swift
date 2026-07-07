//
//  ClientDetailView.swift
//  NexusRetail
//
//  Detail page for a single clienteling record.
//

import SwiftUI
import Supabase

struct ClientDetailView: View {
    let client: AssociateClient
    @Environment(SessionStore.self) private var sessionStore
    
    @State private var isEditingClient = false
    @State private var clientName = ""
    @State private var clientPhone = ""
    @State private var stylePreferences = ""
    @State private var hasConsent = true
    @State private var isNewClientPresented = false
    
    @State private var selectedTab = 0
    @State private var forYouProducts: [POSProduct] = []
    @State private var trendingProducts: [POSProduct] = []
    @State private var isLoading = true
    
    private struct TopProductsRPCParams: Encodable {
        let p_period: String
        let p_limit: Int
        let p_country: String?
    }
    
    private struct MinimalTopProduct: Decodable {
        let id: UUID
        let units: Int
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // Hero card with avatar, name, phone, email
                HStack(spacing: 16) {
                    Circle()
                        .fill(RSMSColors.burgundy)
                        .frame(width: 68, height: 68)
                        .overlay {
                            Text(client.initials)
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(client.name)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(RSMSColors.primaryText)
                        
                        Text(client.phone)
                            .font(RSMSFonts.body)
                            .foregroundStyle(RSMSColors.secondaryText)
                            
                        Text(client.email)
                            .font(RSMSFonts.body)
                            .foregroundStyle(RSMSColors.secondaryText)
                    }
                    Spacer()
                }
                .padding(20)
                .luxuryCard()

                // Unified Card for Style Preferences and Purchase Pattern
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(RSMSColors.burgundy)
                            .frame(width: 42, height: 42)
                            .background(RSMSColors.burgundy.opacity(0.08))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Client Preferences")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(RSMSColors.primaryText)
                            Text(client.preferences)
                                .font(RSMSFonts.subheadline)
                                .foregroundStyle(RSMSColors.secondaryText)
                            
                            Divider().padding(.vertical, 8)
                            
                            Text("Purchase Pattern")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(RSMSColors.primaryText)
                            Text(client.purchasePattern)
                                .font(RSMSFonts.subheadline)
                                .foregroundStyle(RSMSColors.secondaryText)
                        }
                    }
                }
                .padding(18)
                .luxuryCard()
                
                // ML Recommendations Tabs
                Picker("Recommendations", selection: $selectedTab) {
                    Text("For You").tag(0)
                    Text("Trending").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.top, 8)
                
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else {
                    if selectedTab == 0 {
                        recommendationsGrid(forYouProducts)
                    } else {
                        recommendationsGrid(trendingProducts)
                    }
                }
            }
            .screenPadding()
        }
        .background(RSMSColors.background.ignoresSafeArea())
        .navigationTitle("Client Card")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    clientName = client.name
                    clientPhone = client.phone
                    stylePreferences = client.preferences
                    hasConsent = true
                    isEditingClient = true
                    isNewClientPresented = true
                }
                .foregroundStyle(RSMSColors.burgundy)
                .bold()
            }
        }
        .sheet(isPresented: $isNewClientPresented) { newClientSheet }
        .task {
            await loadRecommendations()
        }
    }
    
    private func recommendationsGrid(_ products: [POSProduct]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 20) {
            ForEach(products) { product in
                ProductCardView(product: product)
            }
        }
    }
    
    private func loadRecommendations() async {
        isLoading = true
        defer { isLoading = false }
        
        let allProducts = await POSProductRepository.shared.fetchProducts(storeID: sessionStore.currentUser?.storeID)
        
        // --- 1. For You (ML Recommendations) ---
        RecommendationService.shared.buildProductMapping(from: allProducts)
        
        // Extract keywords from client's preferences
        let preferencesKeywords = client.preferences
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 }
            
        // Find products matching the preferences
        let matchingProducts = allProducts.filter { product in
            let searchString = "\(product.name) \(product.category)".lowercased()
            return preferencesKeywords.contains { keyword in
                searchString.contains(keyword)
            }
        }
        
        if !matchingProducts.isEmpty {
            forYouProducts = Array(matchingProducts.shuffled().prefix(6))
            if forYouProducts.count < 6, let seed = matchingProducts.randomElement() {
                let additionalRecs = RecommendationService.shared.getRecommendedProducts(
                    for: seed,
                    from: allProducts,
                    count: 6 - forYouProducts.count
                )
                for rec in additionalRecs {
                    if !forYouProducts.contains(where: { $0.id == rec.id }) {
                        forYouProducts.append(rec)
                    }
                }
            }
        } else {
            if let seed = allProducts.randomElement() {
                forYouProducts = RecommendationService.shared.getRecommendedProducts(for: seed, from: allProducts, count: 6)
            }
        }
        if forYouProducts.isEmpty {
            forYouProducts = Array(allProducts.shuffled().prefix(6))
        }
        
        // --- 2. Trending ---
        do {
            let topParams = TopProductsRPCParams(p_period: "month", p_limit: 6, p_country: nil)
            let topProductsResp: [MinimalTopProduct] = try await SupabaseManager.shared.client
                .rpc("top_products", params: topParams)
                .execute()
                .value
            
            trendingProducts = topProductsResp.compactMap { top in
                allProducts.first(where: { $0.id == top.id })
            }
            if trendingProducts.isEmpty {
                trendingProducts = Array(allProducts.prefix(6))
            }
        } catch {
            print("Error fetching top products for profile: \(error)")
            trendingProducts = Array(allProducts.shuffled().prefix(6))
        }
    }
    
    // MARK: - Edit Client Sheet
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
            .navigationTitle("Edit Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isNewClientPresented = false }
                        .foregroundColor(RSMSColors.burgundy)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveClientCard() }
                        .bold()
                        .foregroundColor(canCreateClient ? RSMSColors.burgundy : .gray)
                        .disabled(!canCreateClient)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private var canCreateClient: Bool {
        !clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !clientPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        hasConsent
    }

    private func saveClientCard() {
        let name = clientName.trimmingCharacters(in: .whitespacesAndNewlines)
        let phone = clientPhone.trimmingCharacters(in: .whitespacesAndNewlines)
        let editingId = client.dbId

        Task {
            do {
                if let editingId {
                    struct UpdateClient: Encodable {
                        let name: String
                        let phone: String
                    }
                    try await SupabaseManager.shared.client
                        .from("client")
                        .update(UpdateClient(name: name, phone: phone))
                        .eq("id", value: editingId)
                        .execute()
                }
            } catch {
                print("Error saving client: \(error)")
            }
        }
        isNewClientPresented = false
    }
}

fileprivate struct ProductCardView: View {
    let product: POSProduct
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Color.white
                .aspectRatio(0.8, contentMode: .fit)
                .overlay {
                    if let urlString = product.imageUrl, let url = URL(string: urlString) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                            case .success(let image):
                                image.resizable().scaledToFill()
                            case .failure:
                                Image(systemName: "photo").foregroundStyle(.secondary)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(RSMSColors.primaryText)
                    .lineLimit(2)
                
                Text(formatIndianCurrency(product.price))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(RSMSColors.burgundy)
            }
            .padding(.horizontal, 4)
        }
    }
}
