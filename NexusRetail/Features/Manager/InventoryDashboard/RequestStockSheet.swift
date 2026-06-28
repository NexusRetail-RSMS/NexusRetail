//
//  RequestStockSheet.swift
//  NexusRetail
//

import SwiftUI

struct RequestStockSheet: View {
    @Environment(\.dismiss) private var dismiss
    let lowStockItems: [InventoryItem]
    let onSubmit: ([InventoryItem]) -> Void
    
    @State private var selectedItems: Set<UUID> = []
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
                                Button {
                                    if selectedItems.contains(item.id) {
                                        selectedItems.remove(item.id)
                                    } else {
                                        selectedItems.insert(item.id)
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
                                        
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text("\(item.currentStock) in stock")
                                                .font(RSMSFonts.subheadline)
                                                .foregroundColor(RSMSColors.error)
                                                .fontWeight(.bold)
                                            Text("Min: \(item.minimumRequired)")
                                                .font(RSMSFonts.caption)
                                                .foregroundColor(RSMSColors.secondaryText)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                                .buttonStyle(.plain)
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
                    Button(isSubmitting ? "Sending..." : "Send Request") {
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
        
        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let requestedItems = lowStockItems.filter { selectedItems.contains($0.id) }
            onSubmit(requestedItems)
            isSubmitting = false
            dismiss()
        }
    }
}
