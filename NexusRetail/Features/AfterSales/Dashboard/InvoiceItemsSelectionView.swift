import SwiftUI

struct InvoiceItemsSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath
    let invoiceId: String
    
    // Mocked data for demonstration
    @State private var items: [POSProduct] = [
        POSProduct(id: UUID(), itemId: 1, name: "Signature Leather Tote", sku: "TOTE-001", category: "Bags", price: 14500, stock: 10, size: "One Size", imageUrl: "https://images.unsplash.com/photo-1584916201218-f4242ceb4809?w=500&auto=format&fit=crop&q=60"),
        POSProduct(id: UUID(), itemId: 2, name: "Classic Silk Scarf", sku: "SCRF-045", category: "Accessories", price: 4200, stock: 25, size: "M", imageUrl: "https://images.unsplash.com/photo-1601924994987-69e26d50dc26?w=500&auto=format&fit=crop&q=60"),
        POSProduct(id: UUID(), itemId: 3, name: "Aviator Sunglasses", sku: "SUN-892", category: "Eyewear", price: 8900, stock: 5, size: "Standard", imageUrl: "https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=500&auto=format&fit=crop&q=60")
    ]
    
    @State private var selectedItemIds: Set<UUID> = []
    @State private var purchaseDate: Date = Date()
    @State private var salesAssociateName: String = "Jane Doe"
    @State private var storeName: String = "Nexus Retail — MG Road"
    // isExpired is derived from the mock but passed forward for action screen to use
    var isExpired: Bool {
        let days = Calendar.current.dateComponents([.day], from: purchaseDate, to: Date()).day ?? 0
        return days > 7
    }
    
    private var daysSincePurchase: Int {
        Calendar.current.dateComponents([.day], from: purchaseDate, to: Date()).day ?? 0
    }
    
    private var daysRemaining: Int {
        max(0, 7 - daysSincePurchase)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            RSMSColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                customHeaderSection
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Always-visible invoice info banner in burgundy
                        invoiceInfoBanner
                            .padding(.horizontal, RSMSSpacing.lg)
                            .padding(.top, RSMSSpacing.md)
                        
                        Text("Select items to process")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(RSMSColors.secondaryText)
                            .padding(.horizontal, RSMSSpacing.lg)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(items) { item in
                                itemRow(item)
                            }
                        }
                        .padding(.horizontal, RSMSSpacing.lg)
                        
                        Spacer(minLength: 120)
                    }
                }
            }
            
            bottomActionBar
        }
        .navigationBarHidden(true)
        .onAppear {
            setupMockInvoice()
        }
    }
    
    // MARK: - Invoice Info Banner (always burgundy)
    private var invoiceInfoBanner: some View {
        VStack(spacing: 0) {
            // Top header strip — always burgundy
            HStack {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Bill Information")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(daysSincePurchase) day\(daysSincePurchase == 1 ? "" : "s") ago")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(RSMSColors.burgundy)
            
            // Details grid
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    invoiceDetailCell(icon: "doc.text.fill", label: "Invoice ID", value: invoiceId, isLeft: true)
                    Divider().frame(width: 1)
                    invoiceDetailCell(icon: "calendar", label: "Purchase Date", value: purchaseDate.formatted(date: .abbreviated, time: .omitted), isLeft: false)
                }
                
                Divider()
                
                HStack(spacing: 0) {
                    invoiceDetailCell(icon: "person.fill", label: "Sales Associate", value: salesAssociateName, isLeft: true)
                    Divider().frame(width: 1)
                    invoiceDetailCell(icon: "storefront.fill", label: "Store", value: storeName, isLeft: false)
                }
            }
            .background(Color.white)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSColors.burgundy.opacity(0.3), lineWidth: 1.5))
        .shadow(color: RSMSColors.burgundy.opacity(0.12), radius: 10, x: 0, y: 4)
    }
    
    private func invoiceDetailCell(icon: String, label: String, value: String, isLeft: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(RSMSColors.secondaryText)
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(RSMSColors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Mock Data Setup
    private func setupMockInvoice() {
        if invoiceId.lowercased().contains("old") || invoiceId.lowercased().contains("expired") {
            purchaseDate = Calendar.current.date(byAdding: .day, value: -12, to: Date()) ?? Date()
        } else {
            purchaseDate = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        }
    }
    
    // MARK: - Header
    private var customHeaderSection: some View {
        HStack(alignment: .center, spacing: RSMSSpacing.md) {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(RSMSColors.burgundy.opacity(0.1))
                        .frame(width: 44, height: 44)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Invoice Items")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)
                
                Text(invoiceId)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.md)
        .background(.regularMaterial)
    }
    
    // MARK: - Item Row
    private func itemRow(_ item: POSProduct) -> some View {
        let isSelected = selectedItemIds.contains(item.id)
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isSelected {
                    selectedItemIds.remove(item.id)
                } else {
                    selectedItemIds.insert(item.id)
                }
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? RSMSColors.burgundy : RSMSColors.secondaryText.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(RSMSColors.burgundy)
                            .frame(width: 14, height: 14)
                    }
                }
                
                AsyncImage(url: URL(string: item.imageUrl ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.gray.opacity(0.1)
                            .overlay(Image(systemName: "shippingbox").foregroundColor(.gray))
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(RSMSColors.primaryText)
                        .lineLimit(1)
                    
                    Text("\(item.category) • Size: \(item.size)")
                        .font(.system(size: 12))
                        .foregroundColor(RSMSColors.secondaryText)
                    
                    Text(formatIndianCurrency(item.price))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(RSMSColors.burgundy)
                }
                
                Spacer()
            }
            .padding(16)
            .background(RSMSColors.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? RSMSColors.burgundy : RSMSColors.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: Color.black.opacity(isSelected ? 0.08 : 0.02), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        VStack {
            Button {
                path.append(POSFlowDestination.actionSelection(invoiceId: invoiceId, selectedItemIds: selectedItemIds))
            } label: {
                HStack {
                    Text("Continue")
                        .font(.system(size: 18, weight: .bold))
                    Spacer()
                    Text("\(selectedItemIds.count) Selected")
                        .font(.system(size: 14, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Capsule())
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(selectedItemIds.isEmpty ? RSMSColors.secondaryText.opacity(0.5) : RSMSColors.burgundy)
                .cornerRadius(16)
            }
            .disabled(selectedItemIds.isEmpty)
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.vertical, RSMSSpacing.lg)
        .background(
            Color.white
                .shadow(color: Color.black.opacity(0.05), radius: 10, y: -5)
        )
    }
}
