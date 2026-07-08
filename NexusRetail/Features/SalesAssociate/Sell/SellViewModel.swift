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
    
    // Gateway retention
    private var razorpayGateway: RazorpayGateway?
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
        let params = try createCheckoutParams(storeID: storeID, associateID: associateID)
        let orderIdResponse: UUID = try await SupabaseManager.shared.client
            .rpc("process_pos_checkout", params: params)
            .execute()
            .value
        self.lastOrderId = orderIdResponse
        
        // Refresh local cache of stock so UI updates immediately
        await POSProductRepository.shared.refreshStockForStore(storeID: storeID)
    }
    
    private func createCheckoutParams(storeID: UUID?, associateID: UUID?) throws -> CheckoutParams {
        guard let storeID = storeID, let associateID = associateID else { throw NSError(domain: "Checkout", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing storeID or associateID"]) }
        
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
    }
    
    // MARK: - Client lookup / quick-create (checkout customer linking)

    /// Normalizes a phone string to its last 10 digits for tolerant matching
    /// (e.g. "+91 98765 43210" and "9876543210" compare equal).
    private func normalizedPhone(_ phone: String) -> String {
        let digits = phone.filter(\.isNumber)
        return String(digits.suffix(10))
    }

    /// Looks up a client by phone. Fetches all clients and matches in memory on
    /// normalized digits — fine for this dataset's size; if the client table
    /// grows large, replace with a server-side normalized-phone query/index.
    func findClient(byPhone phone: String) async -> (id: UUID, name: String)? {
        let target = normalizedPhone(phone)
        guard target.count >= 6 else { return nil }

        struct ClientRow: Decodable { let id: UUID; let name: String; let phone: String? }
        do {
            let rows: [ClientRow] = try await SupabaseManager.shared.client
                .from("client")
                .select("id, name, phone")
                .execute()
                .value
            if let match = rows.first(where: { normalizedPhone($0.phone ?? "") == target }) {
                return (match.id, match.name)
            }
            return nil
        } catch {
            print("SellViewModel: findClient error: \(error)")
            return nil
        }
    }

    /// Creates a new client with the given name/phone and returns its id.
    func createClient(name: String, phone: String, createdBy: UUID?) async throws -> UUID {
        struct InsertClient: Encodable { let name: String; let phone: String; let created_by: UUID? }
        struct InsertedClient: Decodable { let id: UUID }

        let inserted: InsertedClient = try await SupabaseManager.shared.client
            .from("client")
            .insert(InsertClient(name: name, phone: phone, created_by: createdBy))
            .select("id")
            .single()
            .execute()
            .value
        return inserted.id
    }

    func fetchRecentOrders(storeID: UUID?, associateID: UUID?) async {
        guard let storeID = storeID, let associateID = associateID else {
            await MainActor.run { self.completedOrders = [] }
            return
        }
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
                .eq("associate_id", value: associateID)
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

    // MARK: - Email Receipt
    func sendReceiptEmail(to email: String, orderId: String, storeName: String, cashierName: String, items: [(product: POSProduct, count: Int)], total: Double, subtotal: Double) async {
        let resendApiKey = "re_3ot8yx3s_BDYPp6FcxJXDcFsSXU6bGW7t"
        guard let url = URL(string: "https://api.resend.com/emails") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(resendApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        var itemsHtml = ""
        for item in items {
            itemsHtml += """
            <tr>
                <td style="padding: 8px; border-bottom: 1px solid #ddd;">\(item.product.name)<br><small style="color: #666;">SKU: \(item.product.sku)</small></td>
                <td style="padding: 8px; border-bottom: 1px solid #ddd; text-align: center;">\(item.count)</td>
                <td style="padding: 8px; border-bottom: 1px solid #ddd; text-align: right;">₹\(String(format: "%.0f", item.product.price * Double(item.count)))</td>
            </tr>
            """
        }
        
        let htmlBody = """
        <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #eee; border-radius: 8px; padding: 24px;">
            <div style="text-align: center; margin-bottom: 24px;">
                <h2 style="margin: 0; letter-spacing: 2px;">NEXUS RETAIL</h2>
                <p style="margin: 4px 0 0; color: #666; font-size: 12px;">Official Store Receipt - \(storeName)</p>
            </div>
            
            <div style="background: #f9f9f9; padding: 12px; border-radius: 6px; margin-bottom: 24px; font-size: 14px;">
                <p style="margin: 4px 0;"><b>Order ID:</b> \(orderId)</p>
                <p style="margin: 4px 0;"><b>Date:</b> \(Date().formatted(date: .long, time: .shortened))</p>
                <p style="margin: 4px 0;"><b>Cashier:</b> \(cashierName)</p>
            </div>
            
            <table style="width: 100%; border-collapse: collapse; margin-bottom: 24px; font-size: 14px;">
                <thead>
                    <tr style="background: #f0f0f0;">
                        <th style="padding: 8px; text-align: left;">Item</th>
                        <th style="padding: 8px; text-align: center;">Qty</th>
                        <th style="padding: 8px; text-align: right;">Amount</th>
                    </tr>
                </thead>
                <tbody>
                    \(itemsHtml)
                </tbody>
            </table>
            
            <div style="text-align: right; font-size: 14px; margin-bottom: 32px;">
                <p style="margin: 4px 0;">Subtotal: ₹\(String(format: "%.0f", subtotal))</p>
                <p style="margin: 4px 0;">GST (18% incl.): ₹\(String(format: "%.0f", total * 0.18))</p>
                <h3 style="margin: 8px 0 0; font-size: 18px;">Total Paid: ₹\(String(format: "%.0f", total))</h3>
            </div>
            
            <div style="text-align: center; color: #888; font-size: 12px;">
                <p>Thank you for shopping at Nexus Retail!</p>
                <p>For returns & exchanges visit any store within 30 days.</p>
            </div>
        </div>
        """
        
        let payload: [String: Any] = [
            "from": "Nexus Retail <receipts@updates.nexusretail.tech>",
            "to": [email],
            "subject": "Your Receipt from Nexus Retail (\(orderId))",
            "html": htmlBody
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpRes = response as? HTTPURLResponse, httpRes.statusCode >= 200, httpRes.statusCode < 300 {
                print("SellViewModel: Successfully emailed receipt to \(email)")
            } else {
                print("SellViewModel: Failed to email receipt to \(email)")
            }
        } catch {
            print("SellViewModel: Error emailing receipt: \(error)")
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

    /// Parsed timestamp for sorting (falls back to distantPast if unparseable).
    var createdDate: Date {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: createdAt) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: createdAt) ?? .distantPast
    }

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
