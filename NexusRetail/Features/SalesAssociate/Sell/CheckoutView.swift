import SwiftUI
import Supabase

struct CheckoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(SellViewModel.self) private var viewModel
    @Environment(SessionStore.self) private var sessionStore
    @Binding var path: NavigationPath

    @State private var selectedPayment: POSPaymentMethod = .razorpay

    // Phone-first customer linking
    enum LookupState: Equatable {
        case idle
        case searching
        case found(name: String)
        case notFound
    }
    @State private var phoneText: String = ""
    @State private var newClientName: String = ""
    @State private var lookupState: LookupState = .idle
    @State private var isCreatingClient = false

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

                        // 2. Customer Link (phone-first)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Customer Link")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(RSMSColors.darkBrown)

                            customerLinkCard
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
                            // Customer link is already resolved into viewModel
                            // (selectedClientId/selectedClient) as the user looks
                            // up or creates the client above.
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
        .toolbar(.hidden, for: .tabBar)
    }

    // MARK: - Customer Link (phone-first lookup / quick-create)
    private var customerLinkCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Phone entry + lookup
            HStack(spacing: 10) {
                Image(systemName: "phone.fill")
                    .font(.system(size: 14))
                    .foregroundColor(RSMSColors.secondaryText)
                TextField("Customer phone number", text: $phoneText)
                    .keyboardType(.phonePad)
                    .font(.system(size: 15))
                    .onChange(of: phoneText) { _, _ in
                        // Any edit invalidates a prior match so nothing stale lingers.
                        if lookupState != .idle {
                            lookupState = .idle
                            clearAttachedClient()
                        }
                    }
                    .onSubmit { lookUpPhone() }

                Button { lookUpPhone() } label: {
                    if lookupState == .searching {
                        ProgressView().tint(RSMSColors.burgundy)
                    } else {
                        Text("Look up").font(.system(size: 14, weight: .bold))
                    }
                }
                .foregroundColor(RSMSColors.burgundy)
                .disabled(phoneText.filter(\.isNumber).count < 6 || lookupState == .searching)
            }
            .padding(12)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSColors.inputBorder, lineWidth: 1))

            switch lookupState {
            case .found(let name):
                HStack {
                    Image(systemName: "person.crop.circle.badge.checkmark").foregroundColor(RSMSColors.success)
                    Text("Attached: \(name)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(RSMSColors.success)
                    Spacer()
                    Button("Change") { resetLookup() }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(RSMSColors.burgundy)
                }
                .padding(10)
                .background(RSMSColors.success.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            case .notFound:
                VStack(alignment: .leading, spacing: 10) {
                    Text("No customer found with this number. Add a new one:")
                        .font(.system(size: 12))
                        .foregroundColor(RSMSColors.secondaryText)
                    TextField("Full name", text: $newClientName)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                        .font(.system(size: 15))
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSColors.inputBorder, lineWidth: 1))

                    Button { createAndAttach() } label: {
                        HStack {
                            if isCreatingClient { ProgressView().tint(.white) }
                            Text(isCreatingClient ? "Creating…" : "Create & Attach")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(canCreateClient ? RSMSColors.burgundy : RSMSColors.disabled)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canCreateClient || isCreatingClient)
                }

            case .idle, .searching:
                Text("Look up a customer by phone to attach them, or continue anonymously.")
                    .font(.system(size: 12))
                    .foregroundColor(RSMSColors.secondaryText)
            }

            // Skip / Anonymous
            if viewModel.selectedClientId != nil || lookupState != .idle {
                Button { resetLookup() } label: {
                    Text("Continue as Anonymous / Skip")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(RSMSColors.secondaryText)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RSMSColors.cardBorder, lineWidth: 1))
    }

    private var canCreateClient: Bool {
        !newClientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        phoneText.filter(\.isNumber).count >= 6
    }

    private func lookUpPhone() {
        guard phoneText.filter(\.isNumber).count >= 6 else { return }
        lookupState = .searching
        clearAttachedClient()
        Task {
            let result = await viewModel.findClient(byPhone: phoneText)
            await MainActor.run {
                if let result {
                    viewModel.selectedClientId = result.id
                    viewModel.selectedClient = result.name
                    lookupState = .found(name: result.name)
                } else {
                    lookupState = .notFound
                }
            }
        }
    }

    private func createAndAttach() {
        let name = newClientName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard canCreateClient else { return }
        isCreatingClient = true
        Task {
            do {
                let newId = try await viewModel.createClient(
                    name: name,
                    phone: phoneText,
                    createdBy: sessionStore.currentUser?.id
                )
                await MainActor.run {
                    viewModel.selectedClientId = newId
                    viewModel.selectedClient = name
                    lookupState = .found(name: name)
                    isCreatingClient = false
                }
            } catch {
                print("CheckoutView: createClient failed: \(error)")
                await MainActor.run { isCreatingClient = false }
            }
        }
    }

    private func resetLookup() {
        phoneText = ""
        newClientName = ""
        lookupState = .idle
        clearAttachedClient()
    }

    private func clearAttachedClient() {
        viewModel.selectedClient = nil
        viewModel.selectedClientId = nil
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
