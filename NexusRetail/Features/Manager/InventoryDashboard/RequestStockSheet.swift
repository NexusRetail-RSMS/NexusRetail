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
    let onSubmit: (UUID, Int) -> Void

    @State private var quantity: Int = 10
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSColors.background
                    .ignoresSafeArea()

                VStack(spacing: RSMSSpacing.xl) {
                    // Product info
                    HStack(spacing: 14) {
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
                        .frame(width: 56, height: 56)
                        .cornerRadius(10)
                        .clipped()

                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(RSMSColors.primaryText)
                            Text("\(item.skuCode) · \(item.category)")
                                .font(.system(size: 13))
                                .foregroundColor(RSMSColors.secondaryText)

                            HStack(spacing: 6) {
                                Text("\(item.onHand) in stock")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(item.stockStatus.color)
                                Text("· Min: \(item.reorderThreshold)")
                                    .font(.system(size: 13))
                                    .foregroundColor(RSMSColors.secondaryText)
                            }
                        }

                        Spacer()
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(RSMSRadius.medium)

                    // Quantity
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quantity to Request")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(RSMSColors.primaryText)

                        HStack(spacing: 16) {
                            Button {
                                if quantity > 1 { quantity -= 1 }
                            } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(RSMSColors.burgundy)
                                    .frame(width: 44, height: 44)
                                    .background(RSMSColors.burgundy.opacity(0.08))
                                    .cornerRadius(10)
                            }

                            Text("\(quantity)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(RSMSColors.primaryText)
                                .frame(minWidth: 60)
                                .multilineTextAlignment(.center)

                            Button {
                                if quantity < 999 { quantity += 1 }
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(RSMSColors.burgundy)
                                    .frame(width: 44, height: 44)
                                    .background(RSMSColors.burgundy.opacity(0.08))
                                    .cornerRadius(10)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .background(Color.white)
                        .cornerRadius(RSMSRadius.medium)
                    }

                    Spacer()

                    // Submit button
                    Button {
                        isSubmitting = true
                        onSubmit(item.skuId, quantity)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            isSubmitting = false
                            dismiss()
                        }
                    } label: {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isSubmitting ? "Sending\u{2026}" : "Submit Request")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RSMSColors.burgundy)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(isSubmitting)
                }
                .padding(RSMSSpacing.lg)
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
