import Foundation

@Observable
class RepairOrderManager {
    static let shared = RepairOrderManager()
    
    private let defaultsKey = "savedRepairOrders"
    
    struct RepairOrderData: Codable {
        let pickupDate: TimeInterval
    }
    
    // In-memory mapping from Order ID to Repair Data
    private(set) var repairData: [UUID: RepairOrderData] = [:]
    
    // Pending repair request data for PaymentFlowView to consume
    private var pendingRepairDate: Date?
    private var pendingInvoiceId: String?
    
    private init() {
        loadFromDefaults()
    }
    
    func setPendingRepair(date: Date, invoiceId: String) {
        pendingRepairDate = date
        pendingInvoiceId = invoiceId
    }
    
    func commitPendingRepair(forOrderId orderId: UUID) {
        guard let date = pendingRepairDate else { return }
        
        repairData[orderId] = RepairOrderData(pickupDate: date.timeIntervalSince1970)
        saveToDefaults()
        
        // Clear pending
        pendingRepairDate = nil
        pendingInvoiceId = nil
    }
    
    func setRepairData(date: Date, invoiceId: String, forOrderId orderId: UUID) {
        repairData[orderId] = RepairOrderData(pickupDate: date.timeIntervalSince1970)
        saveToDefaults()
    }
    
    func getPickupDate(forOrderId orderId: UUID) -> Date? {
        if let data = repairData[orderId] {
            return Date(timeIntervalSince1970: data.pickupDate)
        }
        return nil
    }
    
    func isRepairOrder(_ orderId: UUID) -> Bool {
        return repairData.keys.contains(orderId)
    }
    
    private func saveToDefaults() {
        var dictToSave: [String: RepairOrderData] = [:]
        for (key, data) in repairData {
            dictToSave[key.uuidString] = data
        }
        if let data = try? JSONEncoder().encode(dictToSave) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
    
    private func loadFromDefaults() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let savedDict = try? JSONDecoder().decode([String: RepairOrderData].self, from: data) {
            var loadedData: [UUID: RepairOrderData] = [:]
            for (keyStr, repData) in savedDict {
                if let uuid = UUID(uuidString: keyStr) {
                    loadedData[uuid] = repData
                }
            }
            self.repairData = loadedData
        }
    }
}
