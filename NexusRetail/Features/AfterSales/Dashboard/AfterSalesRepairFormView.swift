import SwiftUI

struct AfterSalesRepairFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath
    
    let invoiceId: String
    let selectedItem: POSProduct
    
    @State private var problemDescription: String = ""
    @State private var additionalAmountText: String = ""

    enum WarrantyCheckPhase { case checking, result, done }

    @State private var eligibility: AfterSalesEligibility? = nil
    @State private var isLoading = true
    @State private var checkPhase: WarrantyCheckPhase = .checking
    @State private var checkmarkScale: CGFloat = 0.4
    @State private var isProcessing = false
    @State private var resultTitle = ""
    @State private var resultMessage = ""
    @State private var showResult = false
    @State private var resultWasSuccess = false
    
    @FocusState private var isInputFocused: Bool
    
    private let serviceCost: Double = 500.0

    private var inWarranty: Bool { eligibility?.inWarranty ?? false }
    
    private var totalAmount: Double {
        if inWarranty { return 0 }
        let additional = Double(additionalAmountText) ?? 0.0
        return serviceCost + additional
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
        .task { await loadEligibility() }
        .alert(resultTitle, isPresented: $showResult) {
            Button("OK") {
                if resultWasSuccess { path = NavigationPath() }
            }
        } message: {
            Text(resultMessage)
        }
    }

    private func loadEligibility() async {
        isLoading = true
        checkPhase = .checking
        // Run the real check, but keep the "checking" animation up for a minimum duration
        // so it always feels intentional even when the network is instant.
        let start = Date()
        do {
            eligibility = try await AfterSalesService.checkEligibility(orderId: invoiceId, itemId: selectedItem.itemId)
        } catch {
            print("Repair eligibility check failed: \(error)")
        }
        let elapsed = Date().timeIntervalSince(start)
        if elapsed < 1.4 {
            try? await Task.sleep(nanoseconds: UInt64((1.4 - elapsed) * 1_000_000_000))
        }
        isLoading = false

        // Reveal the result with a spring-in checkmark, hold, then show the form.
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            checkPhase = .result
            checkmarkScale = 1.0
        }
        try? await Task.sleep(nanoseconds: 1_600_000_000)
        withAnimation(.easeInOut(duration: 0.4)) {
            checkPhase = .done
        }
    }

    // MARK: - Warranty Check Overlay
    private var warrantyCheckOverlay: some View {
        let inW = eligibility?.inWarranty ?? false
        let months = eligibility?.warrantyMonths
        return ZStack {
            RSMSColors.background.ignoresSafeArea()

            VStack(spacing: 24) {
                if checkPhase == .checking {
                    ZStack {
                        Circle()
                            .stroke(RSMSColors.burgundy.opacity(0.15), lineWidth: 6)
                            .frame(width: 96, height: 96)
                        ProgressView()
                            .controlSize(.large)
                            .tint(RSMSColors.burgundy)
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 30))
                            .foregroundColor(RSMSColors.burgundy)
                    }
                    Text("Checking warranty…")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(RSMSColors.primaryText)
                    Text("Verifying \(selectedItem.name)")
                        .font(.system(size: 14))
                        .foregroundColor(RSMSColors.secondaryText)
                } else {
                    ZStack {
                        Circle()
                            .fill((inW ? RSMSColors.success : RSMSColors.warning).opacity(0.12))
                            .frame(width: 110, height: 110)
                        Image(systemName: inW ? "checkmark.seal.fill" : "exclamationmark.shield.fill")
                            .font(.system(size: 54))
                            .foregroundColor(inW ? RSMSColors.success : RSMSColors.warning)
                            .scaleEffect(checkmarkScale)
                    }

                    VStack(spacing: 8) {
                        Text(inW ? "In Warranty" : "Out of Warranty")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(RSMSColors.primaryText)

                        if inW {
                            Text("This product is covered\nRepair cost: FREE")
                                .font(.system(size: 15))
                                .foregroundColor(RSMSColors.success)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Warranty has expired\nRepair will be chargeable")
                                .font(.system(size: 15))
                                .foregroundColor(RSMSColors.secondaryText)
                                .multilineTextAlignment(.center)
                        }

                        if let months, inW {
                            Text("\(selectedItem.category) • \(months)-month warranty")
                                .font(.system(size: 12))
                                .foregroundColor(RSMSColors.secondaryText)
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

                if isLoading {
                    HStack { ProgressView().tint(RSMSColors.burgundy); Text("Checking warranty...").font(.system(size: 13)).foregroundColor(RSMSColors.secondaryText) }
                } else if inWarranty {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill").foregroundColor(RSMSColors.success)
                        Text("Covered under warranty — no charge")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(RSMSColors.success)
                        Spacer()
                    }
                    .padding(12)
                    .background(RSMSColors.success.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    HStack {
                        Text("Base Service Cost")
                            .font(.system(size: 15))
                            .foregroundColor(RSMSColors.secondaryText)
                        Spacer()
                        Text(String(format: "₹%.0f", serviceCost))
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(RSMSColors.primaryText)
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
            }
            
            Divider()
                .background(RSMSColors.divider)
            
            // Total
            HStack {
                Text("Total Amount")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(RSMSColors.primaryText)
                
                Spacer()
                
                Text(inWarranty ? "FREE" : String(format: "₹%.0f", totalAmount))
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
                Task { await submitRepair() }
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
