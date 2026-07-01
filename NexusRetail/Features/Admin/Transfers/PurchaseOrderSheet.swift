import SwiftUI

struct PurchaseOrderSheet: View {
    let product: AdminTransferProduct
    let suggestedQuantity: Int
    let initialRequest: AdminStockRequest?

    @Environment(\.dismiss) private var dismiss
    @Environment(AdminTransfersViewModel.self) private var viewModel

    @State private var quantityText: String
    @State private var selectedSupplier: String = "Global Sports Inc"
    @State private var notes: String = ""
    @FocusState private var quantityFocused: Bool
    @FocusState private var notesFocused: Bool

    let mockSuppliers = ["Global Sports Inc", "Nike Distribution Co", "Sports Retail Wholesale", "FastTrack Logistics"]

    init(product: AdminTransferProduct, suggestedQuantity: Int, initialRequest: AdminStockRequest?) {
        self.product = product
        self.suggestedQuantity = suggestedQuantity
        self.initialRequest = initialRequest
        _quantityText = State(initialValue: "\(suggestedQuantity)")
    }

    private var estimatedDelivery: String {
        Calendar.current.date(byAdding: .day, value: 3, to: Date())?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown"
    }

    private var isValid: Bool {
        guard let qty = Int(quantityText) else { return false }
        return qty > 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.nexusBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        productSummaryCard

                        sectionCard(title: "Order Details", icon: "doc.text.fill") {
                            VStack(spacing: 16) {
                                supplierPicker

                                divider

                                quantityField
                            }
                        }

                        sectionCard(title: "Additional Info", icon: "note.text") {
                            VStack(alignment: .leading, spacing: 10) {
                                TextField("Add any notes for this order…", text: $notes, axis: .vertical)
                                    .lineLimit(3...6)
                                    .focused($notesFocused)
                                    .font(.system(size: 15))

                                divider

                                HStack {
                                    Label("Est. Delivery", systemImage: "calendar")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(estimatedDelivery)
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.primary)
                                }
                            }
                        }

                        if let initialReq = initialRequest {
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: "link.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(Color.nexusRed)

                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text("Linked Request")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(.primary)
                                        Spacer()
                                        Text(initialReq.id)
                                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                                            .foregroundColor(Color.nexusRed)
                                    }
                                    Text("Status will update to Awaiting Restock once this order is placed.")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.nexusRed.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.nexusRed.opacity(0.15), lineWidth: 1)
                            )
                        }

                        placeOrderButton
                            .padding(.top, 4)
                    }
                    .padding(20)
                    .padding(.bottom, 12)
                }
            }
            .navigationTitle("New Purchase Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.secondary)
                }
            }
            .onTapGesture {
                quantityFocused = false
                notesFocused = false
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.1))
            .frame(height: 1)
    }

    private var productSummaryCard: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [Color.nexusRed.opacity(0.16), Color.nexusRed.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color.nexusRed)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text(product.sku)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.secondary)

                HStack(spacing: 10) {
                    statPill(label: "In Stock", value: "\(product.warehouseQuantity)", color: product.stockHealth.color)
                    statPill(label: "Reorder", value: "\(product.reorderLevel)", color: .secondary)
                }
                .padding(.top, 2)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
    }

    private func statPill(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.08)))
    }

    private func sectionCard<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.nexusRed)
                Text(title.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .tracking(0.6)
                    .foregroundColor(.secondary)
            }

            content()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
    }

    private var supplierPicker: some View {
        Menu {
            ForEach(mockSuppliers, id: \.self) { supplier in
                Button {
                    selectedSupplier = supplier
                } label: {
                    if supplier == selectedSupplier {
                        Label(supplier, systemImage: "checkmark")
                    } else {
                        Text(supplier)
                    }
                }
            }
        } label: {
            HStack {
                Text("Supplier")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text(selectedSupplier)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var quantityField: some View {
        HStack {
            Text("Quantity")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: 14) {
                stepperButton(systemImage: "minus") {
                    let current = Int(quantityText) ?? 0
                    quantityText = "\(max(0, current - 1))"
                }

                TextField("0", text: $quantityText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .focused($quantityFocused)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .frame(minWidth: 44)

                stepperButton(systemImage: "plus") {
                    let current = Int(quantityText) ?? 0
                    quantityText = "\(current + 1)"
                }
            }
        }
    }

    private func stepperButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.nexusRed)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.nexusRed.opacity(0.1)))
        }
        .buttonStyle(.plain)
    }

    private var placeOrderButton: some View {
        Button {
            placeOrder()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                Text("Place Order")
            }
            .font(.system(size: 16, weight: .bold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: isValid ? [Color.nexusRed, Color.nexusRed.opacity(0.85)] : [Color.gray.opacity(0.4), Color.gray.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            .shadow(color: isValid ? Color.nexusRed.opacity(0.3) : .clear, radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!isValid)
        .animation(.easeInOut(duration: 0.2), value: isValid)
    }

    private func placeOrder() {
        guard let qty = Int(quantityText), qty > 0 else { return }

        withAnimation {
            viewModel.createPurchaseOrder(for: product, quantity: qty, supplier: selectedSupplier, notes: notes)
        }

        dismiss()
    }
}
