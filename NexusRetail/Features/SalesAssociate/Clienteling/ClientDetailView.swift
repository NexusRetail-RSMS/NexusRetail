//
//  ClientDetailView.swift
//  NexusRetail
//
//  Detail page for a single clienteling record.
//

import SwiftUI
import Supabase

struct ClientDetailView: View {
    @Environment(AppTheme.self) private var theme
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

    // Dynamic client insights (computed from real order history)
    @State private var dynamicPreferences: String?
    @State private var dynamicPurchasePattern: String?
    
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
        ZStack(alignment: .top) {
            theme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                ZStack(alignment: .top) {
                    // Top Curvy Background - Now inside ScrollView so it scrolls up
                    TopWaveShape()
                        .fill(theme.burgundy.opacity(0.85))
                        .frame(height: 260)
                    
                    VStack(spacing: 0) {
                        // Spacer to align avatar over the curve edge
                        Spacer().frame(height: 140)
                        
                        // Avatar
                        Circle()
                            .fill(LinearGradient(colors: [theme.gold, theme.gold.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Circle().stroke(Color.white, lineWidth: 6)
                            )
                            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
                            .overlay {
                                Text(client.initials)
                                    .font(.system(size: 46, weight: .bold, design: .rounded))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 2)
                            }
                            .padding(.bottom, 16)
                        
                        // Profile Info
                        Text(client.name)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.primaryText)
                            .padding(.bottom, 4)
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "envelope.fill")
                                    .font(.system(size: 13))
                                Text(client.email.isEmpty ? "No Email" : client.email)
                                    .font(.system(size: 14))
                            }
                            
                            Text("|")
                                .foregroundStyle(Color.gray.opacity(0.5))
                            
                            HStack(spacing: 4) {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 13))
                                Text(client.phone.isEmpty ? "No Phone" : client.phone)
                                    .font(.system(size: 14))
                            }
                        }
                        .foregroundStyle(theme.secondaryText)
                        .padding(.bottom, 24)
                        
                        // Style Preferences & Purchase Pattern Card
                        HStack(alignment: .top, spacing: 20) {
                            VStack(spacing: 8) {
                                Text(dynamicPreferences ?? "Analyzing shopping history...")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(theme.burgundy)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                                
                                Text("Style Preferences")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(theme.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Divider()
                            
                            VStack(spacing: 8) {
                                Text(dynamicPurchasePattern ?? "Loading pattern...")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(theme.burgundy)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(3)
                                
                                Text("Purchase Pattern")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(theme.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(20)
                        .background(theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(theme.burgundy.opacity(0.6), lineWidth: 1.5)
                        )
                        .shadow(color: theme.burgundy.opacity(0.15), radius: 12, x: 0, y: 6)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 32)
                        
                        // Custom Tabs
                        HStack(spacing: 32) {
                            customTab(title: "For You", index: 0)
                            customTab(title: "Trending", index: 1)
                            Spacer()
                        }
                        .padding(.horizontal, 24)
                        
                        Divider()
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                        
                        // Recommendations Grid
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        } else {
                            if selectedTab == 0 {
                                recommendationsGrid(forYouProducts)
                                    .padding(.horizontal, 24)
                            } else {
                                recommendationsGrid(trendingProducts)
                                    .padding(.horizontal, 24)
                            }
                        }
                        
                        Spacer().frame(height: 60)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    startEditing()
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
            }
        }
        .sheet(isPresented: $isNewClientPresented) { newClientSheet }
        .task {
            await loadClientInsights()
            await loadRecommendations()
        }
    }

    // MARK: - Dynamic Insights

    private func loadClientInsights() async {
        guard let dbId = client.dbId else {
            dynamicPreferences = client.preferences
            dynamicPurchasePattern = client.purchasePattern
            return
        }

        do {
            struct ClientOrderLine: Decodable {
                let quantity: Int
                let products: InsightProduct?
            }
            struct InsightProduct: Decodable {
                let category: String?
                let attributes: String?
            }
            struct ClientOrder: Decodable {
                let total: Double
                let order_line_item: [ClientOrderLine]
            }

            let orders: [ClientOrder] = try await SupabaseManager.shared.client
                .from("orders")
                .select("total, order_line_item(quantity, products(category, attributes))")
                .eq("client_id", value: dbId.uuidString)
                .execute()
                .value

            if orders.isEmpty {
                dynamicPreferences = "No purchases yet. \(client.preferences)"
                dynamicPurchasePattern = "New client. Pattern will appear after assisted selling history is available."
                return
            }

            let totalSpend = orders.reduce(0) { $0 + $1.total }
            let avgSpend = totalSpend / Double(orders.count)
            let formattedAvg = String(format: "₹%.0f", avgSpend)

            dynamicPurchasePattern = "Frequent buyer (\(orders.count) orders) averaging \(formattedAvg) per visit."

            var categoryCounts: [String: Int] = [:]
            for order in orders {
                for line in order.order_line_item {
                    if let cat = line.products?.category {
                        categoryCounts[cat, default: 0] += line.quantity
                    }
                }
            }

            let topCategories = categoryCounts.sorted { $0.value > $1.value }.prefix(2).map { $0.key }
            if !topCategories.isEmpty {
                let catString = topCategories.joined(separator: " and ")
                dynamicPreferences = "Prefers \(catString)"
            } else {
                dynamicPreferences = "Exploring various categories."
            }

        } catch {
            print("Failed to fetch client insights: \(error)")
            dynamicPreferences = client.preferences
            dynamicPurchasePattern = client.purchasePattern
        }
    }

    private func startEditing() {
        clientName = client.name
        clientPhone = client.phone
        stylePreferences = client.preferences
        hasConsent = true
        isEditingClient = true
        isNewClientPresented = true
    }
    
    private func customTab(title: String, index: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: selectedTab == index ? .bold : .medium))
                    .foregroundStyle(selectedTab == index ? theme.burgundy : theme.secondaryText)
                
                Rectangle()
                    .fill(selectedTab == index ? theme.burgundy : Color.clear)
                    .frame(height: 3)
                    .cornerRadius(1.5)
            }
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
                        .tint(theme.burgundy)
                } footer: {
                    Text("Required before saving personal details.")
                }
            }
            .navigationTitle("Edit Client")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { isNewClientPresented = false }
                        .foregroundColor(theme.burgundy)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { saveClientCard() }
                        .bold()
                        .foregroundColor(canCreateClient ? theme.burgundy : .gray)
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
    @Environment(AppTheme.self) private var theme
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
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(theme.gold.opacity(0.3), lineWidth: 0.5)
                )
                .shadow(color: theme.gold.opacity(0.1), radius: 8, x: 0, y: 4)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.primaryText)
                    .lineLimit(2)
                
                Text(formatIndianCurrency(product.price))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(theme.burgundy)
            }
            .padding(.horizontal, 4)
        }
    }
}

fileprivate struct TopWaveShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        
        // Right side going down
        path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.7))
        
        // Curving across to the left
        path.addCurve(
            to: CGPoint(x: 0, y: rect.height * 0.9),
            control1: CGPoint(x: rect.width * 0.75, y: rect.height + 40),
            control2: CGPoint(x: rect.width * 0.25, y: rect.height * 0.6)
        )
        
        // Left side going up
        path.addLine(to: CGPoint(x: 0, y: 0))
        
        path.closeSubpath()
        return path
    }
}
