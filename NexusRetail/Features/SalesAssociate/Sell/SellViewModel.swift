import SwiftUI
import Combine

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
    
    // Chosen payment method
    var selectedPaymentMethod: POSPaymentMethod = .razorpay
    
    // Unavailable product and alternative helper tracking
    var originalUnavailableProduct: POSProduct? = nil
    var isAlternativeSuggested: Bool = false
    
    // Receipt digital share fields
    var receiptSharedEmail: String = ""
    var receiptSharedPhone: String = ""
    var isReceiptShared: Bool = false
    
    var totalAmount: Double {
        cartItems.reduce(0) { $0 + $1.price }
    }
    
    var subtotalAmount: Double {
        totalAmount
    }
    
    func addToCart(product: POSProduct, isAlternative: Bool = false) {
        cartItems.append(product)
        let log = CartActionLog(productName: product.name, action: .added, isAlternative: isAlternative)
        actionLogs.append(log)
    }
    
    func removeFromCart(product: POSProduct) {
        if let index = cartItems.firstIndex(where: { $0.id == product.id }) {
            cartItems.remove(at: index)
            let log = CartActionLog(productName: product.name, action: .removed, isAlternative: false)
            actionLogs.append(log)
        }
    }
    
    // Dynamic completed orders log
    var completedOrders: [MockPOSOrder] = [
        MockPOSOrder(id: "#421", client: "Ananya Rao", amount: 3299, status: "Completed", time: "11:30 AM", date: "Today"),
        MockPOSOrder(id: "#420", client: "Kabir Mehta", amount: 2199, status: "Pending Payment", time: "10:15 AM", date: "Today"),
        MockPOSOrder(id: "#419", client: "Mira Kapoor", amount: 1999, status: "Alternative Suggested", time: "Yesterday", date: "Yesterday")
    ]
    
    func recordCompletedSale() {
        let orderNumber = "#\(completedOrders.count + 420 + 2)"
        let clientName = selectedClient ?? "Anonymous"
        let newOrder = MockPOSOrder(
            id: orderNumber,
            client: clientName,
            amount: totalAmount,
            status: isAlternativeSuggested ? "Alternative Suggested" : "Completed",
            time: "Just Now",
            date: "Today"
        )
        completedOrders.insert(newOrder, at: 0)
    }
    
    func resetFlow() {
        cartItems = []
        actionLogs = []
        selectedClient = nil
        selectedPaymentMethod = .razorpay
        originalUnavailableProduct = nil
        isAlternativeSuggested = false
        receiptSharedEmail = ""
        receiptSharedPhone = ""
        isReceiptShared = false
    }
}

struct MockPOSOrder: Identifiable, Hashable {
    let id: String
    let client: String
    let amount: Double
    let status: String
    let time: String
    let date: String
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
