//
//  ProductDetailView.swift
//  NexusRetail
//
//  Full product detail screen for the Manager Inventory tab.
//  Shows product image, stock status, price editor, and restock button.
//

import SwiftUI
import AVFoundation
import Supabase

struct ProductDetailView: View {
    let item: InventoryItemRow
    @Bindable var viewModel: InventoryViewModel
    let storeID: UUID?
    
    @State private var localPriceText: String = ""
    @State private var isSavingPrice: Bool = false
    @State private var priceError: String? = nil
    @State private var priceSaved: Bool = false
    
    @State private var restockQty: Int = 10
    @State private var isRequestingRestock: Bool = false
    @State private var restockSuccess: Bool = false
    @State private var showSuccessAnimation: Bool = false
    @State private var ripple1 = false
    @State private var ripple2 = false
    @State private var restockError: String? = nil
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: RSMSSpacing.xl) {
                    // MARK: - Product Image
                    productImage
                    
                    // MARK: - Product Info
                    productInfoCard
                    
                    // MARK: - Stock Status
                    stockCard
                    
                    // MARK: - Price Editor
                    priceEditorCard
                    
                    // MARK: - Request Restock
                    restockCard
                    
                    // MARK: - Recent Activity Placeholder
                    recentActivityCard
                }
                .padding(RSMSSpacing.lg)
                .padding(.bottom, RSMSSpacing.xxxl)
            }
            
            // MARK: - Success Animation Overlay
            if showSuccessAnimation {
                ZStack {
                    RSMSColors.success
                        .ignoresSafeArea()
                    
                    Circle()
                        .stroke(Color.white.opacity(0.4), lineWidth: 4)
                        .frame(width: 100, height: 100)
                        .scaleEffect(ripple1 ? 4 : 0.5)
                        .opacity(ripple1 ? 0 : 1)
                    
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 100, height: 100)
                        .scaleEffect(ripple2 ? 6 : 0.5)
                        .opacity(ripple2 ? 0 : 1)
                    
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Text("Request Sent!")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                .zIndex(2)
                .onAppear {
                    AudioServicesPlaySystemSound(1322)
                    withAnimation(.easeOut(duration: 0.8)) {
                        ripple1 = true
                    }
                    withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                        ripple2 = true
                    }
                }
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(showSuccessAnimation ? .hidden : .visible, for: .navigationBar, .tabBar)
        .onAppear {
            localPriceText = String(format: "%.0f", item.localPrice)
        }
    }
    
    // MARK: - Product Image
    
    private var productImage: some View {
        AsyncImage(url: URL(string: item.imageUrl ?? "")) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            default:
                ZStack {
                    Color.gray.opacity(0.06)
                    Image(systemName: "photo")
                        .foregroundColor(RSMSColors.secondaryText.opacity(0.3))
                        .font(.system(size: 40))
                }
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .cornerRadius(RSMSRadius.large)
        .clipped()
    }
    
    // MARK: - Info Card
    
    private var productInfoCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(item.name)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(RSMSColors.primaryText)
            
            HStack(spacing: 12) {
                Label(item.skuCode, systemImage: "barcode")
                    .font(.system(size: 13))
                    .foregroundColor(RSMSColors.secondaryText)
                
                Text("·")
                    .foregroundColor(RSMSColors.secondaryText)
                
                Label(item.category, systemImage: "tag")
                    .font(.system(size: 13))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            
            // Status pill
            HStack {
                Image(systemName: item.stockStatus.icon)
                    .foregroundColor(item.stockStatus.color)
                Text(item.stockStatus.rawValue)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(item.stockStatus.color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(item.stockStatus.color.opacity(0.1))
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(RSMSRadius.medium)
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
    
    // MARK: - Stock Card
    
    private var stockCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stock Level")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(RSMSColors.primaryText)
            
            // Big number
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(item.onHand)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(item.stockStatus.color)
                Text("/ Min: \(item.reorderThreshold)")
                    .font(.system(size: 16))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            
            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.12))
                        .frame(height: 10)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(item.progressColor)
                        .frame(width: geo.size.width * item.stockProgress, height: 10)
                }
            }
            .frame(height: 10)
            
            // Value
            HStack {
                Text("Inventory Value")
                    .font(.system(size: 13))
                    .foregroundColor(RSMSColors.secondaryText)
                Spacer()
                Text(item.formattedValue)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(RSMSColors.primaryText)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(RSMSRadius.medium)
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
    
    // MARK: - Price Editor
    
    private var priceEditorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pricing")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(RSMSColors.primaryText)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Base Price")
                        .font(.system(size: 12))
                        .foregroundColor(RSMSColors.secondaryText)
                    Text(formatIndianCurrency(item.basePrice))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(RSMSColors.primaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Floor (Min Allowed)")
                        .font(.system(size: 12))
                        .foregroundColor(RSMSColors.secondaryText)
                    Text(formatIndianCurrency(item.floorPrice))
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(RSMSColors.warning)
                }
            }
            
            Divider()
            
            // Local price editor
            VStack(alignment: .leading, spacing: 6) {
                Text("Local Store Price")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(RSMSColors.primaryText)
                
                HStack {
                    Text("₹")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                    
                    TextField("Enter price", text: $localPriceText)
                        .keyboardType(.numberPad)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(RSMSColors.primaryText)
                    
                    Spacer()
                    
                    Button {
                        savePrice()
                    } label: {
                        HStack(spacing: 4) {
                            if isSavingPrice {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(.white)
                            }
                            Text(priceSaved ? "Saved ✓" : "Save")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(priceSaved ? RSMSColors.success : RSMSColors.burgundy)
                        .cornerRadius(8)
                    }
                    .disabled(isSavingPrice)
                }
                
                if let error = priceError {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(RSMSColors.error)
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(RSMSRadius.medium)
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
    
    // MARK: - Restock Card
    
    private var restockCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Request Restock")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(RSMSColors.primaryText)
            
            Stepper(value: $restockQty, in: 1...999) {
                Text("Quantity: \(restockQty) units")
                    .font(.system(size: 15))
                    .foregroundColor(RSMSColors.primaryText)
            }
            
            Button {
                submitRestock()
            } label: {
                HStack {
                    if isRequestingRestock {
                        ProgressView()
                            .tint(.white)
                    }
                    Text("Send Request")
                        .font(.system(size: 15, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RSMSColors.burgundy)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isRequestingRestock)
            
            if let error = restockError {
                Text(error)
                    .font(.system(size: 12))
                    .foregroundColor(RSMSColors.error)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(RSMSRadius.medium)
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
    
    // MARK: - Recent Activity
    
    private var recentActivityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(RSMSColors.primaryText)
            
            ForEach(0..<3, id: \.self) { i in
                HStack(spacing: 10) {
                    Circle()
                        .fill(RSMSColors.burgundy.opacity(0.15))
                        .frame(width: 8, height: 8)
                    
                    Text(["Stock updated to \(item.onHand) units", "Price adjusted", "Restock delivered"][i])
                        .font(.system(size: 13))
                        .foregroundColor(RSMSColors.secondaryText)
                    
                    Spacer()
                    
                    Text(["Today", "2d ago", "1w ago"][i])
                        .font(.system(size: 12))
                        .foregroundColor(RSMSColors.secondaryText.opacity(0.6))
                }
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(RSMSRadius.medium)
        .shadow(color: Color.black.opacity(0.04), radius: 6, y: 2)
    }
    
    // MARK: - Actions
    
    private func savePrice() {
        guard let price = Double(localPriceText) else {
            priceError = "Please enter a valid number."
            return
        }
        
        if price < item.floorPrice {
            priceError = "Price cannot be below floor: \(formatIndianCurrency(item.floorPrice))"
            return
        }
        
        priceError = nil
        isSavingPrice = true
        
        Task {
            var targetStoreID = storeID
            if targetStoreID == nil {
                do {
                    let stores: [Store] = try await SupabaseManager.shared.client.from("store").select().execute().value
                    targetStoreID = stores.first?.id
                } catch {
                    print("Error fetching fallback store: \(error)")
                    await MainActor.run {
                        priceError = "Error fetching store: \(error.localizedDescription)"
                        isSavingPrice = false
                    }
                    return
                }
            }
            
            guard let validStoreID = targetStoreID else {
                await MainActor.run {
                    priceError = "No store found in DB to attach to this request."
                    isSavingPrice = false
                }
                return
            }
            
            let success = await viewModel.saveLocalPrice(skuID: item.skuId, storeID: validStoreID, price: price)
            await MainActor.run {
                isSavingPrice = false
                priceSaved = success
                if !success {
                    priceError = "Failed to save. Try again."
                }
            }
        }
    }
    
    private func submitRestock() {
        isRequestingRestock = true
        
        Task {
            var targetStoreID = storeID
            if targetStoreID == nil {
                do {
                    let stores: [Store] = try await SupabaseManager.shared.client.from("store").select().execute().value
                    targetStoreID = stores.first?.id
                } catch {
                    print("Error fetching fallback store: \(error)")
                    await MainActor.run {
                        restockError = "Error fetching store: \(error.localizedDescription)"
                        isRequestingRestock = false
                    }
                    return
                }
            }
            
            guard let validStoreID = targetStoreID else {
                await MainActor.run {
                    restockError = "No store found in DB to attach to this request."
                    isRequestingRestock = false
                }
                return
            }
            
            let errorStr = await viewModel.requestRestock(skuID: item.skuId, quantity: restockQty, storeID: validStoreID)
            await MainActor.run {
                isRequestingRestock = false
                restockError = errorStr
                restockSuccess = (errorStr == nil)
                if restockSuccess {
                    triggerSuccessAnimation()
                }
            }
        }
    }
    
    private func triggerSuccessAnimation() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            showSuccessAnimation = true
        }
        
        // Hide after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSuccessAnimation = false
                ripple1 = false
                ripple2 = false
            }
        }
    }
}
