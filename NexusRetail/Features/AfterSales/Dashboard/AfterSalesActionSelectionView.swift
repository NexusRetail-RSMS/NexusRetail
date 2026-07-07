import SwiftUI

struct AfterSalesActionSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath
    
    let invoiceId: String
    let selectedItem: POSProduct
    
    @State private var showExchangeDeclinedAlert = false
    
    // Mirrors the same mock logic from InvoiceItemsSelectionView
    private var isInvoiceExpired: Bool {
        invoiceId.lowercased().contains("old") || invoiceId.lowercased().contains("expired")
    }
    
    private var purchaseDate: Date {
        if isInvoiceExpired {
            return Calendar.current.date(byAdding: .day, value: -12, to: Date()) ?? Date()
        } else {
            return Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        }
    }
    
    private var daysSincePurchase: Int {
        Calendar.current.dateComponents([.day], from: purchaseDate, to: Date()).day ?? 0
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Premium background
            LinearGradient(
                colors: [RSMSColors.background, Color(white: 0.95)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Decorative background blur elements
            Circle()
                .fill(RSMSColors.burgundy.opacity(0.15))
                .frame(width: 300, height: 300)
                .blur(radius: 60)
                .position(x: 50, y: -50)
                .ignoresSafeArea()
                
            Circle()
                .fill(Color(hex: "34495E").opacity(0.1))
                .frame(width: 250, height: 250)
                .blur(radius: 50)
                .position(x: UIScreen.main.bounds.width - 50, y: 300)
            
VStack(spacing: 0) {
    customHeaderSection

    ScrollView(showsIndicators: false) {
        productHeroSection

        VStack(alignment: .leading, spacing: 32) {
            Text("Select Action")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(RSMSColors.secondaryText)
                .padding(.horizontal, RSMSSpacing.lg)

            VStack(spacing: 24) {
                actionCard(
                    title: "Exchange Product",
                    description: "Swap the selected items for a different size, color, or a completely new product.",
                    icon: "arrow.triangle.2.circlepath",
                    color: RSMSColors.burgundy
                ) {
                    if isInvoiceExpired {
                        showExchangeDeclinedAlert = true
                    } else {
                        path.append(POSFlowDestination.exchangeProduct(invoiceId: invoiceId, selectedItemIds: selectedItemIds))
                    }
                }

                actionCard(
                    title: "Repair Product",
                    description: "Send the selected items to our service center for expert repair and maintenance.",
                    icon: "wrench.and.screwdriver.fill",
                    color: Color(hex: "34495E") // Sophisticated slate
                ) {
                    print("Repair initiated for invoice \(invoiceId), items: \(selectedItemIds.count)")
                }
            }
            .padding(.horizontal, RSMSSpacing.lg)
        }
        .padding(.top, RSMSSpacing.lg)
    }

                }
                .padding(.bottom, 60)
            }
            .ignoresSafeArea(edges: .top)
            
            customHeaderSection
        }
        .navigationBarHidden(true)
        .alert("Exchange Not Possible", isPresented: $showExchangeDeclinedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This invoice was purchased \(daysSincePurchase) days ago. Exchanges are only allowed within 7 days of purchase. The exchange window for Invoice #\(invoiceId) has closed.")
        }
    }
    
    // MARK: - Header
    private var customHeaderSection: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
.frame(width: 48, height: 48)
.shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

Circle()
    .stroke(Color.white.opacity(0.5), lineWidth: 0.5)
    .frame(width: 48, height: 48)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(RSMSColors.primaryText)
                }
            }
.shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

VStack(alignment: .leading, spacing: 4) {
    Text("Process Items")
        .font(.system(size: 28, weight: .bold, design: .rounded))
        .foregroundColor(RSMSColors.primaryText)

    Text("\(selectedItemIds.count) item(s) selected")
        .font(.system(size: 15, weight: .medium))
        .foregroundColor(RSMSColors.secondaryText)
}


            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
.padding(.bottom, RSMSSpacing.md)
.background(.ultraThinMaterial)
.shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Product Hero
    private var productHeroSection: some View {
        VStack(spacing: 0) {
            GeometryReader { geo in
                let width = geo.size.width
                CachedAsyncImage(url: URL(string: selectedItem.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: width, height: width * 1.1)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: width, height: width * 1.1)
                        .overlay(ProgressView())
                }
            }
            .frame(height: UIScreen.main.bounds.width * 1.1)
            
            // Product info
            VStack(alignment: .center, spacing: 8) {
                Text(selectedItem.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(String(format: "₹%.0f", selectedItem.price))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(RSMSColors.secondaryText)
                
                Text("\(selectedItem.category) • Size: \(selectedItem.size)")
                    .font(.system(size: 14))
                    .foregroundColor(RSMSColors.secondaryText.opacity(0.8))
            }
            .padding(.top, 32)
            .padding(.horizontal, RSMSSpacing.lg)
        }
    }
    
    // MARK: - Action Grid
    private var actionGridSection: some View {
        HStack(spacing: 16) {
            actionTile(
                title: "Exchange",
                icon: "arrow.triangle.2.circlepath",
                color: RSMSColors.burgundy
            ) {
                print("Exchange initiated for invoice \(invoiceId), item: \(selectedItem.id)")
                // Future navigation to exchange flow
            }
            
            actionTile(
                title: "Repair",
                icon: "wrench.and.screwdriver.fill",
                color: Color(hex: "34495E")
            ) {
                path.append(POSFlowDestination.repairForm(invoiceId: invoiceId, selectedItem: selectedItem))
            }
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 40)
    }
    
    private func actionTile(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(RSMSColors.primaryText)
                    
                    Text(description)
                        .font(.system(size: 14))
                        .foregroundColor(RSMSColors.secondaryText)
                        .lineSpacing(4)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer(minLength: 0)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(RSMSColors.secondaryText.opacity(0.3))
            }
            .padding(24)
            .background(.white)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
            )
            .shadow(color: color.opacity(0.08), radius: 15, x: 0, y: 8)
            .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Button style for press animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)

    }
}
