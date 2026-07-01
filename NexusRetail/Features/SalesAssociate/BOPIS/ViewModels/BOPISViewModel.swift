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
    
    func packAndNotify(id: UUID) {
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
    
    // MARK: - Mock Data initialized with real DB items
    func loadData(storeID: UUID?) async {
        let products = await POSProductRepository.shared.fetchProducts(storeID: storeID)
        
        let p1 = products.indices.contains(0) ? products[0] : nil
        let p2 = products.indices.contains(1) ? products[1] : nil
        let p3 = products.indices.contains(2) ? products[2] : nil
        let p4 = products.indices.contains(3) ? products[3] : nil
        
        let order1Items = [
            BOPISOrderItem(id: UUID(), name: p1?.name ?? "Aurelia Croco Tote", sku: p1?.sku ?? "BAG-AUR-204", quantity: 1, price: p1?.price ?? 2450.00, qrCode: "nexus://product/\(p1?.sku ?? "BAG-AUR-204")", imageUrl: p1?.imageUrl),
            BOPISOrderItem(id: UUID(), name: p2?.name ?? "Classic Leather Watches", sku: p2?.sku ?? "ACC-CLW-009", quantity: 1, price: p2?.price ?? 450.00, qrCode: "nexus://product/\(p2?.sku ?? "ACC-CLW-009")", imageUrl: p2?.imageUrl)
        ]
        
        let order2Items = [
            BOPISOrderItem(id: UUID(), name: p3?.name ?? "Véloute Silk Blouse", sku: p3?.sku ?? "APP-VEL-031", quantity: 1, price: p3?.price ?? 890.00, qrCode: "nexus://product/\(p3?.sku ?? "APP-VEL-031")", imageUrl: p3?.imageUrl)
        ]
        
        let order3Items = [
            BOPISOrderItem(id: UUID(), name: p4?.name ?? "Nocturne Velvet Fragrances", sku: p4?.sku ?? "BAG-NOC-055", quantity: 2, price: p4?.price ?? 640.00, qrCode: "nexus://product/\(p4?.sku ?? "BAG-NOC-055")", imageUrl: p4?.imageUrl),
            BOPISOrderItem(id: UUID(), name: p1?.name ?? "Ivory Pearl Earrings", sku: p1?.sku ?? "JWL-IPE-201", quantity: 2, price: p1?.price ?? 580.00, qrCode: "nexus://product/\(p1?.sku ?? "JWL-IPE-201")", imageUrl: p1?.imageUrl)
        ]
        
        let order4Items = [
            BOPISOrderItem(id: UUID(), name: p2?.name ?? "Obsidian Chronograph", sku: p2?.sku ?? "WCH-OBS-099", quantity: 1, price: p2?.price ?? 24500.00, qrCode: "nexus://product/\(p2?.sku ?? "WCH-OBS-099")", imageUrl: p2?.imageUrl)
        ]
        
        let fetchedOrders = [
            BOPISOrder(
                id: UUID(),
                orderId: "ORD-99321",
                customerName: "Eleanor Vance",
                phoneNumber: "+1 (555) 123-4567",
                pickupTime: "Today, 2:00 PM",
                status: .pending,
                items: order1Items,
                itemCount: 2,
                totalAmount: order1Items.reduce(0) { $0 + ($1.price * Double($1.quantity)) },
                verificationCode: nil
            ),
            BOPISOrder(
                id: UUID(),
                orderId: "ORD-99344",
                customerName: "James Holden",
                phoneNumber: "+1 (555) 987-6543",
                pickupTime: "Today, 3:30 PM",
                status: .pending,
                items: order2Items,
                itemCount: 1,
                totalAmount: order2Items.reduce(0) { $0 + ($1.price * Double($1.quantity)) },
                verificationCode: nil
            ),
            BOPISOrder(
                id: UUID(),
                orderId: "ORD-99105",
                customerName: "Sarah Connor",
                phoneNumber: "+1 (555) 345-6789",
                pickupTime: "Today, 1:15 PM",
                status: .waitingForCustomer,
                items: order3Items,
                itemCount: 4,
                totalAmount: order3Items.reduce(0) { $0 + ($1.price * Double($1.quantity)) },
                verificationCode: "SC-9281"
            ),
            BOPISOrder(
                id: UUID(),
                orderId: "ORD-98899",
                customerName: "Bruce Wayne",
                phoneNumber: "+1 (555) 222-3333",
                pickupTime: "Yesterday, 4:00 PM",
                status: .waitingForCustomer,
                items: order4Items,
                itemCount: 1,
                totalAmount: order4Items.reduce(0) { $0 + ($1.price * Double($1.quantity)) },
                verificationCode: "BW-7742"
            )
        ]
        
        await MainActor.run {
            self.orders = fetchedOrders
        }
    }
}
