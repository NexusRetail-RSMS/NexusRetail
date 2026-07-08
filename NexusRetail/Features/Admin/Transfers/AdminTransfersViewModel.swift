import Foundation
import SwiftUI
import Supabase

@Observable
class AdminTransfersViewModel {
    var requests: [AdminStockRequest] = []

    var isLoading = false
    var errorMessage: String?

    // MARK: - Computed

    var activeRequestsCount: Int {
        requests.filter { $0.status == .pending }.count
    }

    var pendingRequests: [AdminStockRequest] {
        requests.filter { $0.status == .pending }
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
                .select("*, products(*), store!requesting_store_id(*, manager:app_user!store_manager_fk(*))")
                .order("created_at", ascending: false)
                .execute()
                .value

            self.requests = fetchedRequests

            // Check for auto-approvals on load
            checkAutoApprovals()
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
    }

    // MARK: - Approve Immediately

    func approveRequest(_ request: AdminStockRequest) {
        guard let index = requests.firstIndex(where: { $0.id == request.id }) else { return }

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
                    requests[index].approvalMethod = .immediate
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
                try await SupabaseManager.shared.client
                    .from("transfer_request")
                    .update(StatusUpdate(status: TransferStatus.approved.rawValue))
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
}
