import SwiftUI

struct TransferRequestCard: View {
    let request: AdminStockRequest

    @Environment(AdminTransfersViewModel.self) private var viewModel
    @Environment(AdminNavigationStore.self) private var navStore

    @State private var showingDenialAlert = false
    @State private var denialReason = ""
    @State private var showingPurchaseOrderSheet = false
    @State private var isPressed = false

    var body: some View {
        let product = viewModel.product(for: request.productID)
        let manager = viewModel.manager(for: request.managerID)
        let store = viewModel.store(for: request.storeID)

        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.nexusRed, Color.nexusRed.opacity(0.72)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 46, height: 46)

                    Text(initials(for: manager?.name ?? "?"))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .shadow(color: Color.nexusRed.opacity(0.3), radius: 8, x: 0, y: 4)

                VStack(alignment: .leading, spacing: 3) {
                    Text(manager?.name ?? "Unknown Manager")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    HStack(spacing: 4) {
                        Image(systemName: "storefront.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(store?.name ?? "Unknown Store")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 6) {
                    StatusBadge(status: request.status)
                    PriorityBadge(priority: request.priority)
                }
            }

            LinearGradient(
                colors: [Color.gray.opacity(0.16), Color.gray.opacity(0.03)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 1)

            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.nexusRed.opacity(0.12), Color.nexusRed.opacity(0.04)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 17))
                            .foregroundColor(Color.nexusRed)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(product?.name ?? "Unknown Item")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(product?.category ?? "Category")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(request.id)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.gray.opacity(0.08)))
            }

            HStack(spacing: 0) {
                stockStat(
                    label: "Requested",
                    value: "\(request.requestedQuantity)",
                    color: .primary
                )

                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 1, height: 38)

                let available = product?.warehouseQuantity ?? 0
                stockStat(
                    label: "Available",
                    value: "\(available)",
                    color: available >= request.requestedQuantity ? .green : .red
                )
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.045))
            )

            if request.status == .pending || request.status == .awaitingRestock {
                let isSufficient = (product?.warehouseQuantity ?? 0) >= request.requestedQuantity

                HStack(spacing: 12) {
                    if isSufficient {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                viewModel.approveRequest(request)
                            }
                        } label: {
                            Label("Approve", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 15, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [Color.nexusRed, Color.nexusRed.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(15)
                                .shadow(color: Color.nexusRed.opacity(0.32), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(PressableButtonStyle())
                    } else {
                        Button {
                            showingPurchaseOrderSheet = true
                        } label: {
                            Label("Purchase Order", systemImage: "cart.fill.badge.plus")
                                .font(.system(size: 15, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(
                                    LinearGradient(
                                        colors: [Color.nexusRed, Color.nexusRed.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(15)
                                .shadow(color: Color.nexusRed.opacity(0.32), radius: 10, x: 0, y: 5)
                        }
                        .buttonStyle(PressableButtonStyle())
                    }

                    Button {
                        showingDenialAlert = true
                    } label: {
                        Label("Deny", systemImage: "xmark.circle")
                            .font(.system(size: 15, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.nexusRed.opacity(0.07))
                            .foregroundColor(Color.nexusRed)
                            .overlay(
                                RoundedRectangle(cornerRadius: 15)
                                    .stroke(Color.nexusRed.opacity(0.18), lineWidth: 1)
                            )
                            .cornerRadius(15)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .padding(.top, 4)
            }

            if let reason = request.denialReason {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.06)))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.97)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color.black.opacity(0.07), radius: 16, x: 0, y: 8)
                .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.black.opacity(0.045), lineWidth: 1)
        )
        .alert("Deny Request", isPresented: $showingDenialAlert) {
            TextField("Reason (optional)", text: $denialReason)
            Button("Cancel", role: .cancel) { }
            Button("Deny", role: .destructive) {
                withAnimation {
                    viewModel.denyRequest(request, reason: denialReason.isEmpty ? "No stock available" : denialReason)
                }
            }
        } message: {
            Text("Are you sure you want to deny this transfer request?")
        }
        .sheet(isPresented: $showingPurchaseOrderSheet) {
            if let product = product {
                PurchaseOrderSheet(product: product, suggestedQuantity: request.requestedQuantity * 2, initialRequest: request)
            }
        }
    }

    @ViewBuilder
    private func stockStat(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .tracking(0.6)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, label == "Requested" ? 0 : 14)
    }

    private func initials(for name: String) -> String {
        let parts = name.split(separator: " ")
        let chars = parts.prefix(2).compactMap { $0.first }
        return String(chars).uppercased()
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .opacity(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct StatusBadge: View {
    let status: TransferRequestStatus
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)
            Text(status.rawValue)
                .font(.caption)
                .fontWeight(.bold)
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(status.color.opacity(0.1))
        .overlay(Capsule().stroke(status.color.opacity(0.18), lineWidth: 1))
        .clipShape(Capsule())
    }
}

struct PriorityBadge: View {
    let priority: RequestPriority
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flag.fill")
                .font(.system(size: 9))
            Text(priority.rawValue)
        }
        .font(.caption2)
        .fontWeight(.bold)
        .foregroundColor(priority.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(priority.color.opacity(0.1))
        .clipShape(Capsule())
    }
}
