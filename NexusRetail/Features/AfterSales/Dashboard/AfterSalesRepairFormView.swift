import SwiftUI

struct AfterSalesRepairFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SellViewModel.self) private var viewModel
    @Environment(SessionStore.self) private var sessionStore
    @Binding var path: NavigationPath
    
    let invoiceId: String
    let selectedItem: POSProduct
    let isUnderWarranty: Bool
    
    @State private var problemDescription: String = ""
    @State private var additionalAmountText: String = ""
    @State private var isProcessing: Bool = false
    
    @FocusState private var isInputFocused: Bool
    
    private let baseServiceCost: Double = 500.0
    private var actualServiceCost: Double {
        isUnderWarranty ? 0.0 : baseServiceCost
    }
    
    private var totalAmount: Double {
        let additional = Double(additionalAmountText) ?? 0.0
        return actualServiceCost + additional
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            RSMSColors.background
                .ignoresSafeArea()
                .onTapGesture {
                    isInputFocused = false
                }
            
            VStack(spacing: 0) {
                customHeaderSection
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        productSummaryCard
                        
                        formSection
                    }
                    .padding(.vertical, RSMSSpacing.lg)
                }
                .onTapGesture {
                    isInputFocused = false
                }
                
                bottomActionBar
            }
            
            if isProcessing {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .controlSize(.large)
                            .tint(.white)
                        
                        Text("Processing Request...")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    private var customHeaderSection: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                }
            }
            
            Spacer()
            
            Text("Repair Request")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(RSMSColors.primaryText)
            
            Spacer()
            
            // Dummy view for alignment
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.bottom, RSMSSpacing.sm)
        .background(RSMSColors.background)
    }
    
    // MARK: - Product Summary
    private var productSummaryCard: some View {
        HStack(spacing: 16) {
            CachedAsyncImage(url: URL(string: selectedItem.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 70, height: 70)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(selectedItem.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(RSMSColors.primaryText)
                    .lineLimit(2)
                
                Text(selectedItem.sku)
                    .font(.system(size: 13))
                    .foregroundColor(RSMSColors.secondaryText)
                
                if isUnderWarranty {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                        Text("Under Warranty (6 Months)")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.green)
                    .padding(.top, 4)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(RSMSColors.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 4)
        .padding(.horizontal, RSMSSpacing.lg)
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Description Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Problem Description")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(RSMSColors.secondaryText)
                
                TextEditor(text: $problemDescription)
                    .focused($isInputFocused)
                    .frame(height: 120)
                    .padding(12)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(RSMSColors.inputBorder, lineWidth: 1)
                    )
            }
            
            Divider()
                .background(RSMSColors.divider)
            
            // Cost Details
            VStack(alignment: .leading, spacing: 16) {
                Text("Cost Breakdown")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(RSMSColors.primaryText)
                
                HStack {
                    Text("Base Service Cost")
                        .font(.system(size: 15))
                        .foregroundColor(RSMSColors.secondaryText)
                    Spacer()
                    if isUnderWarranty {
                        Text(String(format: "₹%.0f", baseServiceCost))
                            .font(.system(size: 15, weight: .medium))
                            .strikethrough()
                            .foregroundColor(RSMSColors.secondaryText.opacity(0.5))
                            .padding(.trailing, 4)
                    }
                    
                    Text(String(format: "₹%.0f", actualServiceCost))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(isUnderWarranty ? .green : RSMSColors.primaryText)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Additional Parts (₹)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(RSMSColors.secondaryText)
                    
                    TextField("Enter amount", text: $additionalAmountText)
                        .focused($isInputFocused)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(RSMSColors.inputBorder, lineWidth: 1)
                        )
                }
            }
            
            Divider()
                .background(RSMSColors.divider)
            
            // Total
            HStack {
                Text("Total Amount")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)
                
                Spacer()
                
                Text(String(format: "₹%.0f", totalAmount))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(RSMSColors.burgundy)
            }
        }
        .padding(.horizontal, RSMSSpacing.lg)
    }
    
    // MARK: - Bottom Action
    private var bottomActionBar: some View {
        VStack {
            Button {
                isInputFocused = false
                
                let repairProduct = POSProduct(
                    id: UUID(),
                    itemId: selectedItem.itemId,
                    name: "Repair: \(selectedItem.name)",
                    sku: selectedItem.sku,
                    category: "Service",
                    price: totalAmount,
                    stock: 999,
                    size: selectedItem.size,
                    imageUrl: selectedItem.imageUrl
                )
                
                viewModel.resetFlow()
                viewModel.cartItems.append(repairProduct)
                
                if totalAmount == 0 {
                    isProcessing = true
                    Task {
                        do {
                            // Automatically process the checkout without payment gateway
                            try await viewModel.processCheckout(storeID: sessionStore.currentUser?.storeID, associateID: sessionStore.currentUser?.id)
                            await POSProductRepository.shared.refreshStockForStore(storeID: sessionStore.currentUser?.storeID)
                            await viewModel.fetchRecentOrders(storeID: sessionStore.currentUser?.storeID, associateID: sessionStore.currentUser?.id)
                            
                            await MainActor.run {
                                isProcessing = false
                                path.append(POSFlowDestination.receipt)
                            }
                        } catch {
                            print("Checkout failed: \(error)")
                            await MainActor.run { isProcessing = false }
                        }
                    }
                } else {
                    viewModel.selectedPaymentMethod = .razorpay
                    path.append(POSFlowDestination.payment)
                }
                
            } label: {
                Text("Submit Repair Request")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(problemDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? RSMSColors.secondaryText.opacity(0.5) : RSMSColors.burgundy)
                    .cornerRadius(12)
            }
            .disabled(problemDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.vertical, 24)
    }
}
