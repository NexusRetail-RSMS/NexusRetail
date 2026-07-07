import SwiftUI
import Supabase

struct ActiveRepairsView: View {
    @Environment(SessionStore.self) private var sessionStore
    
    @State private var repairOrders: [RepairOrderViewModel] = []
    @State private var isLoading = true
    
    struct RepairOrderViewModel: Identifiable {
        let id: UUID
        let customerName: String
        let customerTier: String
        let itemName: String
        let itemSKU: String
        let itemImageURL: String?
        let pickupDate: Date
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
                            RepairCardView(
                                customerName: repair.customerName,
                                customerTier: repair.customerTier,
                                customerImageURL: nil, // Add if supported in backend later
                                itemImageURL: repair.itemImageURL,
                                itemName: repair.itemName,
                                itemSKU: repair.itemSKU,
                                pickupDate: repair.pickupDate
                            )
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
            
            // Ensure we use the current user's store
            let storeID = sessionStore.currentUser?.storeID
            
            var query = SupabaseManager.shared.client
                .from("orders")
                .select("id, total, created_at, store_id, client(name, phone), order_line_item(id, quantity, applied_price, products(item_id, item_name, category, sku_code, price, pexels_page, image_url))")
                
            if let storeID = storeID {
                query = query.eq("store_id", value: storeID)
            }
            
            let orders: [StoreOrder] = try await query
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value
            
            var fetchedRepairs: [RepairOrderViewModel] = []
            
            for order in orders {
                // Check if any order line item is a "Service"
                let serviceItems = order.orderLineItems?.filter { item in
                    item.products?.category == "Service" || item.products?.itemName?.hasPrefix("Repair:") == true
                } ?? []
                
                for serviceItem in serviceItems {
                    guard let product = serviceItem.products else { continue }
                    
                    // Retrieve pickup date from local manager or fallback to +7 days
                    let pickupDate = RepairOrderManager.shared.getPickupDate(forOrderId: order.id) ?? fallbackPickupDate(from: order.createdAt)
                    
                    let vm = RepairOrderViewModel(
                        id: order.id,
                        customerName: order.client?.name ?? "Unknown Customer",
                        customerTier: "Luxe Luxury",
                        itemName: product.itemName?.replacingOccurrences(of: "Repair: ", with: "") ?? "Unknown Item",
                        itemSKU: product.skuCode ?? "N/A",
                        itemImageURL: product.imageUrl,
                        pickupDate: pickupDate
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
