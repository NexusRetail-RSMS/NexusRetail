//
//  BOPISOrderItem.swift
//  NexusRetail
//

import Foundation

struct BOPISOrderItem: Identifiable, Equatable {
    let id: UUID
    let name: String
    let sku: String
    let quantity: Int
    let price: Double
    let qrCode: String
}
