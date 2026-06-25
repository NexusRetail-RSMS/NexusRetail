//
//  ProductCatalogueViewModel.swift
//  NexusRetail
//

import SwiftUI
import Combine

// MARK: - Models

struct TrendingProduct: Identifiable {
    let id: UUID
    let name: String
    let stockStatus: String
    let units: Int
    let price: Double
    let imageName: String // SF Symbol name
}

struct CatalogueProduct: Identifiable {
    let id: UUID
    let name: String
    let sku: String
    let category: String
    let price: Double
    let stock: Int
    let date: String
    let imageName: String
}

// MARK: - ViewModel

@MainActor
final class ProductCatalogueViewModel: ObservableObject {

    // MARK: Published State

    @Published var trendingProducts: [TrendingProduct]
    @Published var currentTrendingIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var searchText = ""
    @Published var selectedCategory = "All"
    let categoryOptions = [
        "All",
        "Watches",
        "Bags",
        "Fragrances"
    ]
    private var allProducts: [CatalogueProduct]
    private var timer: AnyCancellable?

    // MARK: Computed — filtered list

    var filteredProducts: [CatalogueProduct] {

        allProducts.filter { product in

            let matchesSearch =
                searchText.isEmpty ||
                product.name.localizedCaseInsensitiveContains(searchText) ||
                product.sku.localizedCaseInsensitiveContains(searchText)

            let matchesCategory =
                selectedCategory == "All" ||
                product.category == selectedCategory

            return matchesSearch && matchesCategory
        }
    }

    // MARK: Init

    init() {
        self.trendingProducts = [
            TrendingProduct(
                id: UUID(), name: "Noiré Burgundy Tote",
                stockStatus: "In Stock", units: 24,
                price: 1290, imageName: "bag"
            ),
            TrendingProduct(
                id: UUID(), name: "Classic Leather Wallet",
                stockStatus: "In Stock", units: 58,
                price: 450, imageName: "hero"
            ),
            TrendingProduct(
                id: UUID(), name: "Silk Evening Scarf",
                stockStatus: "Low Stock", units: 7,
                price: 320, imageName: "watch"
            ),
            TrendingProduct(
                id: UUID(), name: "Monogram Crossbody",
                stockStatus: "In Stock", units: 31,
                price: 980, imageName: "perfume"
            )
        ]

        self.allProducts = [
            // Active
            CatalogueProduct(
                id: UUID(), name: "Aurelia Croco Tote",
                sku: "BAG-AUR-204", category: "Bags",
                price: 2450, stock: 128,
                date: "Jan 12, 2026", imageName: "bag"
            ),
            CatalogueProduct(
                id: UUID(), name: "Véloute Silk Blouse",
                sku: "APP-VEL-031", category: "Fragrances",
                price: 890, stock: 44,
                date: "Feb 02, 2026", imageName: "perfume"
            ),
            CatalogueProduct(
                id: UUID(), name: "Monogram Crossbody",
                sku: "BAG-MON-117", category: "Bags",
                price: 980, stock: 31,
                date: "Mar 15, 2026", imageName: "hero"
            ),
            // Low Stock → shown under Active with badge
            CatalogueProduct(
                id: UUID(), name: "Aurum Tourbillon",
                sku: "WCH-AUR-088", category: "Watches",
                price: 18900, stock: 6,
                date: "Mar 03, 2026", imageName: "watch"
            ),
            // Inactive
            CatalogueProduct(
                id: UUID(), name: "Nocturne Velvet Fragrances",
                sku: "BAG-NOC-055", category: "Fragrances",
                price: 640, stock: 0,
                date: "Nov 10, 2025", imageName: "perfume"
            ),
            CatalogueProduct(
                id: UUID(), name: "Classic Leather Watches",
                sku: "ACC-CLW-009", category: "Watches",
                price: 450, stock: 0,
                date: "Oct 22, 2025", imageName: "watch"
            ),
            // Out of Stock
            CatalogueProduct(
                id: UUID(), name: "L'Éclat Noir Parfum",
                sku: "FRG-ECL-512", category: "Fragrances",
                price: 320, stock: 0,
                date: "Feb 20, 2026", imageName: "perfume"
            ),
            CatalogueProduct(
                id: UUID(), name: "Ivory Pearl Earrings",
                sku: "JWL-IPE-201", category: "Watches",
                price: 580, stock: 0,
                date: "Jan 05, 2026", imageName: "watch"
            ),
            // Upcoming
            CatalogueProduct(
                id: UUID(), name: "Sable Trench Coat",
                sku: "APP-SBL-340", category: "Bags",
                price: 3200, stock: 0,
                date: "Aug 01, 2026", imageName: "hero"
            ),
            CatalogueProduct(
                id: UUID(), name: "Obsidian Chronograph",
                sku: "WCH-OBS-099", category: "Watches",
                price: 24500, stock: 0,
                date: "Sep 15, 2026", imageName: "watch"
            )
        ]

        startAutoScroll()
    }

    // MARK: Auto-scroll Timer

    private func startAutoScroll() {
        timer = Timer.publish(every: 3, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                withAnimation(.easeInOut(duration: 0.4)) {
                    self.currentTrendingIndex =
                        (self.currentTrendingIndex + 1) % self.trendingProducts.count
                }
            }
    }

    func stopAutoScroll() {
        timer?.cancel()
        timer = nil
    }

    func resumeAutoScroll() {
        guard timer == nil else { return }
        startAutoScroll()
    }

    // MARK: Computed Helpers — Trending

    func formattedPrice(for product: TrendingProduct) -> String {
        formatPrice(product.price)
    }

    func stockLabel(for product: TrendingProduct) -> String {
        "\(product.stockStatus) · \(product.units) units"
    }

    func stockColor(for product: TrendingProduct) -> Color {
        product.stockStatus.lowercased().contains("low") ? RSMSColors.warning : RSMSColors.success
    }

    // MARK: Computed Helpers — Catalogue

    func formattedPrice(for product: CatalogueProduct) -> String {
        formatPrice(product.price)
    }

    func badgeLabel(for product: CatalogueProduct) -> String? {
        product.category
    }
    // MARK: Private

    private func formatPrice(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(Int(value))"
    }
}
