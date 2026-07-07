import SwiftUI

struct AfterSalesActionSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath
    
    let invoiceId: String
    let selectedItem: POSProduct

    @State private var eligibility: AfterSalesEligibility? = nil
    @State private var isLoading = true
    @State private var isProcessing = false
    @State private var resultTitle = ""
    @State private var resultMessage = ""
    @State private var showResult = false
    @State private var resultWasSuccess = false
    @State private var showExchangeConfirm = false
    
    var body: some View {
        ZStack(alignment: .top) {
            RSMSColors.background
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    productHeroSection
                    warrantyBanner
                    actionGridSection
                }
                .padding(.bottom, 60)
            }
            .ignoresSafeArea(edges: .top)
            
            customHeaderSection

            if isProcessing {
                Color.black.opacity(0.25).ignoresSafeArea()
                ProgressView().tint(.white)
            }
        }
        .navigationBarHidden(true)
        .task { await loadEligibility() }
        .alert(resultTitle, isPresented: $showResult) {
            Button("OK") {
                if resultWasSuccess { path = NavigationPath() }
            }
        } message: {
            Text(resultMessage)
        }
        .sheet(isPresented: $showExchangeConfirm) {
            exchangeConfirmSheet
                .presentationDetents([.height(440)])
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Exchange Confirmation Sheet
    private var exchangeConfirmSheet: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 10) {
                ZStack {
                    Circle().fill(RSMSColors.burgundy.opacity(0.1)).frame(width: 64, height: 64)
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(RSMSColors.burgundy)
                }
                Text("Confirm Exchange")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)
            }
            .padding(.top, 28)

            // Product summary
            HStack(spacing: 14) {
                CachedAsyncImage(url: URL(string: selectedItem.imageUrl ?? "")) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.1))
                }
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 4) {
                    Text(selectedItem.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(RSMSColors.primaryText)
                        .lineLimit(2)
                    Text(selectedItem.category)
                        .font(.system(size: 13))
                        .foregroundColor(RSMSColors.secondaryText)
                }
                Spacer()
            }
            .padding(16)
            .background(RSMSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(RSMSColors.cardBorder, lineWidth: 1))
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, 20)

            // Info row
            HStack(spacing: 10) {
                Image(systemName: "shippingbox.and.arrow.backward.fill")
                    .foregroundColor(RSMSColors.success)
                Text("The returned unit will be restocked into inventory.")
                    .font(.system(size: 13))
                    .foregroundColor(RSMSColors.secondaryText)
                Spacer()
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, 16)

            Spacer()

            // Actions
            VStack(spacing: 12) {
                Button {
                    Task {
                        showExchangeConfirm = false
                        await processExchange()
                    }
                } label: {
                    HStack {
                        if isProcessing { ProgressView().tint(.white).padding(.trailing, 6) }
                        Text("Process Exchange")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(RSMSColors.burgundy)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(isProcessing)

                Button("Cancel") { showExchangeConfirm = false }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.bottom, 28)
        }
        .background(RSMSColors.background.ignoresSafeArea())
    }

    // MARK: - Eligibility
    private func loadEligibility() async {
        isLoading = true
        do {
            eligibility = try await AfterSalesService.checkEligibility(orderId: invoiceId, itemId: selectedItem.itemId)
        } catch {
            print("Eligibility check failed: \(error)")
        }
        isLoading = false
    }

    private func processExchange() async {
        isProcessing = true
        defer { isProcessing = false }
        do {
            let result = try await AfterSalesService.process(
                orderId: invoiceId, itemId: selectedItem.itemId,
                type: "exchange", issue: "Exchange requested", partsCost: 0)
            if result.success {
                resultWasSuccess = true
                resultTitle = "Exchange Approved"
                resultMessage = "The exchange for \(selectedItem.name) has been recorded and the unit restocked."
            } else {
                resultWasSuccess = false
                resultTitle = "Exchange Not Allowed"
                resultMessage = result.message ?? "This item is no longer eligible for exchange."
            }
            showResult = true
        } catch {
            resultWasSuccess = false
            resultTitle = "Something went wrong"
            resultMessage = "Couldn't process the exchange. Please try again."
            showResult = true
        }
    }

    // MARK: - Warranty Banner
    @ViewBuilder
    private var warrantyBanner: some View {
        if isLoading {
            HStack { ProgressView().tint(RSMSColors.burgundy); Text("Checking warranty...").font(.system(size: 13)).foregroundColor(RSMSColors.secondaryText) }
                .padding(.top, 24)
        } else if let e = eligibility, e.found {
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: e.inWarranty ? "checkmark.seal.fill" : "xmark.seal.fill")
                        .foregroundColor(e.inWarranty ? RSMSColors.success : RSMSColors.error)
                    Text(e.inWarranty ? "In Warranty — repairs are free" : "Out of Warranty — repair will be chargeable")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(RSMSColors.primaryText)
                }
                Text(e.exchangeAllowed ? "Eligible for exchange (within 15 days)" : "Exchange window (15 days) has passed")
                    .font(.system(size: 12))
                    .foregroundColor(e.exchangeAllowed ? RSMSColors.success : RSMSColors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(RSMSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(RSMSColors.cardBorder, lineWidth: 1))
            .padding(.horizontal, RSMSSpacing.lg)
            .padding(.top, 24)
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
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(RSMSColors.primaryText)
                }
            }
            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .frame(maxWidth: .infinity, alignment: .leading)
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
        let exchangeEnabled = (eligibility?.exchangeAllowed ?? false) && !isLoading
        return HStack(spacing: 16) {
            actionTile(
                title: "Exchange",
                icon: "arrow.triangle.2.circlepath",
                color: RSMSColors.burgundy,
                enabled: exchangeEnabled
            ) {
                showExchangeConfirm = true
            }
            
            actionTile(
                title: "Repair",
                icon: "wrench.and.screwdriver.fill",
                color: Color(hex: "34495E"),
                enabled: !isLoading
            ) {
                path.append(POSFlowDestination.repairForm(invoiceId: invoiceId, selectedItem: selectedItem))
            }
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 24)
    }
    
    private func actionTile(title: String, icon: String, color: Color, enabled: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.06))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .regular))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(RSMSColors.primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(RSMSColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 4)
            .opacity(enabled ? 1.0 : 0.4)
        }
        .buttonStyle(CardPressStyle())
        .disabled(!enabled)
    }
}

// MARK: - Missing Button Style
struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
