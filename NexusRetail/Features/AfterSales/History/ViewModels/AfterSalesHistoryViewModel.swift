import Foundation
import Observation

protocol AfterSalesHistoryServiceProtocol {
    func fetchExchanges() async throws -> [ExchangeHistoryItem]
    func fetchRepairs() async throws -> [RepairHistoryItem]
}

class MockAfterSalesHistoryService: AfterSalesHistoryServiceProtocol {
    func fetchExchanges() async throws -> [ExchangeHistoryItem] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        return [
            ExchangeHistoryItem(
                id: UUID().uuidString,
                customerName: "Rahul Sharma",
                invoiceNumber: "INV-1045",
                productName: "Nike Air Max",
                exchangeDate: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                reason: "Size Issue",
                status: "Completed"
            ),
            ExchangeHistoryItem(
                id: UUID().uuidString,
                customerName: "Sneha Patel",
                invoiceNumber: "INV-1042",
                productName: "Apple AirPods Pro",
                exchangeDate: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
                reason: "Defective left bud",
                status: "Completed"
            )
        ]
    }
    
    func fetchRepairs() async throws -> [RepairHistoryItem] {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 800_000_000)
        return [
            RepairHistoryItem(
                id: UUID().uuidString,
                customerName: "Ananya Verma",
                invoiceNumber: "INV-1028",
                productName: "Timex Chronograph",
                repairType: "Battery Replacement",
                completionDate: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date(),
                status: "Completed"
            ),
            RepairHistoryItem(
                id: UUID().uuidString,
                customerName: "Vikram Singh",
                invoiceNumber: "INV-1011",
                productName: "Sony WH-1000XM5",
                repairType: "Hinge Repair",
                completionDate: Calendar.current.date(byAdding: .day, value: -12, to: Date()) ?? Date(),
                status: "Completed"
            )
        ]
    }
}

@Observable
class AfterSalesHistoryViewModel {
    var exchanges: [ExchangeHistoryItem] = []
    var repairs: [RepairHistoryItem] = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    
    private let service: AfterSalesHistoryServiceProtocol
    
    init(service: AfterSalesHistoryServiceProtocol = MockAfterSalesHistoryService()) {
        self.service = service
    }
    
    func fetchHistory() async {
        isLoading = true
        errorMessage = nil
        do {
            async let exchangesTask = service.fetchExchanges()
            async let repairsTask = service.fetchRepairs()
            
            let (fetchedExchanges, fetchedRepairs) = try await (exchangesTask, repairsTask)
            self.exchanges = fetchedExchanges.sorted(by: { $0.exchangeDate > $1.exchangeDate })
            self.repairs = fetchedRepairs.sorted(by: { $0.completionDate > $1.completionDate })
        } catch {
            self.errorMessage = "Failed to load history."
        }
        isLoading = false
    }
}
