//
//  BOPISOrder.swift
//  NexusRetail
//

import Foundation

enum BOPISOrderStatus: String, CaseIterable, Identifiable {
    case pending = "Pending"
    case waitingForCustomer = "Waiting for Customer"
    case collected = "Collected"
    
    var id: String { self.rawValue }
}

struct BOPISOrder: Identifiable, Equatable {
    let id: UUID
    let orderId: String
    let customerName: String
    let phoneNumber: String
    let pickupTime: String
    var status: BOPISOrderStatus
    let items: [BOPISOrderItem]
    let itemCount: Int
    let totalAmount: Double
    var verificationCode: String?
}
