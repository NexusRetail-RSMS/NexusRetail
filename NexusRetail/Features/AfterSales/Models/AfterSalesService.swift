//
//  AfterSalesService.swift
//  NexusRetail
//
//  Real backend wiring for the After-Sales flow: pull the items on a scanned
//  invoice, check warranty/exchange eligibility, and process a repair/exchange.
//

import Foundation
import Supabase

// MARK: - DTOs

/// A single purchased line on a scanned invoice (order).
struct AfterSalesInvoiceItem: Identifiable, Hashable {
    let id: UUID          // order_line_item.id
    let itemId: Int64
    let name: String
    let category: String
    let sku: String
    let price: Double
    let quantity: Int
    let imageUrl: String?
}

/// Eligibility snapshot for an item on an order (mirrors check_after_sales_eligibility).
struct AfterSalesEligibility: Decodable {
    let found: Bool
    // Kept as raw strings to avoid microsecond timestamp decode issues; logic uses the booleans.
    let purchasedAt: String?
    let category: String?
    let warrantyMonths: Int?
    let warrantyEnd: String?
    let exchangeEnd: String?
    let inWarranty: Bool
    let exchangeAllowed: Bool

    enum CodingKeys: String, CodingKey {
        case found
        case purchasedAt = "purchased_at"
        case category
        case warrantyMonths = "warranty_months"
        case warrantyEnd = "warranty_end"
        case exchangeEnd = "exchange_end"
        case inWarranty = "in_warranty"
        case exchangeAllowed = "exchange_allowed"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        found = (try? c.decode(Bool.self, forKey: .found)) ?? false
        purchasedAt = try? c.decodeIfPresent(String.self, forKey: .purchasedAt)
        category = try? c.decodeIfPresent(String.self, forKey: .category)
        warrantyMonths = try? c.decodeIfPresent(Int.self, forKey: .warrantyMonths)
        warrantyEnd = try? c.decodeIfPresent(String.self, forKey: .warrantyEnd)
        exchangeEnd = try? c.decodeIfPresent(String.self, forKey: .exchangeEnd)
        inWarranty = (try? c.decode(Bool.self, forKey: .inWarranty)) ?? false
        exchangeAllowed = (try? c.decode(Bool.self, forKey: .exchangeAllowed)) ?? false
    }
}

/// Result of processing a repair/exchange (mirrors process_after_sales).
struct AfterSalesProcessResult: Decodable {
    let success: Bool
    let ticketId: UUID?
    let type: String?
    let inWarranty: Bool?
    let warrantyStatus: String?
    let serviceCost: Double?
    let restocked: Bool?
    let message: String?
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case success
        case ticketId = "ticket_id"
        case type
        case inWarranty = "in_warranty"
        case warrantyStatus = "warranty_status"
        case serviceCost = "service_cost"
        case restocked
        case message
        case reason
    }
}

/// Full invoice detail powering the After-Sales invoice screen (customer + items
/// with per-item purchase date, warranty end, and eligibility).
struct AfterSalesInvoiceDetails: Decodable {
    let found: Bool
    let customer: RequestCustomer?
    let items: [AfterSalesInvoiceLine]

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        found = (try? c.decode(Bool.self, forKey: .found)) ?? false
        items = (try? c.decode([AfterSalesInvoiceLine].self, forKey: .items)) ?? []
        let custDTO: CustomerDTO? = (try? c.decodeIfPresent(CustomerDTO.self, forKey: .customer)) ?? nil
        if let cust = custDTO {
            customer = RequestCustomer(name: cust.name ?? "Customer",
                                       phone: cust.phone ?? "",
                                       email: cust.email ?? "")
        } else {
            customer = nil
        }
    }

    private struct CustomerDTO: Decodable {
        let name: String?
        let phone: String?
        let email: String?
    }

    enum CodingKeys: String, CodingKey { case found, customer, items }
}

struct AfterSalesInvoiceLine: Decodable, Identifiable, Hashable {
    let lineId: UUID
    let itemId: Int64
    let name: String
    let category: String
    let sku: String
    let price: Double
    let quantity: Int
    let imageUrl: String?
    let purchaseDate: Date?
    let warrantyEndDate: Date?
    let inWarranty: Bool
    let exchangeAllowed: Bool

    var id: UUID { lineId }

    enum CodingKeys: String, CodingKey {
        case lineId = "line_id"
        case itemId = "item_id"
        case name, category, sku, price, quantity
        case imageUrl = "image_url"
        case pexelsPage = "pexels_page"
        case purchasedAt = "purchased_at"
        case warrantyEnd = "warranty_end"
        case inWarranty = "in_warranty"
        case exchangeAllowed = "exchange_allowed"
        case products
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lineId = try c.decode(UUID.self, forKey: .lineId)
        itemId = try c.decode(Int64.self, forKey: .itemId)
        name = (try? c.decode(String.self, forKey: .name)) ?? "Item"
        category = (try? c.decode(String.self, forKey: .category)) ?? "—"
        sku = (try? c.decode(String.self, forKey: .sku)) ?? "—"
        // numeric can arrive as number or string
        if let d = try? c.decode(Double.self, forKey: .price) { price = d }
        else if let s = try? c.decode(String.self, forKey: .price) { price = Double(s) ?? 0 }
        else { price = 0 }
        quantity = (try? c.decode(Int.self, forKey: .quantity)) ?? 1

        // Try flat image_url/pexels_page first, then fall back to nested products object
        var rawImage = (try? c.decodeIfPresent(String.self, forKey: .imageUrl)) ?? nil
        var pexels = (try? c.decodeIfPresent(String.self, forKey: .pexelsPage)) ?? nil
        if rawImage == nil && pexels == nil {
            struct ProductsNested: Decodable {
                var image_url: String?
                var pexels_page: String?
            }
            if let products = try? c.decodeIfPresent(ProductsNested.self, forKey: .products) {
                rawImage = products.image_url
                pexels = products.pexels_page
            }
        }
        imageUrl = POSProductRepository.shared.extractPexelsImageUrl(from: pexels ?? "") ?? rawImage

        let purchasedStr = (try? c.decodeIfPresent(String.self, forKey: .purchasedAt)) ?? nil
        let warrantyStr = (try? c.decodeIfPresent(String.self, forKey: .warrantyEnd)) ?? nil
        purchaseDate = AfterSalesService.parseServerDate(purchasedStr)
        warrantyEndDate = AfterSalesService.parseServerDate(warrantyStr)

        inWarranty = (try? c.decode(Bool.self, forKey: .inWarranty)) ?? false
        exchangeAllowed = (try? c.decode(Bool.self, forKey: .exchangeAllowed)) ?? false
    }
}

// MARK: - Service

enum AfterSalesService {

    private static var client: SupabaseClient { SupabaseManager.shared.client }

    /// Parses Postgres timestamptz strings (with or without fractional seconds).
    static func parseServerDate(_ string: String?) -> Date? {
        guard let string else { return nil }
        let withFrac = ISO8601DateFormatter()
        withFrac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = withFrac.date(from: string) { return d }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: string)
    }

    struct InvoiceParams: Encodable { let p_order_id: String }

    /// Single-call invoice detail (customer + items + warranty/eligibility).
    static func fetchInvoiceDetails(orderId: String) async throws -> AfterSalesInvoiceDetails {
        try await client
            .rpc("after_sales_invoice", params: InvoiceParams(p_order_id: orderId))
            .execute()
            .value
    }

    /// Fetch the real purchased items on a scanned invoice (order UUID string).
    static func fetchInvoiceItems(orderId: String) async throws -> [AfterSalesInvoiceItem] {
        struct ProductJoin: Decodable {
            let item_name: String
            let category: String?
            let sku_code: String?
            let image_url: String?
            let pexels_page: String?
        }
        struct LineRow: Decodable {
            let id: UUID
            let item_id: Int64
            let quantity: Int
            let applied_price: Double?
            let products: ProductJoin?

            enum CodingKeys: String, CodingKey {
                case id, item_id, quantity, applied_price, products
            }

            init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                id = try c.decode(UUID.self, forKey: .id)
                item_id = try c.decode(Int64.self, forKey: .item_id)
                quantity = (try? c.decode(Int.self, forKey: .quantity)) ?? 1
                // PostgREST can serialize `numeric` as either a JSON number or a string.
                if let d = try? c.decodeIfPresent(Double.self, forKey: .applied_price) {
                    applied_price = d
                } else if let s = try? c.decodeIfPresent(String.self, forKey: .applied_price) {
                    applied_price = Double(s)
                } else {
                    applied_price = nil
                }
                products = try? c.decodeIfPresent(ProductJoin.self, forKey: .products)
            }
        }

        let rows: [LineRow] = try await client
            .from("order_line_item")
            .select("id, item_id, quantity, applied_price, products(item_name, category, sku_code, image_url, pexels_page)")
            .eq("order_id", value: orderId)
            .execute()
            .value

        return rows.map { row in
            let img = POSProductRepository.shared.extractPexelsImageUrl(from: row.products?.pexels_page ?? "")
                ?? row.products?.image_url
            return AfterSalesInvoiceItem(
                id: row.id,
                itemId: row.item_id,
                name: row.products?.item_name ?? "Unknown Item",
                category: row.products?.category ?? "—",
                sku: row.products?.sku_code ?? "SKU-\(row.item_id)",
                price: row.applied_price ?? 0,
                quantity: row.quantity,
                imageUrl: img
            )
        }
    }

    struct EligibilityParams: Encodable {
        let p_order_id: String
        let p_item_id: Int64
    }

    static func checkEligibility(orderId: String, itemId: Int64) async throws -> AfterSalesEligibility {
        try await client
            .rpc("check_after_sales_eligibility",
                 params: EligibilityParams(p_order_id: orderId, p_item_id: itemId))
            .execute()
            .value
    }

    struct ProcessParams: Encodable {
        let p_order_id: String
        let p_item_id: Int64
        let p_type: String       // "repair" | "exchange"
        let p_issue: String
        let p_parts_cost: Double
    }

    static func process(orderId: String, itemId: Int64, type: String, issue: String, partsCost: Double) async throws -> AfterSalesProcessResult {
        try await client
            .rpc("process_after_sales",
                 params: ProcessParams(p_order_id: orderId, p_item_id: itemId, p_type: type, p_issue: issue, p_parts_cost: partsCost))
            .execute()
            .value
    }
}
