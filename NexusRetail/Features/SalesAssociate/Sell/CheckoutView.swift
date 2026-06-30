import SwiftUI

struct CheckoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SellViewModel.self) private var viewModel
    @Binding var path: NavigationPath
    
    // Simple clients list matching clienteling data
    let clients = ["Ananya Rao", "Kabir Mehta", "Mira Kapoor"]
    
    @State private var clientSelection: String = "Skip"
    @State private var selectedPayment: POSPaymentMethod = .razorpay
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Custom Curved Header
                    customHeaderSection
                    
                    VStack(alignment: .leading, spacing: 24) {
                        // 1. Order Summary
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Order Summary")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(RSMSColors.darkBrown)
                            
                            VStack(spacing: 0) {
                                ForEach(viewModel.cartItems) { item in
                                    HStack {
                                        Text(item.name)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(RSMSColors.primaryText)
                                        
                                        Spacer()
                                        
                                        Text("$\(String(format: "%.2f", item.price))")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(RSMSColors.primaryText)
                                    }
                                    .padding(.vertical, 12)
                                    
                                    if item != viewModel.cartItems.last {
                                        Divider()
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .background(RSMSColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(RSMSColors.cardBorder, lineWidth: 1)
                            )
                        }
                        
                        // 2. Customer Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Customer Link")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(RSMSColors.darkBrown)
                            
                            VStack(spacing: 12) {
                                Picker("Customer", selection: $clientSelection) {
                                    Text("Anonymous / Skip").tag("Skip")
                                    ForEach(clients, id: \.self) { client in
                                        Text(client).tag(client)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(RSMSColors.burgundy)
                                
                                if clientSelection != "Skip" {
                                    HStack {
                                        Image(systemName: "person.crop.circle.badge.checkmark")
                                            .foregroundColor(RSMSColors.success)
                                        Text("Attached client: \(clientSelection)")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(RSMSColors.success)
                                        Spacer()
                                    }
                                    .padding(10)
                                    .background(RSMSColors.success.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RSMSColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(RSMSColors.cardBorder, lineWidth: 1)
                            )
                        }
                        
                        // 3. Payment Method Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Payment Method")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(RSMSColors.darkBrown)
                            
                            VStack(spacing: 12) {
                                // Razorpay Choice
                                paymentOptionRow(
                                    method: .razorpay,
                                    title: "Razorpay (UPI / Cards / Wallets)",
                                    icon: "creditcard.and.123",
                                    selected: selectedPayment == .razorpay
                                )
                                
                                // Card Terminal Choice
                                paymentOptionRow(
                                    method: .cardTerminal,
                                    title: "Card Terminal (Tap / Swipe / Chip)",
                                    icon: "macbook.and.iphone", // looks like POS/payment terminal
                                    selected: selectedPayment == .cardTerminal
                                )
                            }
                        }
                        
                        // Pay Button
                        Button {
                            // Save choices to ViewModel and navigate
                            viewModel.selectedClient = clientSelection == "Skip" ? nil : clientSelection
                            viewModel.selectedPaymentMethod = selectedPayment
                            path.append(POSFlowDestination.payment)
                        } label: {
                            HStack {
                                Text("Pay $\(String(format: "%.2f", viewModel.totalAmount))")
                                    .font(.system(size: 16, weight: .bold))
                                Spacer()
                                Image(systemName: "lock.fill")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(RSMSColors.burgundy)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: RSMSColors.burgundy.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, RSMSSpacing.lg)
                    .padding(.top, RSMSSpacing.xl)
                    .padding(.bottom, RSMSSpacing.xxl)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header
    private var customHeaderSection: some View {
        HStack(alignment: .center, spacing: RSMSSpacing.md) {
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
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Checkout")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Finalize & Authorize Payment")
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
    
    private func paymentOptionRow(method: POSPaymentMethod, title: String, icon: String, selected: Bool) -> some View {
        Button {
            withAnimation {
                selectedPayment = method
            }
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(selected ? RSMSColors.burgundy.opacity(0.1) : Color.gray.opacity(0.08))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(selected ? RSMSColors.burgundy : RSMSColors.secondaryText)
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(RSMSColors.primaryText)
                
                Spacer()
                
                // Radio Circle
                ZStack {
                    Circle()
                        .stroke(selected ? RSMSColors.burgundy : Color.gray.opacity(0.4), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if selected {
                        Circle()
                            .fill(RSMSColors.burgundy)
                            .frame(width: 10, height: 10)
                    }
                }
            }
            .padding(16)
            .background(RSMSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? RSMSColors.burgundy : RSMSColors.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
