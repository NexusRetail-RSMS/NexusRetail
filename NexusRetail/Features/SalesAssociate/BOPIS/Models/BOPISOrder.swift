//
//  BOPISOrder.swift
//  NexusRetail
//

import Foundation

enum BOPISOrderStatus: String, CaseIterable, Identifiable {
    case pendingPreparation = "Pending Preparation"
    case readyForPickup = "Ready for Pickup"
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
    let itemCount: Int
    let totalAmount: Double
    let verificationCode: String?
}
