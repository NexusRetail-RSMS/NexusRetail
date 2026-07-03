//
//  RequestStockSheet.swift
//  NexusRetail
//
//  Sheet for requesting stock replenishment.
//  Accepts an InventoryItemRow and lets the manager set quantity.
//

import SwiftUI

struct RequestStockSheet: View {
    @Environment(\.dismiss) private var dismiss
    let item: InventoryItemRow
    let storeID: UUID?
    let onSubmit: (Int64, Int) -> Void

    @State private var quantity: Int = 10
    @State private var isSubmitting = false
    @State private var isSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSColors.background
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
                                        .foregroundColor(RSMSColors.secondaryText.opacity(0.4))
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
                                .foregroundColor(RSMSColors.primaryText)
                            Text("\(item.skuCode) · \(item.category)")
                                .font(.system(size: 13))
                                .foregroundColor(RSMSColors.secondaryText)
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
                                .foregroundColor(RSMSColors.secondaryText)

                        }

                        Spacer()
                        TextField("", value: $quantity, format: .number)
                            .keyboardType(.numberPad)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(RSMSColors.primaryText)
                            .multilineTextAlignment(.center)
                            .frame(width: 50)
                        Stepper(
                            "",
                            value: $quantity,
                            in: 1...999
                        )
                        .labelsHidden()
                        .tint(RSMSColors.burgundy)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(24)

                    // Submit button
                    Button {
                        isSubmitting = true
                        onSubmit(item.itemId, quantity)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation {
                                isSubmitting = false
                                isSuccess = true
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                dismiss()
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
                        .background(isSuccess ? Color.green : RSMSColors.burgundy)
                        .foregroundColor(.white)
                        .cornerRadius(24)
                    }
                    .disabled(isSubmitting || isSuccess)
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
                            .foregroundColor(RSMSColors.primaryText)
                    }
                }
            }
        }
    }
}
