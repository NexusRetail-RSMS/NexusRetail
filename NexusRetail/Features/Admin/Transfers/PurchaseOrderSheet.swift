import SwiftUI

struct PurchaseOrderSheet: View {
    let product: AdminTransferProduct
    let suggestedQuantity: Int
    let initialRequest: AdminStockRequest? // Optional: if this PO was triggered by a denial/restock request
    
    @Environment(\.dismiss) private var dismiss
    @Environment(AdminTransfersViewModel.self) private var viewModel
    
    @State private var quantityText: String
    @State private var notes: String = ""
    
    init(product: AdminTransferProduct, suggestedQuantity: Int, initialRequest: AdminStockRequest?) {
        self.product = product
        self.suggestedQuantity = suggestedQuantity
        self.initialRequest = initialRequest
        _quantityText = State(initialValue: "\(suggestedQuantity)")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Product Details")) {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(product.name).foregroundColor(.secondary)
                    }
                    HStack {
                        Text("SKU")
                        Spacer()
                        Text(product.sku).foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Current Stock")
                        Spacer()
                        Text("\(product.warehouseQuantity)").foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Order Details")) {
                    
                    HStack {
                        Text("Quantity")
                        Spacer()
                        TextField("Qty", text: $quantityText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("Additional Info")) {
                    TextField("Notes (Optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                    
                    HStack {
                        Text("Est. Delivery")
                        Spacer()
                        Text(Calendar.current.date(byAdding: .day, value: 3, to: Date())?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                }
                
                if let initialReq = initialRequest {
                    Section(footer: Text("This will update the related transfer request status to 'Awaiting Restock'.")) {
                        HStack {
                            Text("Linked Request")
                            Spacer()
                            Text(initialReq.id.uuidString).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Create Purchase Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Place Order") {
                        placeOrder()
                    }
                    .fontWeight(.bold)
                    .disabled(Int(quantityText) == nil || Int(quantityText)! <= 0)
                }
            }
        }
    }
    
    private func placeOrder() {
        guard let qty = Int(quantityText), qty > 0 else { return }
        
        withAnimation {
            viewModel.createPurchaseOrder(for: product, quantity: qty, supplier: "Internal Warehouse", notes: notes)
        }
        
        dismiss()
    }
}
