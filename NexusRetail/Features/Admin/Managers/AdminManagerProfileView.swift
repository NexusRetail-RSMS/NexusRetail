import SwiftUI

struct AdminManagerProfileView: View {
    let manager: AdminTransferManager
    @Environment(AdminTransfersViewModel.self) private var viewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.nexusRed.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Text(manager.avatarInitials)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.nexusRed)
                    }
                    
                    Text(manager.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(manager.storeName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 24)
                
                // Contact Info Card
                VStack(spacing: 0) {
                    ContactRow(icon: "envelope.fill", text: manager.email)
                    Divider().padding(.leading, 48)
                    ContactRow(icon: "phone.fill", text: manager.phone)
                }
                .background(Color.nexusBackground)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Stats Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatCard(title: "Total Requests", value: "\(manager.totalRequests)", icon: "doc.text.fill", color: .nexusRed)
                    StatCard(title: "Approved", value: "\(manager.approvedRequests)", icon: "checkmark.circle.fill", color: .green)
                    StatCard(title: "Pending", value: "\(manager.pendingRequests)", icon: "clock.fill", color: .orange)
                }
                .padding(.horizontal)
                
                // Recent Activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Stock Requests")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    let recentRequests = viewModel.requests.filter { $0.managerID == manager.id }.sorted { $0.requestDate > $1.requestDate }
                    
                    if recentRequests.isEmpty {
                        Text("No recent requests")
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    } else {
                        ForEach(recentRequests) { request in
                            let product = viewModel.product(for: request.productID)
                            ManagerRequestRow(request: request, productName: product?.name ?? "Unknown")
                        }
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .navigationTitle(manager.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ContactRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.nexusGold)
                .frame(width: 24)
            
            Text(text)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding()
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.nexusBackground)
        .cornerRadius(12)
    }
}

struct ManagerRequestRow: View {
    let request: AdminStockRequest
    let productName: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(productName)
                    .font(.headline)
                Text("\(request.requestedQuantity) units • \(request.requestDate.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(request.status.rawValue)
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(request.status.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(request.status.color.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color.nexusBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
