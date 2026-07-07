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
        let createdAt: Date
        let problemDescription: String?
    }
    
    var body: some View {
        ZStack {
            RSMSColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                
                if isLoading {
                    Spacer()
                    ProgressView("Loading Repairs...")
                        .tint(RSMSColors.burgundy)
                    Spacer()
                } else if repairOrders.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: 48))
                            .foregroundColor(RSMSColors.secondaryText)
                        Text("No Active Repairs")
                            .font(RSMSFonts.title)
                            .foregroundColor(RSMSColors.primaryText)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(repairOrders) { repair in
                                NavigationLink(destination: RepairOrderDetailsView(repair: repair)) {
                                    RepairCardView(
                                        customerName: repair.customerName,
                                        customerImageURL: nil,
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
                        .padding(.bottom, 80) // To account for the floating tab bar
                    }
                    .refreshable { await fetchRepairOrders() }
                }
            }
        }
        .task { await fetchRepairOrders() }
        .navigationBarHidden(true)
    }

    // MARK: - Header
    
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Repairs")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(RSMSColors.primaryText)
            Spacer()
        }
        .padding(.horizontal, RSMSSpacing.lg)
        .padding(.top, 16)
        .padding(.bottom, 4)
    }

    // MARK: - Data (backed by the real after_sales_ticket table)

    /// A repair ticket row joined with its product (image/sku) and customer.
    private struct RepairTicketRow: Decodable {
        let id: UUID
        let itemName: String?
        let issueDescription: String?
        let createdAt: Date
        let products: ProductJoin?
        let client: ClientJoin?

        struct ProductJoin: Decodable {
            let skuCode: String?
            let imageUrl: String?
            let pexelsPage: String?
            enum CodingKeys: String, CodingKey {
                case skuCode = "sku_code"
                case imageUrl = "image_url"
                case pexelsPage = "pexels_page"
            }
        }
        struct ClientJoin: Decodable {
            let name: String?
        }

        enum CodingKeys: String, CodingKey {
            case id
            case itemName = "item_name"
            case issueDescription = "issue_description"
            case createdAt = "created_at"
            case products
            case client
        }
    }
    
    private func fetchRepairOrders() async {
        isLoading = true
        defer { isLoading = false }
        do {
            var query = SupabaseManager.shared.client
                .from("after_sales_ticket")
                .select("id, item_name, issue_description, created_at, products(sku_code, image_url, pexels_page), client(name)")
                .eq("type", value: "repair")

            if let storeID = sessionStore.currentUser?.storeID {
                query = query.eq("store_id", value: storeID.uuidString)
            }

            let rows: [RepairTicketRow] = try await query
                .order("created_at", ascending: false)
                .execute()
                .value

            let mapped: [RepairOrderViewModel] = rows.map { row in
                let img = POSProductRepository.shared.extractPexelsImageUrl(from: row.products?.pexelsPage ?? "")
                    ?? row.products?.imageUrl
                // Estimated pickup: 7 days after the ticket was raised.
                let pickup = Calendar.current.date(byAdding: .day, value: 7, to: row.createdAt) ?? row.createdAt
                return RepairOrderViewModel(
                    id: row.id,
                    customerName: row.client?.name ?? "Walk-in Customer",
                    itemName: row.itemName ?? "Item",
                    itemSKU: row.products?.skuCode ?? "N/A",
                    itemImageURL: img,
                    pickupDate: pickup,
                    createdAt: row.createdAt,
                    problemDescription: row.issueDescription
                )
            }

            await MainActor.run { self.repairOrders = mapped }
        } catch {
            print("Failed to fetch repairs: \(error)")
        }
    }
}
