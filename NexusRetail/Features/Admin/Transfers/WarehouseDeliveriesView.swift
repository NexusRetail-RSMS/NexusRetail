import SwiftUI

struct ActiveDeliveriesSection: View {
    @Environment(AdminTransfersViewModel.self) private var viewModel
    
    var activeDeliveries: [AdminDelivery] {
        viewModel.deliveries.filter { $0.status != .delivered }.sorted { $0.dispatchDate > $1.dispatchDate }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Active Deliveries")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            if activeDeliveries.isEmpty {
                Text("No active deliveries")
                    .foregroundColor(.secondary)
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(delivery.id)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(delivery.destinationStoreName)
                        .font(.headline)
                }
                
                Spacer()
                
                Text(delivery.status.rawValue)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(delivery.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(delivery.status.color.opacity(0.1))
                    .cornerRadius(8)
            }
            
            HStack(spacing: 16) {
                // Route Indicator
                HStack(spacing: 4) {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(.secondary)
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Image(systemName: "storefront.fill")
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Qty: \(delivery.quantity)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    
                    Text("Est: \(delivery.estimatedArrival.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
        )
    }
}

struct DeliveryDetailView: View {
    let delivery: AdminDelivery
    @Environment(AdminTransfersViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    
    // Derived property to make sure we have the latest status
    var currentDelivery: AdminDelivery {
        viewModel.deliveries.first(where: { $0.id == delivery.id }) ?? delivery
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Status Header
                VStack(spacing: 8) {
                    Text(currentDelivery.status.rawValue)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(currentDelivery.status.color)
                    
                    Text("ID: \(currentDelivery.id)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)
                
                // Timeline
                DeliveryTimelineView(status: currentDelivery.status)
                    .padding(.horizontal)
                
                // Details Card
                VStack(alignment: .leading, spacing: 16) {
                    DetailRow(title: "Destination", value: currentDelivery.destinationStoreName)
                    DetailRow(title: "Manager", value: currentDelivery.managerName)
                    
                    if let product = viewModel.product(for: currentDelivery.productID) {
                        DetailRow(title: "Product", value: product.name)
                    }
                    DetailRow(title: "Quantity", value: "\(currentDelivery.quantity)")
                    
                    if let tracking = currentDelivery.trackingNumber {
                        DetailRow(title: "Tracking", value: tracking)
                    }
                    
                    DetailRow(title: "Dispatch Date", value: currentDelivery.dispatchDate.formatted(date: .abbreviated, time: .omitted))
                    DetailRow(title: "Est. Arrival", value: currentDelivery.estimatedArrival.formatted(date: .abbreviated, time: .omitted))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                // Simulate Button
                if currentDelivery.status == .inTransit {
                    Button {
                        withAnimation {
                            viewModel.simulateStoreDelivery(for: currentDelivery)
                        }
                    } label: {
                        Text("Simulate Delivery")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.nexusDark)
                            .foregroundColor(Color.nexusBackground)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 30)
        }
        .background(Color.nexusBackground)
        .navigationTitle("Delivery Details")
        .navigationBarTitleDisplayMode(.inline)
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
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
                Circle()
                    .fill(isCompleted ? Color.nexusRed : Color.gray.opacity(0.3))
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? Color.nexusRed : Color.gray.opacity(0.3))
                        .frame(width: 2, height: 30)
                }
            }
            
            Text(title)
                .font(.subheadline)
                .fontWeight(isCompleted ? .bold : .regular)
                .foregroundColor(isCompleted ? .primary : .secondary)
                .padding(.top, -2)
            
            Spacer()
        }
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
}
