//
//  AssociateClient.swift
//  NexusRetail
//
//  Model for a clienteling client record, plus static sample data.
//

import Foundation

struct AssociateClient: Identifiable {
    let id          = UUID()
    let name:       String
    let phone:      String
    let preferences: String
    let tier:       String
    let purchasePattern: String
    let recommendedNext: String

    var initials: String {
        name
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
            .uppercased()
    }
}

// MARK: - Sample Data

enum SalesAssociateSampleData {
    static let clients: [AssociateClient] = [
        AssociateClient(
            name: "Ananya Rao",
            phone: "+91 98765 43210",
            preferences: "Minimal gold, silk sarees",
            tier: "VIP",
            purchasePattern: "Buys festive wear every 5-6 weeks, prefers warm gold accents.",
            recommendedNext: "Kundan choker and ivory silk dupatta"
        ),
        AssociateClient(
            name: "Kabir Mehta",
            phone: "+91 98111 22009",
            preferences: "Tailored jackets, navy tones",
            tier: "Gold",
            purchasePattern: "Often buys structured workwear and premium accessories.",
            recommendedNext: "Navy linen blazer and leather card case"
        ),
        AssociateClient(
            name: "Mira Kapoor",
            phone: "+91 90000 77123",
            preferences: "Statement earrings, emerald",
            tier: "Silver",
            purchasePattern: "Responds well to limited-drop jewelry recommendations.",
            recommendedNext: "Emerald drop earrings and velvet evening clutch"
        )
    ]

    static let monthRevenue: [RevenuePoint] = [
        RevenuePoint(label: "Jul", value: 3),
        RevenuePoint(label: "Aug", value: 2),
        RevenuePoint(label: "Sep", value: 2),
        RevenuePoint(label: "Oct", value: 2),
        RevenuePoint(label: "Nov", value: 1),
        RevenuePoint(label: "Dec", value: 22),
        RevenuePoint(label: "Jan", value: 78),
        RevenuePoint(label: "Feb", value: 68),
        RevenuePoint(label: "Mar", value: 124),
        RevenuePoint(label: "Apr", value: 74),
        RevenuePoint(label: "May", value: 77),
        RevenuePoint(label: "Jun", value: 52)
    ]

    static let weekRevenue: [RevenuePoint] = [
        RevenuePoint(label: "Mon", value: 18),
        RevenuePoint(label: "Tue", value: 24),
        RevenuePoint(label: "Wed", value: 21),
        RevenuePoint(label: "Thu", value: 36),
        RevenuePoint(label: "Fri", value: 42),
        RevenuePoint(label: "Sat", value: 54),
        RevenuePoint(label: "Sun", value: 31)
    ]

    static let salesCards: [SalesSummaryCard] = [
        SalesSummaryCard(title: "Premium Sarees",    subtitle: "Top assisted category", value: "₹42L", icon: "sparkles"),
        SalesSummaryCard(title: "Clienteling Sales", subtitle: "From appointments",     value: "₹18L", icon: "person.2.fill"),
        SalesSummaryCard(title: "Cross-sell Attach", subtitle: "Cart add-ons",          value: "31%",  icon: "bag.badge.plus")
    ]
}
