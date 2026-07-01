import SwiftUI

struct ActiveDeliveriesSection: View {
    @Environment(AdminTransfersViewModel.self) private var viewModel

    var activeDeliveries: [AdminDelivery] {
        viewModel.deliveries.filter { $0.status != .delivered }.sorted { $0.dispatchDate > $1.dispatchDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Active Deliveries")
                    .font(.system(size: 20, weight: .bold, design: .rounded))

                if !activeDeliveries.isEmpty {
                    Text("\(activeDeliveries.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.nexusRed)
                        .clipShape(Capsule())
                }

                Spacer()
            }
            .padding(.horizontal)

            if activeDeliveries.isEmpty {
                VStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.07))
                            .frame(width: 76, height: 76)
                        Image(systemName: "shippingbox")
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(.gray.opacity(0.7))
                    }
                    Text("No active deliveries")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .padding(.horizontal)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(activeDeliveries) { delivery in
                        NavigationLink(destination: DeliveryDetailView(delivery: delivery)) {
                            DeliveryCard(delivery: delivery)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct DeliveryCard: View {
    let delivery: AdminDelivery

    private var progress: CGFloat {
        switch delivery.status {
        case .preparing: return 0.15
        case .dispatched: return 0.45
        case .inTransit: return 0.8
        case .delivered: return 1.0
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(delivery.id)
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.09))
                        .clipShape(Capsule())

                    Text(delivery.destinationStoreName)
                        .font(.system(size: 16.5, weight: .bold))
                }

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(delivery.status.color)
                        .frame(width: 6, height: 6)
                    Text(delivery.status.rawValue)
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .foregroundColor(delivery.status.color)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(delivery.status.color.opacity(0.1))
                .overlay(Capsule().stroke(delivery.status.color.opacity(0.18), lineWidth: 1))
                .clipShape(Capsule())
            }

            HStack(spacing: 8) {
                Image(systemName: "building.2.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.11))
                            .frame(height: 4)

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [delivery.status.color.opacity(0.6), delivery.status.color],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * progress, height: 4)

                        Image(systemName: "shippingbox.fill")
                            .font(.system(size: 11))
                            .foregroundColor(delivery.status.color)
                            .padding(3)
                            .background(Circle().fill(Color.white))
                            .shadow(color: Color.black.opacity(0.18), radius: 3, x: 0, y: 1)
                            .offset(x: max(geo.size.width * progress - 9, 0))
                    }
                }
                .frame(height: 16)

                Image(systemName: "storefront.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
            }

            HStack {
                Label("Qty \(delivery.quantity)", systemImage: "cube.box.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()

                Label(delivery.estimatedArrival.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 5)
                .shadow(color: Color.black.opacity(0.03), radius: 1, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.045), lineWidth: 1)
        )
    }
}

struct DeliveryDetailView: View {
    let delivery: AdminDelivery
    @Environment(AdminTransfersViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    var currentDelivery: AdminDelivery {
        viewModel.deliveries.first(where: { $0.id == delivery.id }) ?? delivery
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(currentDelivery.status.color.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Circle()
                            .stroke(currentDelivery.status.color.opacity(0.2), lineWidth: 1)
                            .frame(width: 80, height: 80)

                        Image(systemName: statusIcon(for: currentDelivery.status))
                            .font(.system(size: 30))
                            .foregroundColor(currentDelivery.status.color)
                    }
                    .shadow(color: currentDelivery.status.color.opacity(0.2), radius: 14, x: 0, y: 6)

                    Text(currentDelivery.status.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(currentDelivery.status.color)

                    Text("ID: \(currentDelivery.id)")
                        .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(Color.gray.opacity(0.09))
                        .clipShape(Capsule())
                }
                .padding(.top)

                DeliveryTimelineView(status: currentDelivery.status)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 16) {
                    DetailRow(title: "Destination", value: currentDelivery.destinationStoreName, icon: "storefront.fill")
                    DetailRow(title: "Manager", value: currentDelivery.managerName, icon: "person.fill")

                    if let product = viewModel.product(for: currentDelivery.productID) {
                        DetailRow(title: "Product", value: product.name, icon: "shippingbox.fill")
                    }
                    DetailRow(title: "Quantity", value: "\(currentDelivery.quantity)", icon: "cube.box.fill")

                    if let tracking = currentDelivery.trackingNumber {
                        DetailRow(title: "Tracking", value: tracking, icon: "barcode")
                    }

                    DetailRow(title: "Dispatch Date", value: currentDelivery.dispatchDate.formatted(date: .abbreviated, time: .omitted), icon: "calendar.badge.clock")
                    DetailRow(title: "Est. Arrival", value: currentDelivery.estimatedArrival.formatted(date: .abbreviated, time: .omitted), icon: "calendar")
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.black.opacity(0.045), lineWidth: 1)
                )
                .padding(.horizontal)

                if currentDelivery.status == .inTransit {
                    Button {
                        withAnimation {
                            viewModel.simulateStoreDelivery(for: currentDelivery)
                        }
                    } label: {
                        Label("Simulate Delivery", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.nexusDark, Color.nexusDark.opacity(0.85)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(Color.nexusBackground)
                            .cornerRadius(16)
                            .shadow(color: Color.nexusDark.opacity(0.28), radius: 12, x: 0, y: 6)
                    }
                    .buttonStyle(PressableButtonStyle())
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 30)
        }
        .background(Color.nexusBackground)
        .navigationTitle("Delivery Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func statusIcon(for status: DeliveryStatus) -> String {
        switch status {
        case .preparing: return "shippingbox.fill"
        case .dispatched: return "arrow.up.bin.fill"
        case .inTransit: return "shippingbox.and.arrow.backward.fill"
        case .delivered: return "checkmark.seal.fill"
        }
    }
}

struct DeliveryTimelineView: View {
    let status: DeliveryStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TimelineStep(title: "Preparing", isCompleted: true, isLast: false)
            TimelineStep(title: "Dispatched", isCompleted: status != .preparing, isLast: false)
            TimelineStep(title: "In Transit", isCompleted: status == .inTransit || status == .delivered, isLast: false)
            TimelineStep(title: "Delivered", isCompleted: status == .delivered, isLast: true)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.black.opacity(0.045), lineWidth: 1)
        )
    }
}

struct TimelineStep: View {
    let title: String
    let isCompleted: Bool
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                ZStack {
                    if isCompleted {
                        Circle()
                            .fill(Color.nexusRed.opacity(0.15))
                            .frame(width: 24, height: 24)
                    }
                    Circle()
                        .fill(isCompleted ? Color.nexusRed : Color.gray.opacity(0.3))
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle().stroke(Color.white, lineWidth: 2)
                        )
                }
                .frame(width: 24, height: 24)

                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? Color.nexusRed : Color.gray.opacity(0.25))
                        .frame(width: 2, height: 28)
                }
            }

            Text(title)
                .font(.subheadline)
                .fontWeight(isCompleted ? .bold : .regular)
                .foregroundColor(isCompleted ? .primary : .secondary)
                .padding(.top, 3)

            Spacer()

            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color.nexusRed)
                    .padding(.top, 3)
            }
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    var icon: String? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .frame(width: 18)
                    .padding(.top, 1)
            }

            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: icon != nil ? 84 : 100, alignment: .leading)

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)

            Spacer()
        }
    }
}
