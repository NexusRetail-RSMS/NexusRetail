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
    /// Full ISO-8601 created_at, used for reliable time sorting / the merged hub list.
    let createdAt: String
    var status: BOPISOrderStatus
    let items: [BOPISOrderItem]
    let itemCount: Int
    let totalAmount: Double
    var verificationCode: String?

    /// Parsed timestamp for sorting (falls back to distantPast if unparseable).
    var createdDate: Date {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: createdAt) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: createdAt) ?? .distantPast
    }
}
