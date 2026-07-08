//
//  ExchangeModels.swift
//  NexusRetail
//
//  Models for the Exchange flow: replacement items, pricing summary,
//  and completed transaction records.
//

import Foundation

/// A replacement product selected during an exchange, with its chosen quantity.
struct ExchangeReplacementItem: Identifiable, Hashable {
    let id: UUID
    let product: POSProduct
    var quantity: Int

    var lineTotal: Double { product.price * Double(quantity) }

    init(product: POSProduct, quantity: Int = 1) {
        self.id = product.id
        self.product = product
        self.quantity = quantity
    }
}

/// Computed pricing breakdown for the exchange.
struct ExchangePricingSummary {
    let originalProduct: POSProduct
    let originalQuantity: Int
    let replacementItems: [ExchangeReplacementItem]

    var originalValue: Double { originalProduct.price * Double(originalQuantity) }

    var replacementTotal: Double {
        replacementItems.reduce(0) { $0 + $1.lineTotal }
    }

    var difference: Double { replacementTotal - originalValue }

    var amountPayable: Double { max(0, difference) }

    var isValid: Bool { replacementTotal >= originalValue && !replacementItems.isEmpty }

    var requiresPayment: Bool { difference > 0 }

    var shortfall: Double { max(0, originalValue - replacementTotal) }
}

/// The completed exchange transaction record.
struct ExchangeTransaction: Hashable {
    let transactionId: String
    let invoiceId: String
    let originalProduct: POSProduct
    let originalQuantity: Int
    let replacementItem: ExchangeReplacementItem
    let amountPaid: Double
    let date: Date

    var replacementTotal: Double {
        replacementItem.lineTotal
    }
}
