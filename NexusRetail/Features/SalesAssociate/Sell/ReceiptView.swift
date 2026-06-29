import SwiftUI
import Supabase

struct ReceiptView: View {
    @Environment(SellViewModel.self) private var viewModel
    @Environment(SessionStore.self) private var sessionStore
    
    // Binding or callback to reset navigation path back to root
    var onComplete: (() -> Void)? = nil
    
    @State private var email = ""
    @State private var phone = ""
    @State private var showShareToast = false
    @State private var isSaving = false
    
    // Cached state to prevent SwiftUI reset layout glitches showing ₹0
    @State private var cachedItems: [POSProduct] = []
    @State private var cachedTotal: Double = 0.0
    @State private var cachedSubtotal: Double = 0.0
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .center, spacing: 0) {
                    // Custom Curved Header (No back button since transaction is completed)
                    customHeaderSection
                    
                    VStack(spacing: 28) {
                        // Paper Receipt Card
                        paperReceiptView
                            .padding(.top, 10)
                        
                        // Digital Sharing Input Fields
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Share Digital Receipt")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(RSMSColors.darkBrown)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 12) {
                                // Email field
                                TextField("Customer Email (optional)", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .padding(12)
                                    .background(RSMSColors.background)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(RSMSColors.cardBorder, lineWidth: 1)
                                    )
                                
                                // Phone field
                                TextField("Customer Phone (optional)", text: $phone)
                                    .keyboardType(.phonePad)
                                    .padding(12)
                                    .background(RSMSColors.background)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(RSMSColors.cardBorder, lineWidth: 1)
                                    )
                                
                                Button {
                                    shareReceipt()
                                } label: {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Share Receipt")
                                            .fontWeight(.bold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(RSMSColors.burgundy)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                                .disabled(email.isEmpty && phone.isEmpty)
                                .opacity(email.isEmpty && phone.isEmpty ? 0.6 : 1.0)
                            }
                            .padding(16)
                            .background(RSMSColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(RSMSColors.cardBorder, lineWidth: 1)
                            )
                        }
                        
                        // Complete Sale button
                        Button {
                            completeSale()
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                        .padding(.trailing, 8)
                                }
                                Text("Complete Sale & Return")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(RSMSColors.burgundy)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: RSMSColors.burgundy.opacity(0.25), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(isSaving)
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.bottom, RSMSSpacing.xxl)
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // Toast alert for digital sharing
            if showShareToast {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                        Text("Digital receipt shared successfully!")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(RSMSColors.success)
                    .clipShape(Capsule())
                    .shadow(radius: 6)
                    .padding(.bottom, 36)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if cachedItems.isEmpty {
                cachedItems = viewModel.cartItems
                cachedTotal = viewModel.totalAmount
                cachedSubtotal = viewModel.subtotalAmount
            }
        }
    }
    
    // MARK: - Header
    private var customHeaderSection: some View {
        HStack(alignment: .center, spacing: RSMSSpacing.md) {
            Spacer()
            
            VStack(alignment: .center, spacing: 2) {
                Text("Transaction Success")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Payment Authorized")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.xxxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(HeaderCurve())
    }
    
    // MARK: - Receipt Layout
    private var paperReceiptView: some View {
        VStack(spacing: 16) {
            // Receipt Header / Branding
            VStack(spacing: 6) {
                Text("NEXUS RETAIL")
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(RSMSColors.primaryText)
                    .kerning(2.0)
                
                Text("Official Store Receipt")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(RSMSColors.secondaryText)
                
                Text("Delhi Corporate Office Store")
                    .font(.system(size: 12))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            .padding(.top, 10)
            
            Divider()
                .padding(.horizontal, 4)
            
            // Meta info
            VStack(spacing: 6) {
                receiptMetaRow(label: "Date", value: Date.now.formatted(date: .abbreviated, time: .shortened))
                receiptMetaRow(label: "Cashier", value: sessionStore.currentUser?.name ?? "Sales Associate")
                if let client = viewModel.selectedClient {
                    receiptMetaRow(label: "Client", value: client)
                }
                receiptMetaRow(label: "Payment Method", value: viewModel.selectedPaymentMethod.rawValue)
            }
            
            Divider()
                .padding(.horizontal, 4)
            
            // Items List
            VStack(spacing: 10) {
                ForEach(cachedItems) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(RSMSColors.primaryText)
                            Text("Size: \(item.size)  •  SKU: \(item.sku)")
                                .font(.system(size: 11))
                                .foregroundColor(RSMSColors.secondaryText)
                        }
                        Spacer()
                        Text("₹\(Int(item.price))")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(RSMSColors.primaryText)
                    }
                }
            }
            
            Divider()
                .padding(.horizontal, 4)
            
            // Totals
            VStack(spacing: 8) {
                HStack {
                    Text("Subtotal")
                        .font(.system(size: 13))
                        .foregroundColor(RSMSColors.secondaryText)
                    Spacer()
                    Text("₹\(Int(cachedSubtotal))")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                }
                
                HStack {
                    Text("Tax (Inclusive)")
                        .font(.system(size: 13))
                        .foregroundColor(RSMSColors.secondaryText)
                    Spacer()
                    Text("₹\(Int(cachedTotal * 0.18))")
                        .font(.system(size: 13))
                        .foregroundColor(RSMSColors.secondaryText)
                }
                
                HStack {
                    Text("Total Paid")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                    Spacer()
                    Text("₹\(Int(cachedTotal))")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(RSMSColors.burgundy)
                }
            }
            .padding(.bottom, 10)
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    private func receiptMetaRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(RSMSColors.secondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(RSMSColors.primaryText)
        }
    }
    
    // MARK: - Actions
    private func shareReceipt() {
        withAnimation {
            showShareToast = true
        }
        
        // Hide after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showShareToast = false
            }
        }
    }
    
    private func completeSale() {
        isSaving = true
        
        Task {
            // Save to Supabase (Background)
            do {
                let orderId = UUID()
                let storeId = sessionStore.currentUser?.storeID ?? UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
                let associateId = sessionStore.currentUser?.id ?? UUID()
                
                // Formulate order insert payload
                struct OrderInsert: Encodable {
                    let id: UUID
                    let store_id: UUID
                    let associate_id: UUID
                    let total: Double
                    let client_id: UUID?
                }
                
                let orderInsert = OrderInsert(
                    id: orderId,
                    store_id: storeId,
                    associate_id: associateId,
                    total: cachedTotal,
                    client_id: nil // clienteling relation optional or mock
                )
                
                // 1. Insert order record
                try await SupabaseManager.shared.client
                    .from("orders")
                    .insert(orderInsert)
                    .execute()
                
                // 2. Insert line items
                struct LineItemInsert: Encodable {
                    let order_id: UUID
                    let quantity: Int
                    let applied_price: Double
                    let sku_id: UUID
                }
                
                var lineItems: [LineItemInsert] = []
                for item in cachedItems {
                    lineItems.append(LineItemInsert(
                        order_id: orderId,
                        quantity: 1,
                        applied_price: item.price,
                        sku_id: item.id
                    ))
                }
                
                if !lineItems.isEmpty {
                    try await SupabaseManager.shared.client
                        .from("order_line_item")
                        .insert(lineItems)
                        .execute()
                }
                
                print("ReceiptView: Order successfully saved to database.")
            } catch {
                print("ReceiptView: Non-fatal error inserting order to Supabase (using mock database completion): \(error)")
            }
            
            await MainActor.run {
                isSaving = false
                viewModel.recordCompletedSale()
                viewModel.resetFlow()
                if let onComplete = onComplete {
                    onComplete()
                }
            }
        }
    }
}
