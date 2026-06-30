//
//  BOPISViewModel.swift
//  NexusRetail
//

import Foundation
import SwiftUI

@Observable
class BOPISViewModel {
    var orders: [BOPISOrder] = []
    var searchText: String = ""
    var selectedFilter: BOPISOrderStatus? = nil // nil means "All"
    
    init() {
        loadMockData()
    }
    
    var filteredOrders: [BOPISOrder] {
        var result = orders
        
        // Exclude collected from default "All" view to keep it clean, unless explicitly searching?
        // Let's just filter strictly based on selectedFilter.
        if let filter = selectedFilter {
            result = result.filter { $0.status == filter }
        } else {
            // For "All" we might want to exclude collected to keep active queue clean, but let's follow standard "All" definition.
            // Requirement says "The order disappears from the active pickup list." when collected.
            // So we will hide Collected from "All" by default.
            result = result.filter { $0.status != .collected }
        }
        
        if !searchText.isEmpty {
            result = result.filter { order in
                order.customerName.localizedCaseInsensitiveContains(searchText) ||
                order.orderId.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    // MARK: - State Transitions
    
    func prepareOrder(id: UUID) {
        if let index = orders.firstIndex(where: { $0.id == id }) {
            orders[index].status = .readyForPickup
        }
    }
    
    func notifyCustomer(id: UUID) {
        if let index = orders.firstIndex(where: { $0.id == id }) {
            orders[index].status = .waitingForCustomer
        }
    }
    
    func markCollected(id: UUID) {
        if let index = orders.firstIndex(where: { $0.id == id }) {
            orders[index].status = .collected
        }
    }
    
    // MARK: - Mock Data
    private func loadMockData() {
        self.orders = [
            BOPISOrder(
                id: UUID(),
                orderId: "ORD-99321",
                customerName: "Eleanor Vance",
                phoneNumber: "+1 (555) 123-4567",
                pickupTime: "Today, 2:00 PM",
                status: .pendingPreparation,
                itemCount: 2,
                totalAmount: 1450.00,
                verificationCode: nil
            ),
            BOPISOrder(
                id: UUID(),
                orderId: "ORD-99344",
                customerName: "James Holden",
                phoneNumber: "+1 (555) 987-6543",
                pickupTime: "Today, 3:30 PM",
                status: .pendingPreparation,
                itemCount: 1,
                totalAmount: 320.00,
                verificationCode: nil
            ),
            BOPISOrder(
                id: UUID(),
                orderId: "ORD-99105",
                customerName: "Sarah Connor",
                phoneNumber: "+1 (555) 345-6789",
                pickupTime: "Today, 1:15 PM",
                status: .readyForPickup,
                itemCount: 4,
                totalAmount: 4890.00,
                verificationCode: nil
            ),
            BOPISOrder(
                id: UUID(),
                orderId: "ORD-98899",
                customerName: "Bruce Wayne",
                phoneNumber: "+1 (555) 222-3333",
                pickupTime: "Yesterday, 4:00 PM",
                status: .waitingForCustomer,
                itemCount: 1,
                totalAmount: 12500.00,
                verificationCode: "BW-7742"
            )
        ]
    }
}
