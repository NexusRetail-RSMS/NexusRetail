import SwiftUI
import Supabase

struct ExchangeSummaryView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(SessionStore.self) private var sessionStore
    @Binding var path: NavigationPath
    
    let originalProductId: UUID
    let replacementProductId: UUID
    let amount: Double
    
    @State private var email = ""
    @State private var phone = ""
    @State private var showShareToast = false
    @State private var isSaving = false
    
    @State private var storeName: String = "NexusRetail"
    @State private var exchangeId: String = "EX-\(Int.random(in: 100000...999999))"
    @State private var originalProduct: POSProduct? = nil
    @State private var replacementProduct: POSProduct? = nil
    
    @State private var generatedReceiptImage: UIImage? = nil
    @State private var showShareSheet = false
    
    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .center, spacing: 0) {
                    customHeaderSection
                    
                    VStack(spacing: 28) {
                        paperReceiptView.padding(.top, 10)
                        
                        // Digital Share
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Share Digital Receipt")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(theme.darkBrown)
                                .padding(.horizontal, 4)
                            
                            VStack(spacing: 12) {
                                TextField("Customer Email (optional)", text: $email)
                                    .keyboardType(.emailAddress)
                                    .textInputAutocapitalization(.never)
                                    .padding(12)
                                    .background(theme.background)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.cardBorder, lineWidth: 1))
                                
                                TextField("Customer Phone (optional)", text: $phone)
                                    .keyboardType(.phonePad)
                                    .padding(12)
                                    .background(theme.background)
                                    .cornerRadius(10)
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(theme.cardBorder, lineWidth: 1))
                                
                                Button { shareReceipt() } label: {
                                    HStack {
                                        Image(systemName: "square.and.arrow.up")
                                        Text("Share Receipt").fontWeight(.bold)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(theme.burgundy)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                                .disabled(email.isEmpty && phone.isEmpty)
                                .opacity(email.isEmpty && phone.isEmpty ? 0.6 : 1.0)
                            }
                            .padding(16)
                            .background(theme.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(theme.cardBorder, lineWidth: 1))
                        }
                        
                        // Complete Sale
                        Button { completeExchange() } label: {
                            HStack {
                                if isSaving {
                                    ProgressView().tint(.white).padding(.trailing, 8)
                                }
                                Text("Complete Exchange & Return")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(theme.burgundy)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: theme.burgundy.opacity(0.25), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                        .disabled(isSaving)
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.bottom, RSMSSpacing.xxl)
                }
            }
            .ignoresSafeArea(edges: .top)
            
            if showShareToast {
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill").foregroundColor(.white)
                        Text("Digital receipt shared successfully!")
                            .font(.system(size: 13, weight: .bold)).foregroundColor(.white)
                    }
                    .padding(.vertical, 12).padding(.horizontal, 24)
                    .background(theme.success)
                    .clipShape(Capsule())
                    .shadow(radius: 6)
                    .padding(.bottom, 36)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            originalProduct = POSProductRepository.shared.products.first { $0.id == originalProductId }
            replacementProduct = POSProductRepository.shared.products.first { $0.id == replacementProductId }
        }
        .task {
            // Fetch real store name from DB
            if let storeID = sessionStore.currentUser?.storeID {
                struct StoreRow: Decodable { let name: String }
                if let rows: [StoreRow] = try? await SupabaseManager.shared.client
                    .from("store")
                    .select("name")
                    .eq("id", value: storeID)
                    .execute()
                    .value,
                   let first = rows.first {
                    storeName = first.name
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = generatedReceiptImage {
                ShareSheet(items: [image])
            }
        }
    }
    
    // MARK: - Header
    private var customHeaderSection: some View {
        HStack {
            Spacer()
            VStack(spacing: 2) {
                Text("Exchange Complete")
                    .font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                Text(amount > 0 ? "Payment Authorized" : "No Payment Required")
                    .font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.8))
            }
            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.xxxl)
        .frame(maxWidth: .infinity)
        .background(LinearGradient(colors: [theme.burgundy, theme.darkBurgundy], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(HeaderCurve())
    }
    
    // MARK: - Paper Receipt
    private var paperReceiptView: some View {
        VStack(spacing: 16) {
            // Branding
            VStack(spacing: 4) {
                Text("NEXUS RETAIL")
                    .font(.system(size: 16, weight: .black)).foregroundColor(theme.primaryText).kerning(2.0)
                Text("Official Store Receipt")
                    .font(.system(size: 11, weight: .bold)).foregroundColor(theme.secondaryText)
                Text(storeName)
                    .font(.system(size: 12)).foregroundColor(theme.secondaryText)
            }
            .padding(.top, 10)
            
            dashedDivider
            
            // Order meta
            VStack(spacing: 6) {
                receiptMetaRow(label: "Exchange ID", value: exchangeId)
                receiptMetaRow(label: "Date",     value: Date.now.formatted(date: .abbreviated, time: .shortened))
                receiptMetaRow(label: "Cashier",  value: sessionStore.currentUser?.name ?? "Sales Associate")
            }
            
            dashedDivider
            
            // Line items
            VStack(spacing: 10) {
                if let original = originalProduct {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("RETURNED: \(original.name)")
                                .font(.system(size: 13, weight: .bold)).foregroundColor(theme.primaryText)
                            HStack(spacing: 8) {
                                Text("SKU: \(original.sku)")
                                    .font(.system(size: 11)).foregroundColor(theme.secondaryText)
                            }
                        }
                        Spacer()
                        Text("-\(formatIndianCurrency(original.price))")
                            .font(.system(size: 13, weight: .bold)).foregroundColor(theme.error)
                    }
                }
                
                if let replacement = replacementProduct {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("NEW: \(replacement.name)")
                                .font(.system(size: 13, weight: .bold)).foregroundColor(theme.primaryText)
                            HStack(spacing: 8) {
                                Text("SKU: \(replacement.sku)")
                                    .font(.system(size: 11)).foregroundColor(theme.secondaryText)
                            }
                        }
                        Spacer()
                        Text(formatIndianCurrency(replacement.price))
                            .font(.system(size: 13, weight: .bold)).foregroundColor(theme.primaryText)
                    }
                }
            }
            
            dashedDivider
            
            // Totals
            VStack(spacing: 8) {
                HStack {
                    Text("Amount Due / Paid").font(.system(size: 16, weight: .bold)).foregroundColor(theme.primaryText)
                    Spacer()
                    Text(formatIndianCurrency(amount)).font(.system(size: 18, weight: .black)).foregroundColor(theme.burgundy)
                }
            }
            .padding(.bottom, 10)
            
            // Footer
            VStack(spacing: 2) {
                Text("Thank you for shopping at Nexus Retail")
                    .font(.system(size: 10)).foregroundColor(theme.secondaryText)
                Text("For returns & exchanges visit any store within 30 days")
                    .font(.system(size: 9)).foregroundColor(theme.secondaryText.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    private var dashedDivider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.25))
            .frame(height: 1)
            .padding(.horizontal, 4)
    }
    
    private func receiptMetaRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.system(size: 12)).foregroundColor(theme.secondaryText)
            Spacer()
            Text(value).font(.system(size: 12, weight: .bold)).foregroundColor(theme.primaryText)
        }
    }
    
    // MARK: - Actions
    @MainActor
    private func shareReceipt() {
        let renderer = ImageRenderer(content: paperReceiptView.frame(width: 350))
        renderer.scale = UIScreen.main.scale
        if let image = renderer.uiImage {
            generatedReceiptImage = image
            showShareSheet = true
        } else {
            withAnimation { showShareToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation { self.showShareToast = false }
            }
        }
    }
    
    private func completeExchange() {
        isSaving = true
        Task {
            // DB logic would go here
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                isSaving = false
                path = NavigationPath()
            }
        }
    }
}
