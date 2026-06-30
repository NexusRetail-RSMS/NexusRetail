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
            let order = orders[index]
            let initials = order.customerName.components(separatedBy: " ")
                .compactMap { $0.first }
                .map { String($0) }
                .joined()
                .uppercased()
            let randomCode = String(format: "%04d", Int.random(in: 1000...9999))
            orders[index].verificationCode = "\(initials)-\(randomCode)"
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
                status: .pending,
                items: [
                    BOPISOrderItem(id: UUID(), name: "Aurelia Croco Tote", sku: "BAG-AUR-204", quantity: 1, price: 2450.00, qrCode: "nexus://product/BAG-AUR-204"),
                    BOPISOrderItem(id: UUID(), name: "Classic Leather Watches", sku: "ACC-CLW-009", quantity: 1, price: 450.00, qrCode: "nexus://product/ACC-CLW-009")
                ],
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
                status: .pending,
                items: [
                    BOPISOrderItem(id: UUID(), name: "Véloute Silk Blouse", sku: "APP-VEL-031", quantity: 1, price: 890.00, qrCode: "nexus://product/APP-VEL-031")
                ],
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
                items: [
                    BOPISOrderItem(id: UUID(), name: "Nocturne Velvet Fragrances", sku: "BAG-NOC-055", quantity: 2, price: 640.00, qrCode: "nexus://product/BAG-NOC-055"),
                    BOPISOrderItem(id: UUID(), name: "Ivory Pearl Earrings", sku: "JWL-IPE-201", quantity: 2, price: 580.00, qrCode: "nexus://product/JWL-IPE-201")
                ],
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
                items: [
                    BOPISOrderItem(id: UUID(), name: "Obsidian Chronograph", sku: "WCH-OBS-099", quantity: 1, price: 24500.00, qrCode: "nexus://product/WCH-OBS-099")
                ],
                itemCount: 1,
                totalAmount: 12500.00,
                verificationCode: "BW-7742"
            )
        ]
    }
}
