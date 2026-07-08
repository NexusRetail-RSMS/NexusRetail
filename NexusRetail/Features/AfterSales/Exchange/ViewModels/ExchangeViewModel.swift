//
//  ExchangeViewModel.swift
//  NexusRetail
//
//  ViewModel driving the Exchange flow: product selection, pricing
//  calculations, and exchange processing.
//

import SwiftUI
import Combine

@Observable
class ExchangeViewModel {
    // Original product being exchanged
    let originalProduct: POSProduct
    let originalQuantity: Int
    let invoiceId: String
    let purchaseDate: Date?
    let warrantyEndDate: Date?
    let customer: RequestCustomer?

    // Replacement selection (single product)
    var selectedReplacement: ExchangeReplacementItem? = nil

    // Search & filter
    var searchText: String = ""
    var selectedCategory: String? = nil

    // Store inventory
    var storeProducts: [POSProduct] = []
    var isLoading: Bool = false
    var isProcessing: Bool = false

    // Result
    var lastTransaction: ExchangeTransaction? = nil

    init(
        originalProduct: POSProduct,
        originalQuantity: Int = 1,
        invoiceId: String,
        purchaseDate: Date? = nil,
        warrantyEndDate: Date? = nil,
        customer: RequestCustomer? = nil
    ) {
        self.originalProduct = originalProduct
        self.originalQuantity = originalQuantity
        self.invoiceId = invoiceId
        self.purchaseDate = purchaseDate
        self.warrantyEndDate = warrantyEndDate
        self.customer = customer
    }

    // MARK: - Computed Properties

    var originalValue: Double {
        originalProduct.price * Double(originalQuantity)
    }

    var replacementTotal: Double {
        selectedReplacement?.product.price ?? 0
    }

    var difference: Double {
        replacementTotal - originalValue
    }

    var amountPayable: Double {
        max(0, difference)
    }

    var isExchangeValid: Bool {
        selectedReplacement != nil
    }

    var requiresPayment: Bool {
        difference > 0
    }

    var availableCategories: [String] {
        let cats = Set(storeProducts.map(\.category))
        return cats.sorted()
    }

    var filteredProducts: [POSProduct] {
        var results = storeProducts.filter { $0.id != originalProduct.id && $0.stock > 0 && $0.price >= originalProduct.price }

        if let category = selectedCategory {
            results = results.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            results = results.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.sku.localizedCaseInsensitiveContains(searchText) ||
                $0.category.localizedCaseInsensitiveContains(searchText)
            }
        }

        return results
    }

    // MARK: - Data Loading

    func loadProducts(storeID: UUID?) async {
        isLoading = true
        let fetched = await POSProductRepository.shared.fetchProducts(storeID: storeID)
        await MainActor.run {
            self.storeProducts = fetched
            self.isLoading = false
        }
    }

    // MARK: - Replacement Management

    func isProductSelected(_ product: POSProduct) -> Bool {
        selectedReplacement?.product.id == product.id
    }

    func toggleReplacement(_ product: POSProduct) {
        guard product.stock > 0 else { return }
        if let selected = selectedReplacement, selected.product.id == product.id {
            selectedReplacement = nil
        } else {
            selectedReplacement = ExchangeReplacementItem(product: product, quantity: 1)
        }
    }

    func removeReplacement() {
        selectedReplacement = nil
    }

    // MARK: - Exchange Processing

    func processExchange() async -> ExchangeTransaction? {
        guard let replacement = selectedReplacement else { return nil }
        isProcessing = true
        defer { isProcessing = false }

        do {
            let result = try await AfterSalesService.process(
                orderId: invoiceId,
                itemId: originalProduct.itemId,
                type: "exchange",
                issue: "Exchange — \(replacement.product.name)",
                partsCost: amountPayable
            )

            if result.success {
                let transaction = ExchangeTransaction(
                    transactionId: result.ticketId?.uuidString ?? "EXC-\(UUID().uuidString.prefix(8).uppercased())",
                    invoiceId: invoiceId,
                    originalProduct: originalProduct,
                    originalQuantity: originalQuantity,
                    replacementItem: replacement,
                    amountPaid: amountPayable,
                    date: Date()
                )
                lastTransaction = transaction
                return transaction
            } else {
                print("ExchangeViewModel: Exchange not allowed — \(result.message ?? "Unknown reason")")
                return nil
            }
        } catch {
            print("ExchangeViewModel: Exchange processing error — \(error)")
            return nil
        }
    }
}
