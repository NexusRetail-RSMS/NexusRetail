//
//  RequestStockSheet.swift
//  NexusRetail
//
//  Sheet for requesting stock replenishment.
//  Accepts an InventoryItemRow and lets the manager set quantity.
//

import SwiftUI

struct RequestStockSheet: View {
    @Environment(AppTheme.self) private var theme
    @Environment(\.dismiss) private var dismiss
    let item: InventoryItemRow
    let storeID: UUID?
    /// Returns nil on success, or an error message on failure.
    let onSubmit: (Int64, Int) async -> String?

    @State private var quantity: Int = 10
    @State private var isSubmitting = false
    @State private var isSuccess = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: RSMSSpacing.xl) {
                        // Product info
                        AsyncImage(url: URL(string: item.imageUrl ?? "")) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            default:
                                ZStack {
                                    Color.gray.opacity(0.08)
                                    Image(systemName: "shippingbox")
                                        .foregroundColor(theme.secondaryText.opacity(0.4))
                                }
                            }
                        }
                        .frame(width: 370)
                        .frame(height: 260)
                        .cornerRadius(24)
                        .clipped()
                    HStack(spacing: 14) {

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.primaryText)
                            Text("\(item.skuCode) · \(item.category)")
                                .font(.system(size: 13))
                                .foregroundColor(theme.secondaryText)
                        }

                        Spacer()
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(24)

                    // Quantity
                    HStack(spacing: 16) {
                        HStack(spacing: 8) {
                            Text("Quantity")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(theme.secondaryText)

                        }

                        Spacer()
                        TextField("", value: $quantity, format: .number)
                            .keyboardType(.numberPad)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(theme.primaryText)
                            .multilineTextAlignment(.center)
                            .frame(width: 50)
                        Stepper(
                            "",
                            value: $quantity,
                            in: 1...999
                        )
                        .labelsHidden()
                        .tint(theme.burgundy)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(24)

                    // Submit button — reflects the real DB result, not a timer.
                    Button {
                        errorMessage = nil
                        isSubmitting = true
                        Task {
                            let error = await onSubmit(item.itemId, quantity)
                            await MainActor.run {
                                isSubmitting = false
                                if let error {
                                    errorMessage = error
                                } else {
                                    withAnimation { isSuccess = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        dismiss()
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            if isSuccess {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18, weight: .bold))
                                Text("Request Sent")
                                    .font(.system(size: 16, weight: .bold))
                            } else if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                                Text("Sending\u{2026}")
                                    .font(.system(size: 16, weight: .bold))
                            } else {
                                Text("Submit Request")
                                    .font(.system(size: 16, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isSuccess ? Color.green : theme.burgundy)
                        .foregroundColor(.white)
                        .cornerRadius(24)
                    }
                    .disabled(isSubmitting || isSuccess)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(RSMSSpacing.lg)
                }
            }
            .navigationTitle("Request Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .foregroundColor(theme.primaryText)
                    }
                }
            }
        }
    }
}
