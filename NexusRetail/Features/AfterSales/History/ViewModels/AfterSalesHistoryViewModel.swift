import Foundation
import Supabase

@Observable
final class AfterSalesHistoryViewModel {

    var exchanges: [AfterSalesHistoryView.ExchangeItem] = []
    var repairs: [AfterSalesHistoryView.RepairItem] = []
    var isLoading = false
    var errorMessage: String? = nil

    // MARK: - Row (mirrors ActiveRepairsView / AfterSalesTicketsListView)

    private struct TicketRow: Decodable {
        let id: UUID
        let type: String
        let stage: String
        let createdAt: Date
        let serviceCost: Double?
        let itemName: String?
        let issueDescription: String?
        let orderId: String?
        let products: ProductJoin?
        let client: ClientJoin?
        let replacementItemRows: [ReplacementItemRow]?
        let orders: OrderJoin?
        let orderLineItem: OrderLineItemJoin?

        struct ProductJoin: Decodable {
            let skuCode: String?
            let itemName: String?
            let imageUrl: String?
            let pexelsPage: String?
            enum CodingKeys: String, CodingKey {
                case skuCode = "sku_code"
                case itemName = "item_name"
                case imageUrl = "image_url"
                case pexelsPage = "pexels_page"
            }
        }
        struct ClientJoin: Decodable {
            let name: String?
        }
        struct ReplacementItemRow: Decodable {
            let id: UUID
            let itemName: String?
            let quantity: Int
            let products: ProductJoin?

            enum CodingKeys: String, CodingKey {
                case id
                case itemName = "item_name"
                case quantity
                case products
            }
        }
        struct OrderJoin: Decodable {
            let id: UUID
            let total: Double
            let createdAt: Date
            let pickupCode: String?

            enum CodingKeys: String, CodingKey {
                case id, total
                case createdAt = "created_at"
                case pickupCode = "pickup_code"
            }
        }
        struct OrderLineItemJoin: Decodable {
            let appliedPrice: Double
            let quantity: Int

            enum CodingKeys: String, CodingKey {
                case appliedPrice = "applied_price"
                case quantity
            }
        }

        enum CodingKeys: String, CodingKey {
            case id, type, stage
            case createdAt = "created_at"
            case serviceCost = "service_cost"
            case itemName = "item_name"
            case issueDescription = "issue_description"
            case orderId = "order_id"
            case products
            case client
            case replacementItemRows = "after_sales_ticket_replacement_item"
            case orders
            case orderLineItem = "order_line_item"
        }
    }

    // MARK: - Fetch

    @MainActor
    func fetchHistory(storeID: UUID?) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            var query = SupabaseManager.shared.client
                .from("after_sales_ticket")
                .select("id, type, stage, created_at, service_cost, item_name, issue_description, order_id, products(sku_code, item_name, image_url, pexels_page), client(name), after_sales_ticket_replacement_item(id, item_name, quantity, products(sku_code, item_name, image_url, pexels_page)), orders(id, total, created_at, pickup_code), order_line_item(applied_price, quantity)")
                .eq("stage", value: "completed")

            if let storeID {
                query = query.eq("store_id", value: storeID.uuidString)
            }

            let rows: [TicketRow] = try await query
                .order("created_at", ascending: false)
                .execute()
                .value

            exchanges = rows
                .filter { $0.type == "exchange" || $0.type == "return" }
                .map { row in
                    AfterSalesHistoryView.ExchangeItem(
                        id: row.id,
                        customerName: row.client?.name ?? "Walk-in Customer",
                        orderId: row.orderId,
                        productName: row.itemName ?? "Item",
                        imageUrl: resolvedImageURL(row.products),
                        date: row.createdAt,
                        status: "Completed",
                        replacementItem: resolvedReplacementItem(row.replacementItemRows),
                        invoice: resolvedInvoice(order: row.orders, lineItem: row.orderLineItem)
                    )
                }

            repairs = rows
                .filter { $0.type == "repair" }
                .map { row in
                    AfterSalesHistoryView.RepairItem(
                        id: row.id,
                        customerName: row.client?.name ?? "Walk-in Customer",
                        orderId: row.orderId,
                        productName: row.itemName ?? "Item",
                        imageUrl: resolvedImageURL(row.products),
                        issueDescription: row.issueDescription,
                        serviceCost: row.serviceCost,
                        date: row.createdAt,
                        status: "Completed",
                        invoice: resolvedInvoice(order: row.orders, lineItem: row.orderLineItem)
                    )
                }
        } catch {
            errorMessage = "Couldn't load history. Please try again."
            print("After Sales history fetch error: \(error)")
        }
    }

    private func resolvedImageURL(_ product: TicketRow.ProductJoin?) -> String? {
        POSProductRepository.shared.extractPexelsImageUrl(from: product?.pexelsPage ?? "")
            ?? product?.imageUrl
    }

    private func resolvedReplacementItem(_ rows: [TicketRow.ReplacementItemRow]?) -> AfterSalesHistoryView.ReplacementItem? {
        guard let row = rows?.first else { return nil }
        return AfterSalesHistoryView.ReplacementItem(
            id: row.id,
            productName: row.itemName ?? row.products?.itemName ?? "Item",
            imageUrl: resolvedImageURL(row.products),
            quantity: row.quantity
        )
    }

    private func resolvedInvoice(order: TicketRow.OrderJoin?, lineItem: TicketRow.OrderLineItemJoin?) -> AfterSalesHistoryView.InvoiceInfo? {
        guard let order else { return nil }
        return AfterSalesHistoryView.InvoiceInfo(
            id: order.id,
            orderTotal: order.total,
            pricePaid: lineItem?.appliedPrice,
            pickupCode: order.pickupCode,
            orderDate: order.createdAt
        )
    }
}
