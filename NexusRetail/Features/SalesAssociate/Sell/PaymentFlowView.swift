import SwiftUI

struct PaymentFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SellViewModel.self) private var viewModel
    @Binding var path: NavigationPath
    
    @State private var paymentState: PaymentState = .initial
    @State private var isProcessing = false
    @State private var progressValue: Double = 0.0
    
    enum PaymentState {
        case initial
        case processing
        case success
        case failed
    }
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Custom Curved Header
                    customHeaderSection
                    
                    VStack(spacing: 32) {
                        if viewModel.selectedPaymentMethod == .razorpay {
                            razorpaySection
                        } else {
                            cardTerminalSection
                        }
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, 40)
                    .padding(.bottom, RSMSSpacing.xxl)
                }
            }
            .ignoresSafeArea(edges: .top)
            
            // Full screen loader overlays
            if isProcessing {
                processingOverlay
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    private var customHeaderSection: some View {
        HStack(alignment: .center, spacing: RSMSSpacing.md) {
            if paymentState != .success {
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 44, height: 44)

                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .accessibilityLabel("Back")
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(viewModel.selectedPaymentMethod == .razorpay ? "Razorpay" : "Card Checkout")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text(viewModel.selectedClient == nil ? "Anonymous Transaction" : "Client: \(viewModel.selectedClient!)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.xxxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(HeaderCurve())
    }
    
    // MARK: - Razorpay Native Simulator UI
    private var razorpaySection: some View {
        VStack(spacing: 24) {
            // Receipt branding details
            VStack(spacing: 6) {
                Text("NEXUS RETAIL")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(RSMSColors.secondaryText)
                    .kerning(1.5)
                
                Text("₹\(Int(viewModel.totalAmount))")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(RSMSColors.burgundy)
                
                Text("Order ID: #\(Int.random(in: 100000...999999))")
                    .font(.system(size: 12))
                    .foregroundColor(RSMSColors.secondaryText)
            }
            .padding(.vertical, 10)
            
            // Razorpay Inner Sheet Mockup
            VStack(alignment: .leading, spacing: 18) {
                // Header
                HStack {
                    Image(systemName: "shield.fill")
                        .foregroundColor(Color.blue)
                    Text("Secure payment via Razorpay")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.blue)
                    Spacer()
                    Text("Razorpay")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(Color(red: 0.08, green: 0.45, blue: 0.89))
                }
                .padding(.bottom, 4)
                
                // UPI Options
                VStack(alignment: .leading, spacing: 12) {
                    Text("UPI (Google Pay, PhonePe, Bhim)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(RSMSColors.secondaryText)
                    
                    HStack(spacing: 12) {
                        upiMethodIcon("gpay", label: "Google Pay")
                        upiMethodIcon("phonepe", label: "PhonePe")
                        upiMethodIcon("paytm", label: "Paytm")
                    }
                }
                
                Divider()
                
                // Other Options
                VStack(alignment: .leading, spacing: 12) {
                    Text("Other Payment Modes")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(RSMSColors.secondaryText)
                    
                    optionRow(icon: "creditcard.fill", title: "Cards (Visa, Mastercard, RuPay)")
                    optionRow(icon: "building.columns.fill", title: "Netbanking")
                    optionRow(icon: "wallet.pass.fill", title: "Wallets")
                }
                
                // Pay Button
                Button {
                    processRazorpayPayment()
                } label: {
                    Text("Pay ₹\(Int(viewModel.totalAmount))")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.08, green: 0.45, blue: 0.89))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(RSMSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(RSMSColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
        }
    }
    
    private func upiMethodIcon(_ name: String, label: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "iphone.circle.fill")
                .foregroundColor(RSMSColors.burgundy)
            Text(label)
                .font(.system(size: 12, weight: .bold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private func optionRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(RSMSColors.secondaryText)
                .frame(width: 20)
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(RSMSColors.primaryText)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundColor(RSMSColors.secondaryText.opacity(0.5))
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Card Terminal Simulator UI
    private var cardTerminalSection: some View {
        VStack(spacing: 36) {
            // Visual Card Terminal Graphic
            VStack(spacing: 20) {
                // Device Screen
                VStack(spacing: 10) {
                    Text("NEXUS PAY")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                        .kerning(2.0)
                    
                    if paymentState == .initial {
                        Text("WAITING FOR CARD...")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.white)
                        
                        Text("Insert, Tap, or Swipe")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("₹\(Int(viewModel.totalAmount))")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(RSMSColors.burgundy)
                    } else if paymentState == .processing {
                        Text("AUTHORIZING...")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.orange)
                        ProgressView()
                            .tint(.white)
                    } else if paymentState == .success {
                        Text("APPROVED")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.green)
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.green)
                    }
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
                .frame(width: 260)
                .background(Color(red: 0.1, green: 0.12, blue: 0.18))
                .cornerRadius(12)
                .shadow(inner: .black.opacity(0.8), radius: 4)
                
                // Keypad graphic representational layout
                VStack(spacing: 8) {
                    HStack(spacing: 12) { keypadNum("1"); keypadNum("2"); keypadNum("3") }
                    HStack(spacing: 12) { keypadNum("4"); keypadNum("5"); keypadNum("6") }
                    HStack(spacing: 12) { keypadNum("7"); keypadNum("8"); keypadNum("9") }
                    HStack(spacing: 12) { keypadAction("X", color: .red); keypadNum("0"); keypadAction("O", color: .green) }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 28)
            .background(Color.gray.opacity(0.12))
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 2)
            )
            .frame(width: 290)
            
            // Tap/Insert Trigger Controls
            if paymentState == .initial {
                VStack(spacing: 12) {
                    Text("Customer Action Required")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(RSMSColors.darkBrown)
                    
                    Button {
                        processCardPayment()
                    } label: {
                        HStack {
                            Image(systemName: "contact.sensor.page.fill")
                            Text("Simulate Card Tap / Swipe")
                        }
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 24)
                        .background(RSMSColors.burgundy)
                        .clipShape(Capsule())
                        .shadow(color: RSMSColors.burgundy.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
    
    private func keypadNum(_ num: String) -> some View {
        Text(num)
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 44, height: 32)
            .background(Color.gray.opacity(0.6))
            .cornerRadius(6)
    }
    
    private func keypadAction(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 14, weight: .black))
            .foregroundColor(.white)
            .frame(width: 44, height: 32)
            .background(color)
            .cornerRadius(6)
    }
    
    // MARK: - Simulation Triggers
    private func processRazorpayPayment() {
        withAnimation {
            isProcessing = true
            paymentState = .processing
        }
        
        // Simulates loading/verification delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation {
                isProcessing = false
                paymentState = .success
            }
            
            // Proceed to Receipt View after a short display of success checkmark
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                path.append(POSFlowDestination.receipt)
            }
        }
    }
    
    private func processCardPayment() {
        withAnimation {
            paymentState = .processing
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation {
                paymentState = .success
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                path.append(POSFlowDestination.receipt)
            }
        }
    }
    
    // MARK: - Loader Overlay
    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                
                Text("Authorizing transaction securely...")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
}
extension View {
    func shadow(inner shadowColor: Color, radius: CGFloat, offset: CGPoint = .zero) -> some View {
        self.overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(shadowColor, lineWidth: radius)
                .blur(radius: radius)
                .offset(x: offset.x, y: offset.y)
                .mask(RoundedRectangle(cornerRadius: 12))
        )
    }
}
