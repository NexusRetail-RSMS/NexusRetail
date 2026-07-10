//
//  CollectVerifyView.swift
//  NexusRetail
//
//  Pickup verification: the associate enters the code the customer received by
//  email; on a correct code the order is marked collected. The code itself is
//  never shown to the associate.
//

import SwiftUI

struct CollectVerifyView: View {
    @Environment(AppTheme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    let order: BOPISOrder
    /// Verifies the entered code server-side; returns true if it matched.
    let onVerify: (String) async -> Bool
    /// Re-sends the pickup code to the customer; returns a user-facing message.
    var onResend: (() async -> String)? = nil

    @State private var code = ""
    @State private var isVerifying = false
    @State private var errorMessage: String?
    @State private var isResending = false
    @State private var resendMessage: String?

    private var canVerify: Bool {
        code.trimmingCharacters(in: .whitespaces).count >= 4 && !isVerifying
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                VStack(spacing: RSMSSpacing.xl) {
                    VStack(spacing: 8) {
                        ZStack {
                            Circle().fill(theme.burgundy.opacity(0.08)).frame(width: 72, height: 72)
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 30))
                                .foregroundColor(theme.burgundy)
                        }
                        Text("Verify Pickup")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(theme.primaryText)
                        Text("Ask \(order.customerName) for the code sent to their email, then enter it below.")
                            .font(.system(size: 14))
                            .foregroundColor(theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, RSMSSpacing.xl)

                    TextField("Enter code", text: $code)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .padding(.vertical, 16)
                        .background(theme.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.inputBorder, lineWidth: 1))
                        .padding(.horizontal, RSMSSpacing.lg)
                        .onChange(of: code) { _, _ in errorMessage = nil }

                    if let errorMessage {
                        Text(localized: errorMessage)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(theme.error)
                    }

                    Button {
                        verify()
                    } label: {
                        HStack {
                            if isVerifying { ProgressView().tint(.white) }
                            Text(isVerifying ? "Verifying…" : "Verify & Mark Collected")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canVerify ? theme.burgundy : theme.disabled)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canVerify)
                    .padding(.horizontal, RSMSSpacing.lg)

                    // Resend the pickup code to the customer (lost email, etc.)
                    if onResend != nil {
                        Button {
                            resend()
                        } label: {
                            HStack(spacing: 6) {
                                if isResending {
                                    ProgressView().tint(theme.burgundy)
                                } else {
                                    Image(systemName: "paperplane")
                                }
                                Text(isResending ? "Sending…" : "Resend code to customer")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(theme.burgundy)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(theme.burgundy.opacity(0.4), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .disabled(isResending)
                        .padding(.horizontal, RSMSSpacing.lg)
                    }

                    if let resendMessage {
                        Text(resendMessage)
                            .font(.system(size: 12))
                            .foregroundColor(theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, RSMSSpacing.lg)
                    }

                    Spacer()
                }
            }
            .navigationTitle("Confirm Pickup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(theme.burgundy)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func resend() {
        guard let onResend else { return }
        isResending = true
        resendMessage = nil
        Task {
            let message = await onResend()
            await MainActor.run {
                isResending = false
                resendMessage = message
            }
        }
    }

    private func verify() {
        let entered = code.trimmingCharacters(in: .whitespaces)
        isVerifying = true
        Task {
            let ok = await onVerify(entered)
            await MainActor.run {
                isVerifying = false
                if ok {
                    dismiss()
                } else {
                    errorMessage = "That code doesn't match. Please check and try again."
                }
            }
        }
    }
}
