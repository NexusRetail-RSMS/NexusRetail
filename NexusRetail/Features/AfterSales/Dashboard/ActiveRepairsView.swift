import SwiftUI
import Supabase

struct ActiveRepairsView: View {
    @Environment(SessionStore.self) private var sessionStore
    
    @State private var repairOrders: [RepairOrderViewModel] = []
    @State private var isLoading = true
    
    struct RepairOrderViewModel: Identifiable {
        let id: UUID
        let customerName: String
        let itemName: String
        let itemSKU: String
        let itemImageURL: String?
        let pickupDate: Date
        let problemDescription: String?
    }
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            if isLoading {
                ProgressView("Loading Repairs...")
                    .tint(RSMSColors.burgundy)
            } else if repairOrders.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "wrench.and.screwdriver.fill")
                        .font(.system(size: 48))
                        .foregroundColor(RSMSColors.secondaryText)
                    Text("No Active Repairs")
                        .font(RSMSFonts.title)
                        .foregroundColor(RSMSColors.primaryText)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(repairOrders) { repair in
                            NavigationLink(destination: RepairOrderDetailsView(repair: repair)) {
                                RepairCardView(
                                    customerName: repair.customerName,
                                    customerImageURL: nil, // Add if supported in backend later
                                    itemImageURL: repair.itemImageURL,
                                    itemName: repair.itemName,
                                    itemSKU: repair.itemSKU,
                                    pickupDate: repair.pickupDate
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(16)
                }
            }
        }
        .onAppear {
            Task {
                await fetchRepairOrders()
            }
        }
    }
    
    private func fetchRepairOrders() async {
        do {
            isLoading = true
            
            let query = SupabaseManager.shared.client
                .from("orders")
                .select("id, total, created_at, store_id, client_id, client(name, phone), order_line_item(id, quantity, applied_price, products(item_id, item_name, category, sku_code, price, pexels_page, image_url))")
            
            let orders: [StoreOrder] = try await query
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value
            
            var fetchedRepairs: [RepairOrderViewModel] = []
            
            for order in orders {
                // Determine if it's a repair by checking our local manager
                // Since processCheckout creates line items referencing the original product (and doesn't natively tag it as Service),
                // we rely on the UUID being captured at submission time.
                if !RepairOrderManager.shared.isRepairOrder(order.id) { continue }
                
                let serviceItems = order.orderLineItems ?? []
                
                // If it's a repair, we just grab the first item to display on the card
                if let firstItem = serviceItems.first, let product = firstItem.products {
                    let pickupDate = RepairOrderManager.shared.getPickupDate(forOrderId: order.id) ?? fallbackPickupDate(from: order.createdAt)
                    
                    let customerName = order.client?.name ?? "Customer (Unlinked Invoice)"
                    let problemDesc = RepairOrderManager.shared.getProblemDescription(forOrderId: order.id)
                    
                    let vm = RepairOrderViewModel(
                        id: order.id,
                        customerName: customerName,
                        itemName: product.itemName ?? "Unknown Item",
                        itemSKU: product.skuCode ?? "N/A",
                        itemImageURL: product.imageUrl,
                        pickupDate: pickupDate,
                        problemDescription: problemDesc
                    )
                    
                    fetchedRepairs.append(vm)
                }
            }
            
            await MainActor.run {
                self.repairOrders = fetchedRepairs
                self.isLoading = false
            }
            
        } catch {
            print("Failed to fetch repairs: \(error)")
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func fallbackPickupDate(from createdAtString: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = formatter.date(from: createdAtString) ?? Date()
        return Calendar.current.date(byAdding: .day, value: 7, to: date) ?? Date()
    }
}
