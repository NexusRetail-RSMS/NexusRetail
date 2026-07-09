import Foundation
import SwiftUI
import Razorpay

class RazorpayGateway: NSObject, RazorpayPaymentCompletionProtocol, RazorpayPaymentCompletionProtocolWithData, ExternalWalletSelectionProtocol {
    
    private var razorpay: RazorpayCheckout?
    private var completion: ((Result<[AnyHashable: Any], Error>) -> Void)?
    
    init(keyID: String) {
        super.init()
        self.razorpay = RazorpayCheckout.initWithKey(keyID, andDelegateWithData: self)
        self.razorpay?.setExternalWalletSelectionDelegate(self)
    }
    
    /// Opens the Razorpay Checkout form
    func openCheckout(options: [String: Any], completion: @escaping (Result<[AnyHashable: Any], Error>) -> Void) {
        self.completion = completion
        
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }),
               let rootVC = window.rootViewController {
                
                var topVC = rootVC
                while let presented = topVC.presentedViewController {
                    topVC = presented
                }
                
                print("🛒 [RazorpayGateway] Launching Razorpay Checkout with options: \(options)")
                self.razorpay?.open(options, displayController: topVC)
            } else {
                print("❌ [RazorpayGateway] Error: Could not find key window or root view controller to present Razorpay")
                completion(.failure(NSError(domain: "RazorpayGateway", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not find root view controller"])))
            }
        }
    }
    
    // MARK: - RazorpayPaymentCompletionProtocolWithData
    
    func onPaymentSuccess(_ payment_id: String, andData response: [AnyHashable : Any]?) {
        print("✅ [RazorpayGateway] Payment Success! Payment ID: \(payment_id)")
        print("✅ [RazorpayGateway] Response Data: \(String(describing: response))")
        
        completion?(.success(response ?? [:]))
        completion = nil
    }
    
    func onPaymentError(_ code: Int32, description str: String, andData response: [AnyHashable : Any]?) {
        print("❌ [RazorpayGateway] Payment Failed! Code: \(code), Description: \(str)")
        print("❌ [RazorpayGateway] Response Data: \(String(describing: response))")
        
        let error = NSError(domain: "RazorpayGateway", code: Int(code), userInfo: [NSLocalizedDescriptionKey: str])
        completion?(.failure(error))
        completion = nil
    }
    
    // MARK: - RazorpayPaymentCompletionProtocol (Fallback)
    
    func onPaymentSuccess(_ payment_id: String) {
        self.onPaymentSuccess(payment_id, andData: [:])
    }
    
    func onPaymentError(_ code: Int32, description str: String) {
        self.onPaymentError(code, description: str, andData: [:])
    }
    
    // MARK: - ExternalWalletSelectionProtocol
    
    func onExternalWalletSelected(_ walletName: String, withPaymentData paymentData: [AnyHashable : Any]?) {
        print("💳 [RazorpayGateway] External Wallet Selected: \(walletName)")
        if let data = paymentData {
            print("💳 [RazorpayGateway] Wallet Data: \(data)")
        }
    }
}
