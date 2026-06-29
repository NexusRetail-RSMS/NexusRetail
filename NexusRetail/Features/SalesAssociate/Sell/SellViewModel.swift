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
