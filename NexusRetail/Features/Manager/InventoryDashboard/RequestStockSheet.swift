//
//  RequestStockSheet.swift
//  NexusRetail
//

import SwiftUI

struct RequestStockSheet: View {
    @Environment(\.dismiss) private var dismiss
    let lowStockItems: [InventoryItem]
    let onSubmit: ([StockRequestPayload]) -> Void
    
    @State private var selectedItems: Set<UUID> = []
    @State private var quantities: [UUID: Int] = [:]
    @State private var urgencies: [UUID: StockRequestUrgency] = [:]
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSColors.background
                    .ignoresSafeArea()
                
                if lowStockItems.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(RSMSColors.success)
                        Text("No items are currently low on stock.")
                            .font(RSMSFonts.headline)
                            .foregroundColor(RSMSColors.primaryText)
                    }
                } else {
                    List {
                        Section(header: Text("Select items to request from Admin")
                            .font(RSMSFonts.caption)
                            .foregroundColor(RSMSColors.secondaryText)) {
                            ForEach(lowStockItems) { item in
                                VStack(alignment: .leading, spacing: 12) {
                                    Button {
                                        withAnimation {
                                            if selectedItems.contains(item.id) {
                                                selectedItems.remove(item.id)
                                                // Optional: clean up dicts
                                            } else {
                                                selectedItems.insert(item.id)
                                                if quantities[item.id] == nil {
                                                    quantities[item.id] = max(1, item.minimumRequired - item.currentStock)
                                                }
                                                if urgencies[item.id] == nil {
                                                    urgencies[item.id] = .medium
                                                }
                                            }
                                        }
                                    } label: {
                                        HStack {
                                            Image(systemName: selectedItems.contains(item.id) ? "checkmark.circle.fill" : "circle")
                                                .foregroundColor(selectedItems.contains(item.id) ? RSMSColors.burgundy : RSMSColors.secondaryText)
                                                .font(.system(size: 20))
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(item.name)
                                                    .font(RSMSFonts.headline)
                                                    .foregroundColor(RSMSColors.primaryText)
                                                Text(item.sku)
                                                    .font(RSMSFonts.caption)
                                                    .foregroundColor(RSMSColors.secondaryText)
                                            }
                                            
                                            Spacer()
                                            
                                            VStack(alignment: .trailing, spacing: 2) {
                                                Text("\(item.currentStock)")
                                                    .font(RSMSFonts.headline)
                                                    .foregroundColor(RSMSColors.error)
                                                    .fontWeight(.bold)
                                                Text("in stock")
                                                    .font(RSMSFonts.caption)
                                                    .foregroundColor(RSMSColors.error)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if selectedItems.contains(item.id) {
                                        Divider()
                                            .padding(.vertical, 4)
                                        
                                        HStack {
                                            Text("Required Qty:")
                                                .font(RSMSFonts.subheadline)
                                                .foregroundColor(RSMSColors.primaryText)
                                            Spacer()
                                            Stepper(value: Binding(
                                                get: { quantities[item.id, default: max(1, item.minimumRequired - item.currentStock)] },
                                                set: { quantities[item.id] = $0 }
                                            ), in: 1...1000) {
                                                Text("\(quantities[item.id, default: max(1, item.minimumRequired - item.currentStock)])")
                                                    .font(RSMSFonts.headline)
                                                    .foregroundColor(RSMSColors.burgundy)
                                            }
                                            .frame(maxWidth: 160)
                                        }
                                        
                                        HStack {
                                            Text("Urgency:")
                                                .font(RSMSFonts.subheadline)
                                                .foregroundColor(RSMSColors.primaryText)
                                            Spacer()
                                            Picker("", selection: Binding(
                                                get: { urgencies[item.id, default: .medium] },
                                                set: { urgencies[item.id] = $0 }
                                            )) {
                                                ForEach(StockRequestUrgency.allCases) { urgency in
                                                    Text(urgency.rawValue.capitalized).tag(urgency)
                                                }
                                            }
                                            .pickerStyle(.menu)
                                            .labelsHidden()
                                            .tint(RSMSColors.burgundy)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Request Stock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(RSMSColors.burgundy)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button(isSubmitting ? "Sending..." : "Send") {
                        submitRequest()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(selectedItems.isEmpty || isSubmitting ? RSMSColors.disabled : RSMSColors.burgundy)
                    .disabled(selectedItems.isEmpty || isSubmitting)
                }
            }
        }
    }
    
    private func submitRequest() {
        isSubmitting = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let requestedItems: [StockRequestPayload] = lowStockItems
                .filter { selectedItems.contains($0.id) }
                .map { item in
                    let qty = quantities[item.id] ?? max(1, item.minimumRequired - item.currentStock)
                    let urgency = urgencies[item.id] ?? .medium
                    return StockRequestPayload(item: item, quantity: qty, urgency: urgency)
                }
            
            onSubmit(requestedItems)
            isSubmitting = false
            dismiss()
        }
    }
}
