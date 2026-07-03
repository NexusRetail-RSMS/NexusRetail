import SwiftUI
import Supabase

struct CheckoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SellViewModel.self) private var viewModel
    @Environment(SessionStore.self) private var sessionStore
    @Binding var path: NavigationPath

    // Clients loaded from DB
    @State private var clients: [ClientRow] = []
    @State private var clientSelection: String = "Skip"   // "Skip" or client.id.uuidString
    @State private var selectedPayment: POSPaymentMethod = .razorpay

    struct ClientRow: Decodable, Identifiable {
        let id: UUID
        let name: String
    }

    var body: some View {
        ZStack {
            RSMSColors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    customHeaderSection

                    VStack(alignment: .leading, spacing: 24) {

                        // 1. Order Summary
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Order Summary")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(RSMSColors.darkBrown)

                            VStack(spacing: 0) {
                                ForEach(groupedItems, id: \.product.id) { item in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.product.name)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(RSMSColors.primaryText)
                                            Text("Qty: \(item.count) × \(formatIndianCurrency(item.product.price))")
                                                .font(.system(size: 11))
                                                .foregroundColor(RSMSColors.secondaryText)
                                        }
                                        Spacer()
                                        Text(formatIndianCurrency(item.product.price * Double(item.count)))
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(RSMSColors.primaryText)
                                    }
                                    .padding(.vertical, 12)

                                    if item.product != groupedItems.last?.product { Divider() }
                                }
                            }
                            .padding(.horizontal, 16)
                            .background(RSMSColors.cardBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSColors.cardBorder, lineWidth: 1))
                        }

                        // 2. Customer Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Customer Link")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(RSMSColors.darkBrown)

                            VStack(spacing: 12) {
                                Picker("Customer", selection: $clientSelection) {
                                    Text("Anonymous / Skip").tag("Skip")
                                    ForEach(clients) { client in
                                        Text(client.name).tag(client.id.uuidString)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(RSMSColors.burgundy)

                                if clientSelection != "Skip" {
                                    let name = clients.first(where: { $0.id.uuidString == clientSelection })?.name ?? ""
                                    HStack {
                                        Image(systemName: "person.crop.circle.badge.checkmark").foregroundColor(RSMSColors.success)
                                        Text("Attached client: \(name)")
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
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSColors.cardBorder, lineWidth: 1))
                        }

                        // 3. Payment Method
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Payment Method")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(RSMSColors.darkBrown)

                            VStack(spacing: 12) {
                                paymentOptionRow(method: .razorpay, title: "Razorpay (UPI / Cards / Wallets)", icon: "creditcard.and.123", selected: selectedPayment == .razorpay)
                                paymentOptionRow(method: .cardTerminal, title: "Card Terminal (Tap / Swipe / Chip)", icon: "macbook.and.iphone", selected: selectedPayment == .cardTerminal)
                            }
                        }

                        // Pay Button
                        Button {
                            // Store chosen client
                            if clientSelection == "Skip" {
                                viewModel.selectedClient = nil
                                viewModel.selectedClientId = nil
                            } else {
                                viewModel.selectedClient = clients.first(where: { $0.id.uuidString == clientSelection })?.name
                                viewModel.selectedClientId = UUID(uuidString: clientSelection)
                            }
                            viewModel.selectedPaymentMethod = selectedPayment
                            path.append(POSFlowDestination.payment)
                        } label: {
                            HStack {
                                Text("Pay \(formatIndianCurrency(viewModel.totalAmount))").font(.system(size: 16, weight: .bold))
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
        .task {
            // Load clients from DB for the current associate
            if let userId = sessionStore.currentUser?.id {
                let rows: [ClientRow] = (try? await SupabaseManager.shared.client
                    .from("client")
                    .select("id, name")
                    .eq("created_by", value: userId)
                    .order("name")
                    .execute()
                    .value) ?? []
                clients = rows
            }
        }
    }

    private var customHeaderSection: some View {
        HStack(alignment: .center, spacing: RSMSSpacing.md) {
            Button { dismiss() } label: {
                ZStack {
                    Circle().fill(Color.white.opacity(0.2)).frame(width: 44, height: 44)
                    Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                }
            }
            .accessibilityLabel("Back")

            VStack(alignment: .leading, spacing: 2) {
                Text("Checkout").font(.system(size: 24, weight: .bold)).foregroundColor(.white)
                Text("Finalize & Authorize Payment").font(.system(size: 14, weight: .medium)).foregroundColor(.white.opacity(0.8))
            }
            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 60)
        .padding(.bottom, RSMSSpacing.xxxl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [RSMSColors.burgundy, RSMSColors.darkBurgundy], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(HeaderCurve())
    }

    private func paymentOptionRow(method: POSPaymentMethod, title: String, icon: String, selected: Bool) -> some View {
        Button {
            withAnimation { selectedPayment = method }
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
                Text(title).font(.system(size: 14, weight: .semibold, design: .rounded)).foregroundColor(RSMSColors.primaryText)
                Spacer()
                ZStack {
                    Circle().stroke(selected ? RSMSColors.burgundy : Color.gray.opacity(0.4), lineWidth: 2).frame(width: 20, height: 20)
                    if selected { Circle().fill(RSMSColors.burgundy).frame(width: 10, height: 10) }
                }
            }
            .padding(16)
            .background(RSMSColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? RSMSColors.burgundy : RSMSColors.cardBorder, lineWidth: 1))
            .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }


    
    private var groupedItems: [(product: POSProduct, count: Int)] {
        var counts: [UUID: Int] = [:]
        var uniqueProducts: [POSProduct] = []
        for item in viewModel.cartItems {
            if counts[item.id] == nil { uniqueProducts.append(item); counts[item.id] = 1 }
            else { counts[item.id]! += 1 }
        }
        return uniqueProducts.map { ($0, counts[$0.id] ?? 1) }
    }
}
