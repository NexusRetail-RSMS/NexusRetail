import SwiftUI
import Combine
import Supabase

enum POSPaymentMethod: String, CaseIterable, Identifiable {
    case razorpay = "Razorpay"
    case cardTerminal = "Card Terminal"
    
    var id: String { rawValue }
}

@Observable
class SellViewModel {
    // Current cart items
    var cartItems: [POSProduct] = []
    
    // Log of actions (e.g. "Blue Oxford Shirt - Removed", "Grey Oxford Shirt - Added")
    var actionLogs: [CartActionLog] = []
    
    // Selected client name (nil means skipped/anonymous)
    var selectedClient: String? = nil
    
    // Selected client UUID for DB linkage
    var selectedClientId: UUID? = nil
    
    // Chosen payment method
    var selectedPaymentMethod: POSPaymentMethod = .razorpay
    
    // Unavailable product and alternative helper tracking
    var originalUnavailableProduct: POSProduct? = nil
    var isAlternativeSuggested: Bool = false
    
    // Receipt digital share fields
    var receiptSharedEmail: String = ""
    var receiptSharedPhone: String = ""
    var isReceiptShared: Bool = false
    
    // Last completed order ID (from DB after processCheckout)
    var lastOrderId: UUID? = nil
    
    var totalAmount: Double {
        // Sum price for each cart item — duplicates are intentional (qty × price)
        cartItems.reduce(0) { $0 + $1.price }
    }

    var subtotalAmount: Double { totalAmount }
    
    // Returns how many of this product are currently in the cart
    func quantityInCart(productId: UUID) -> Int {
        cartItems.filter { $0.id == productId }.count
    }

    // Returns true if we can add one more of this product (stock allows it)
    func canAddMore(_ product: POSProduct) -> Bool {
        // Get the live stock from the repository
        let currentStock = POSProductRepository.shared.products
            .first(where: { $0.id == product.id })?.stock ?? product.stock
        return quantityInCart(productId: product.id) < currentStock
    }

    func addToCart(product: POSProduct, isAlternative: Bool = false) {
        // Guard: never exceed available stock (using live stock from repository)
        guard canAddMore(product) else { return }
        cartItems.append(product)
        actionLogs.append(CartActionLog(productName: product.name, action: .added, isAlternative: isAlternative))
    }

    func removeFromCart(product: POSProduct) {
        if let index = cartItems.firstIndex(where: { $0.id == product.id }) {
            cartItems.remove(at: index)
            actionLogs.append(CartActionLog(productName: product.name, action: .removed, isAlternative: false))
        }
    }
    
    // Completed orders from DB
    var completedOrders: [DBOrder] = []
    var isLoadingOrders: Bool = false
    
    struct CheckoutParams: Encodable {
        let p_store_id: UUID
        let p_associate_id: UUID
        let p_items: [[String: AnyCodable]]
        let p_total: Double
        let p_client_id: UUID?
        let p_payment_method: String?
    }
    
    struct AnyCodable: Encodable {
        let value: Any
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch value {
            case let intVal as Int: try container.encode(intVal)
            case let int64Val as Int64: try container.encode(int64Val)
            case let doubleVal as Double: try container.encode(doubleVal)
            case let stringVal as String: try container.encode(stringVal)
            case let uuidVal as UUID: try container.encode(uuidVal)
            default:
                throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Invalid AnyCodable value"))
            }
        }
    }
    
    func processCheckout(storeID: UUID?, associateID: UUID?) async throws {
        guard let storeID = storeID, let associateID = associateID else { return }
        
        // Group items by ID to handle quantities
        var itemCounts: [UUID: (POSProduct, Int)] = [:]
        for item in cartItems {
            if let existing = itemCounts[item.id] {
                itemCounts[item.id] = (existing.0, existing.1 + 1)
            } else {
                itemCounts[item.id] = (item, 1)
            }
        }
        
        let pItems: [[String: AnyCodable]] = itemCounts.values.map { (product, quantity) in
            return [
                "item_id": AnyCodable(value: product.itemId),
                "quantity": AnyCodable(value: quantity),
                "price": AnyCodable(value: product.price)
            ]
        }
        
        // Map the POS payment method to the DB payment_method enum ('razorpay' | 'card').
        let paymentMethodValue = selectedPaymentMethod == .razorpay ? "razorpay" : "card"

        let params = CheckoutParams(
            p_store_id: storeID,
            p_associate_id: associateID,
            p_items: pItems,
            p_total: totalAmount,
            p_client_id: selectedClientId,
            p_payment_method: paymentMethodValue
        )
        
        let orderIdResponse: UUID = try await SupabaseManager.shared.client
            .rpc("process_pos_checkout", params: params)
            .execute()
            .value
        self.lastOrderId = orderIdResponse
    }
    
    func fetchRecentOrders(storeID: UUID?) async {
        guard let storeID = storeID else { return }
        isLoadingOrders = true
        defer { isLoadingOrders = false }

        struct OrderRow: Decodable, Identifiable {
            let id: UUID
            let total: Double
            let status: String
            let created_at: String
            let associate_id: UUID?
            let client_id: UUID?
        }

        do {
            let rows: [OrderRow] = try await SupabaseManager.shared.client
                .from("orders")
                .select("id, total, status, created_at, associate_id, client_id")
                .eq("store_id", value: storeID)
                .eq("status", value: "completed")
                .order("created_at", ascending: false)
                .limit(20)
                .execute()
                .value

            self.completedOrders = rows.map { row in
                DBOrder(
                    id: "ORD-\(row.id.uuidString.prefix(8).uppercased())",
                    amount: row.total,
                    status: "Completed",
                    createdAt: row.created_at
                )
            }
        } catch {
            print("SellViewModel: Error fetching orders: \(error)")
        }
    }

    func resetFlow() {
        cartItems = []
        actionLogs = []
        selectedClient = nil
        selectedClientId = nil
        selectedPaymentMethod = .razorpay
        originalUnavailableProduct = nil
        isAlternativeSuggested = false
        receiptSharedEmail = ""
        receiptSharedPhone = ""
        isReceiptShared = false
        // Note: lastOrderId is intentionally NOT reset here — ReceiptView still needs it
    }
}

struct DBOrder: Identifiable, Hashable {
    let id: String
    let amount: Double
    let status: String
    let createdAt: String

    var formattedTime: String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = f.date(from: createdAt) {
            let df = DateFormatter()
            df.dateStyle = .none
            df.timeStyle = .short
            return df.string(from: date)
        }
        return ""
    }

    var formattedDate: String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = f.date(from: createdAt) {
            if Calendar.current.isDateInToday(date) { return "Today" }
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .none
            return df.string(from: date)
        }
        return ""
    }
}

struct CartActionLog: Identifiable, Hashable {
    let id = UUID()
    let productName: String
    let action: CartAction
    let isAlternative: Bool
    
    enum CartAction {
        case added
        case removed
    }
}
