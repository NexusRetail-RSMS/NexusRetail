//
//  ExchangeWarrantyCheckView.swift
//  NexusRetail
//

import SwiftUI

struct ExchangeWarrantyCheckView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var path: NavigationPath

    let invoiceId: String
    let selectedItem: POSProduct
    let purchaseDate: Date?
    let warrantyEndDate: Date?
    let customer: RequestCustomer?

    enum WarrantyCheckPhase { case checking, result, done }

    @State private var checkPhase: WarrantyCheckPhase = .checking
    @State private var checkmarkScale: CGFloat = 0.4
    @State private var showFailureAlert = false

    /// Exchange is only allowed within 15 days of purchase.
    private var isExchangeAllowed: Bool {
        guard let purchaseDate else { return false }
        guard let deadline = Calendar.current.date(byAdding: .day, value: 15, to: purchaseDate) else { return false }
        return Date() <= deadline
    }

    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()

            // Warranty-check animation overlay (checking -> result -> navigate)
            if checkPhase != .done {
                warrantyCheckOverlay
                    .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .task { await runWarrantyAnimation() }
        .alert("Exchange Not Available", isPresented: $showFailureAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("The 15-day exchange window has passed for this item.")
        }
    }

    // MARK: - Warranty Animation

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

        // After animation, navigate or show error
        try? await Task.sleep(nanoseconds: 300_000_000)
        await MainActor.run {
            if isExchangeAllowed {
                path.removeLast()
                path.append(POSFlowDestination.exchangeSelection(
                    invoiceId: invoiceId,
                    selectedItem: selectedItem,
                    purchaseDate: purchaseDate,
                    warrantyEndDate: warrantyEndDate,
                    customer: customer
                ))
            } else {
                showFailureAlert = true
            }
        }
    }

    // MARK: - Warranty Check Overlay

    private var warrantyCheckOverlay: some View {
        let allowed = isExchangeAllowed
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
                    Text("Checking exchange eligibility…")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(RSMSColors.primaryText)
                    Text("Verifying \(selectedItem.name)")
                        .font(.system(size: 14))
                        .foregroundColor(RSMSColors.secondaryText)
                } else {
                    ZStack {
                        Circle()
                            .fill((allowed ? RSMSColors.success : RSMSColors.warning).opacity(0.12))
                            .frame(width: 110, height: 110)
                        Image(systemName: allowed ? "checkmark.seal.fill" : "exclamationmark.shield.fill")
                            .font(.system(size: 54))
                            .foregroundColor(allowed ? RSMSColors.success : RSMSColors.warning)
                            .scaleEffect(checkmarkScale)
                    }

                    VStack(spacing: 8) {
                        Text(allowed ? "Exchange Eligible" : "Exchange Not Available")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(RSMSColors.primaryText)

                        if allowed {
                            Text("This product qualifies for exchange")
                                .font(.system(size: 15))
                                .foregroundColor(RSMSColors.success)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Exchange window (15 days) has passed")
                                .font(.system(size: 15))
                                .foregroundColor(RSMSColors.secondaryText)
                                .multilineTextAlignment(.center)
                        }

                        if allowed, let end = warrantyEndDate {
                            Text("\(selectedItem.category) • covered until \(end.formatted(date: .abbreviated, time: .omitted))")
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
}
