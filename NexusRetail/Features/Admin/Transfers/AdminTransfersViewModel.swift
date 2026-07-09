import Foundation
import SwiftUI
import CoreLocation
import Supabase

@Observable
class AdminTransfersViewModel {
    var requests: [AdminStockRequest] = []

    var isLoading = false
    var errorMessage: String?

    // MARK: - Computed

    var activeRequestsCount: Int {
        requests.filter { $0.status == .pending || $0.status == .pendingStoreApproval }.count
    }

    var pendingRequests: [AdminStockRequest] {
        requests.filter { $0.status == .pending }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Requests awaiting a source store manager's approval
    var pendingStoreApprovalRequests: [AdminStockRequest] {
        requests.filter { $0.status == .pendingStoreApproval }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var waitingRequests: [AdminStockRequest] {
        requests.filter { $0.status == .routed }
            .sorted { $0.scheduledAt ?? $0.createdAt > $1.scheduledAt ?? $1.createdAt }
    }

    var approvedRequests: [AdminStockRequest] {
        requests.filter { $0.status == .approved }
            .sorted { $0.approvedAt ?? $0.createdAt > $1.approvedAt ?? $1.createdAt }
    }

    // MARK: - Load

    @MainActor
    func load() async {
        isLoading = true
        errorMessage = nil

        do {
            let fetchedRequests: [AdminStockRequest] = try await SupabaseManager.shared.client
                .from("transfer_request")
                .select("*, products(*), store!requesting_store_id(*, manager:app_user!store_manager_fk(*)), source_store:store!source_store_id(name)")
                .order("created_at", ascending: false)
                .execute()
                .value

            self.requests = fetchedRequests

            // Check for auto-approvals and auto-escalations on load
            checkAutoApprovals()
            checkStoreApprovalTimeouts()
        } catch is CancellationError {
            print("Admin transfers load cancelled")
        } catch {
            print("Failed to load admin transfers data: \(error)")
            self.errorMessage = "Error: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Status Update

    struct StatusUpdate: Encodable {
        let status: String
        var source_store_id: UUID? = nil
    }

    // MARK: - Approve Immediately

    func approveRequest(_ request: AdminStockRequest) {
        guard let index = requests.firstIndex(where: { $0.id == request.id }) else { return }

        Task {
            do {
                let chosenSource = try await calculateSourceStore(for: request)
                
                if let sourceStoreId = chosenSource {
                    // Inter-store transfer: route to source store's manager for approval
                    try await SupabaseManager.shared.client
                        .from("transfer_request")
                        .update(StatusUpdate(status: TransferStatus.pendingStoreApproval.rawValue, source_store_id: sourceStoreId))
                        .eq("id", value: request.id)
                        .execute()

                    await MainActor.run {
                        requests[index].status = .pendingStoreApproval
                    }
                } else {
                    // Warehouse sourcing: approve immediately (existing flow)
                    try await SupabaseManager.shared.client
                        .from("transfer_request")
                        .update(StatusUpdate(status: TransferStatus.approved.rawValue, source_store_id: nil))
                        .eq("id", value: request.id)
                        .execute()

                    await MainActor.run {
                        requests[index].status = .approved
                        requests[index].approvedAt = Date()
                        requests[index].approvalMethod = .immediate
                    }
                }
            } catch {
                print("Failed to approve request: \(error)")
            }
        }
    }

    // MARK: - Schedule

    func scheduleRequest(_ request: AdminStockRequest, autoApproveDate: Date) {
        guard let index = requests.firstIndex(where: { $0.id == request.id }) else { return }

        let now = Date()

        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("transfer_request")
                    .update(StatusUpdate(status: TransferStatus.routed.rawValue))
                    .eq("id", value: request.id)
                    .execute()

                await MainActor.run {
                    requests[index].status = .routed
                    requests[index].scheduledAt = now
                    requests[index].autoApproveAt = autoApproveDate
                    requests[index].approvalMethod = .scheduled
                }
            } catch {
                print("Failed to schedule request: \(error)")
            }
        }
    }

    // MARK: - Approve Early

    func approveEarly(_ request: AdminStockRequest) {
        guard let index = requests.firstIndex(where: { $0.id == request.id }) else { return }

        Task {
            do {
                let chosenSource = try await calculateSourceStore(for: request)
                
                try await SupabaseManager.shared.client
                    .from("transfer_request")
                    .update(StatusUpdate(status: TransferStatus.approved.rawValue, source_store_id: chosenSource))
                    .eq("id", value: request.id)
                    .execute()

                await MainActor.run {
                    requests[index].status = .approved
                    requests[index].approvedAt = Date()
                    requests[index].approvalMethod = .early
                }
            } catch {
                print("Failed to approve early: \(error)")
            }
        }
    }

    // MARK: - Auto Approval

    func checkAutoApprovals() {
        let now = Date()

        for (index, request) in requests.enumerated() {
            guard request.status == .routed,
                  let autoApproveAt = request.autoApproveAt,
                  autoApproveAt <= now else { continue }

            Task {
                do {
                    try await SupabaseManager.shared.client
                        .from("transfer_request")
                        .update(StatusUpdate(status: TransferStatus.approved.rawValue))
                        .eq("id", value: request.id)
                        .execute()

                    await MainActor.run {
                        requests[index].status = .approved
                        requests[index].approvedAt = Date()
                        requests[index].approvalMethod = .scheduled
                    }
                } catch {
                    print("Failed to auto-approve request: \(error)")
                }
            }
        }
    }

    // MARK: - Store Approval Timeout (24-hour auto-escalation)

    /// If a pending_store_approval request has been waiting for more than 24 hours,
    /// automatically escalate it back to admin by resetting to pending status.
    func checkStoreApprovalTimeouts() {
        let now = Date()
        let timeoutInterval: TimeInterval = 24 * 60 * 60 // 24 hours

        for (index, request) in requests.enumerated() {
            guard request.status == .pendingStoreApproval else { continue }

            let elapsed = now.timeIntervalSince(request.createdAt)
            guard elapsed >= timeoutInterval else { continue }

            Task {
                do {
                    struct EscalateUpdate: Encodable {
                        let status: String
                        let source_store_id: UUID?
                        let decline_reason: String
                    }

                    try await SupabaseManager.shared.client
                        .from("transfer_request")
                        .update(EscalateUpdate(
                            status: TransferStatus.pending.rawValue,
                            source_store_id: nil,
                            decline_reason: "Auto-escalated: source store did not respond within 24 hours"
                        ))
                        .eq("id", value: request.id)
                        .execute()

                    await MainActor.run {
                        requests[index].status = .pending
                    }
                } catch {
                    print("Failed to auto-escalate request: \(error)")
                }
            }
        }
    }

    // MARK: - Location-Based Sourcing Logic
    
    struct StoreInventoryRow: Decodable {
        let store_id: UUID
        let on_hand: Int
    }
    
    func predictSourceString(for request: AdminStockRequest) async -> String {
        do {
            let reqStore: Store = try await SupabaseManager.shared.client
                .from("store")
                .select("country")
                .eq("id", value: request.requestingStoreId)
                .single()
                .execute()
                .value
            
            let country = reqStore.country ?? ""
            var warehouseName = "Central Warehouse"
            if country.lowercased().contains("india") { warehouseName = "Mumbai Warehouse" }
            if country.lowercased().contains("usa") || country.lowercased().contains("united states") { warehouseName = "Kansas City Warehouse" }
            
            if request.quantity > 3 {
                return warehouseName
            }
            
            let sourceId = try await calculateSourceStore(for: request)
            if let sourceId = sourceId {
                let sourceStore: Store = try await SupabaseManager.shared.client
                    .from("store")
                    .select("name")
                    .eq("id", value: sourceId)
                    .single()
                    .execute()
                    .value
                return "\(sourceStore.name) (Nearby)"
            }
            return warehouseName
        } catch {
            return "Central Warehouse"
        }
    }
    
    private func calculateSourceStore(for request: AdminStockRequest) async throws -> UUID? {
        // Emergency Rule: Only source from stores if request quantity <= 3. Otherwise, use warehouse (nil)
        guard request.quantity <= 3 else { return nil }
        
        // 1. Fetch requesting store details
        let reqStore: Store = try await SupabaseManager.shared.client
            .from("store")
            .select()
            .eq("id", value: request.requestingStoreId)
            .single()
            .execute()
            .value
            
        guard let reqLat = reqStore.latitude, let reqLon = reqStore.longitude, let country = reqStore.country else {
            return nil
        }
        
        let reqLocation = CLLocation(latitude: reqLat, longitude: reqLon)
        
        // 2. Determine country warehouse location
        var warehouseLocation: CLLocation?
        if country.lowercased().contains("india") {
            warehouseLocation = CLLocation(latitude: 19.0760, longitude: 72.8777) // Mumbai Warehouse
        } else if country.lowercased().contains("united states") || country.lowercased().contains("usa") {
            warehouseLocation = CLLocation(latitude: 39.0997, longitude: -94.5786) // Kansas City Warehouse
        }
        
        let distToWarehouse = warehouseLocation.map { reqLocation.distance(from: $0) } ?? .infinity
        
        // 3. Fetch all other stores in the same country
        let allStores: [Store] = try await SupabaseManager.shared.client
            .from("store")
            .select()
            .eq("country", value: country)
            .execute()
            .value
            
        // 4. Fetch inventory for the requested item
        let inventories: [StoreInventoryRow] = try await SupabaseManager.shared.client
            .from("inventory_item")
            .select("store_id, on_hand")
            .eq("item_id", value: Int(request.itemId))
            .execute()
            .value
            
        var inventoryMap: [UUID: Int] = [:]
        for inv in inventories {
            inventoryMap[inv.store_id] = inv.on_hand
        }
        
        var closestStoreId: UUID? = nil
        var minDistance: CLLocationDistance = .infinity
        
        // 5. Find the closest store with sufficient stock (requested + 10 safety threshold)
        let safetyThreshold = 10
        let requiredStock = request.quantity + safetyThreshold
        
        for store in allStores {
            guard store.id != request.requestingStoreId else { continue }
            guard let lat = store.latitude, let lon = store.longitude else { continue }
            
            let stock = inventoryMap[store.id] ?? 0
            if stock >= requiredStock {
                let loc = CLLocation(latitude: lat, longitude: lon)
                let dist = reqLocation.distance(from: loc)
                
                if dist < minDistance {
                    minDistance = dist
                    closestStoreId = store.id
                }
            }
        }
        
        // 6. If the closest valid store is closer than the warehouse, use it! Otherwise, warehouse.
        if minDistance < distToWarehouse {
            return closestStoreId
        }
        
        return nil
    }
}
