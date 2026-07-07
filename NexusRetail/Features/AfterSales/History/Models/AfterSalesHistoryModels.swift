import Foundation

struct ExchangeHistoryItem: Identifiable, Hashable {
    let id: String
    let customerName: String
    let invoiceNumber: String
    let productName: String
    let exchangeDate: Date
    let reason: String
    let status: String
}

struct RepairHistoryItem: Identifiable, Hashable {
    let id: String
    let customerName: String
    let invoiceNumber: String
    let productName: String
    let repairType: String
    let completionDate: Date
    let status: String
}
