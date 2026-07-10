import SwiftUI

struct AfterSalesRepairFormView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath
    
    let invoiceId: String
    let selectedItem: POSProduct
    /// Warranty end determined on the previous (action) screen — reused here so the
    /// two screens never disagree and we don't re-hit the network.
    var warrantyEndDate: Date? = nil
    
    @State private var problemDescription: String = ""
    @State private var additionalAmountText: String = ""

    enum WarrantyCheckPhase { case checking, result, done }

    @State private var checkPhase: WarrantyCheckPhase = .checking
    @State private var checkmarkScale: CGFloat = 0.4
    @State private var isProcessing = false
    @State private var resultTitle = ""
    @State private var resultMessage = ""
    @State private var showResult = false
    @State private var resultWasSuccess = false
    
    @FocusState private var isInputFocused: Bool
    
    private let serviceCost: Double = 500.0

    /// Uses the warranty date passed from the action page (single source of truth).
    private var inWarranty: Bool {
        guard let warrantyEndDate else { return false }
        return Date() <= warrantyEndDate
    }
    
    private var totalAmount: Double {
        if inWarranty { return 0 }
        let additional = Double(additionalAmountText) ?? 0.0
        return serviceCost + additional
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            theme.background
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
                Color.black.opacity(0.25).ignoresSafeArea()
                ProgressView().tint(.white)
            }

            // Warranty-check animation overlay (checking -> result -> reveal form)
            if checkPhase != .done {
                warrantyCheckOverlay
                    .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .task { await runWarrantyAnimation() }
        .alert(resultTitle, isPresented: $showResult) {
            Button("OK") {
                if resultWasSuccess { path = NavigationPath() }
            }
        } message: {
            Text(localized: resultMessage)
        }
    }

    /// No network call — warranty is already known from the action page. We just play
    /// the brief checking → result animation using that value.
    private func runWarrantyAnimation() async {
        checkPhase = .checking
        try? await Task.sleep(nanoseconds: 1_100_000_000)

        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            checkPhase = .result
            checkmarkScale = 1.0
        }
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        withAnimation(.easeInOut(duration: 0.4)) {
            checkPhase = .done
        }
    }

    // MARK: - Warranty Check Overlay
    private var warrantyCheckOverlay: some View {
        let inW = inWarranty
        return ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                if checkPhase == .checking {
                    ZStack {
                        Circle()
                            .stroke(theme.burgundy.opacity(0.15), lineWidth: 6)
                            .frame(width: 96, height: 96)
                        ProgressView()
                            .controlSize(.large)
                            .tint(theme.burgundy)
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 30))
                            .foregroundColor(theme.burgundy)
                    }
                    Text("Checking warranty…")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.primaryText)
                    Text("Verifying \(selectedItem.name)")
                        .font(.system(size: 14))
                        .foregroundColor(theme.secondaryText)
                } else {
                    ZStack {
                        Circle()
                            .fill((inW ? theme.success : theme.warning).opacity(0.12))
                            .frame(width: 110, height: 110)
                        Image(systemName: inW ? "checkmark.seal.fill" : "exclamationmark.shield.fill")
                            .font(.system(size: 54))
                            .foregroundColor(inW ? theme.success : theme.warning)
                            .scaleEffect(checkmarkScale)
                    }

                    VStack(spacing: 8) {
                        Text(inW ? "In Warranty" : "Out of Warranty")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(theme.primaryText)

                        if inW {
                            Text("This product is covered\nRepair cost: FREE")
                                .font(.system(size: 15))
                                .foregroundColor(theme.success)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Warranty has expired\nRepair will be chargeable")
                                .font(.system(size: 15))
                                .foregroundColor(theme.secondaryText)
                                .multilineTextAlignment(.center)
                        }

                        if inW, let end = warrantyEndDate {
                            Text("\(selectedItem.category) • covered until \(end.formatted(date: .abbreviated, time: .omitted))")
                                .font(.system(size: 12))
                                .foregroundColor(theme.secondaryText)
                                .padding(.top, 2)
                        }
                    }
                }
            }
            .padding(32)
        }
    }

    private func submitRepair() async {
        isProcessing = true
        defer { isProcessing = false }
        do {
            let result = try await AfterSalesService.process(
                orderId: invoiceId, itemId: selectedItem.itemId,
                type: "repair", issue: problemDescription, partsCost: totalAmount)
            if result.success {
                resultWasSuccess = true
                resultTitle = "Repair Logged"
                let cost = result.serviceCost ?? totalAmount
                resultMessage = cost <= 0
                    ? "Repair for \(selectedItem.name) has been logged free of charge under warranty."
                    : "Repair for \(selectedItem.name) has been logged. Amount to collect: \(String(format: "₹%.0f", cost))."
            } else {
                resultWasSuccess = false
                resultTitle = "Couldn't Log Repair"
                resultMessage = result.message ?? "Please try again."
            }
            showResult = true
        } catch {
            resultWasSuccess = false
            resultTitle = "Something went wrong"
            resultMessage = "Couldn't submit the repair request. Please try again."
            showResult = true
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
                        .fill(theme.cardBackground)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(theme.primaryText)
                }
            }
            
            Spacer()
            
            Text("Repair Request")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.primaryText)
            
            Spacer()
            
            // Dummy view for alignment
            Color.clear.frame(width: 44, height: 44)
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.bottom, RSMSSpacing.sm)
        .background(theme.background)
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
                    .foregroundColor(theme.primaryText)
                    .lineLimit(2)
                
                Text(selectedItem.sku)
                    .font(.system(size: 13))
                    .foregroundColor(theme.secondaryText)
            }
            Spacer()
        }
        .padding(16)
        .background(theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(theme.cardBorder, lineWidth: 1)
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
                    .foregroundColor(theme.secondaryText)
                
                TextEditor(text: $problemDescription)
                    .focused($isInputFocused)
                    .frame(height: 120)
                    .padding(12)
                    .background(theme.cardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(theme.inputBorder, lineWidth: 1)
                    )
            }
            
            Divider()
                .background(theme.divider)
            
            // Cost Details
            VStack(alignment: .leading, spacing: 16) {
                Text("Cost Breakdown")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.primaryText)

                if inWarranty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill").foregroundColor(theme.success)
                        Text("Covered under warranty — no charge")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.success)
                        Spacer()
                    }
                    .padding(12)
                    .background(theme.success.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    HStack {
                        Text("Base Service Cost")
                            .font(.system(size: 15))
                            .foregroundColor(theme.secondaryText)
                        Spacer()
                        Text(String(format: "₹%.0f", serviceCost))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(theme.primaryText)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Additional Parts (₹)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.secondaryText)

                        TextField("Enter amount", text: $additionalAmountText)
                            .focused($isInputFocused)
                            .keyboardType(.decimalPad)
                            .padding()
                            .background(theme.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(theme.inputBorder, lineWidth: 1)
                            )
                    }
                }
            }
            
            Divider()
                .background(theme.divider)
            
            // Total
            HStack {
                Text("Total Amount")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.primaryText)
                
                Spacer()
                
                Text(inWarranty ? "FREE" : String(format: "₹%.0f", totalAmount))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(theme.burgundy)
            }
        }
        .padding(.horizontal, RSMSSpacing.lg)
    }
    
    // MARK: - Bottom Action
    private var bottomActionBar: some View {
        VStack {
            Button {
                isInputFocused = false
                Task { await submitRepair() }
            } label: {
                Text("Submit Repair Request")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(problemDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? theme.secondaryText.opacity(0.5) : theme.burgundy)
                    .cornerRadius(12)
            }
            .disabled(problemDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.vertical, 24)
    }
}
