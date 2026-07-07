import Foundation

@Observable
class RepairOrderManager {
    static let shared = RepairOrderManager()
    
    private let defaultsKey = "savedRepairOrders"
    
    struct RepairOrderData: Codable {
        let pickupDate: TimeInterval
        let customerName: String
    }
    
    // In-memory mapping from Order ID to Repair Data
    private(set) var repairData: [UUID: RepairOrderData] = [:]
    
    // Temporary cache to pass customer name from Invoice scan to Repair submit
    private var tempCustomerNameCache: [String: String] = [:]
    
    // Pending repair request data for PaymentFlowView to consume
    private var pendingRepairDate: Date?
    private var pendingInvoiceId: String?
    
    private init() {
        loadFromDefaults()
    }
    
    func cacheCustomerName(_ name: String, forInvoiceId invoiceId: String) {
        tempCustomerNameCache[invoiceId] = name
    }
    
    func setPendingRepair(date: Date, invoiceId: String) {
        pendingRepairDate = date
        pendingInvoiceId = invoiceId
    }
    
    func commitPendingRepair(forOrderId orderId: UUID) {
        guard let date = pendingRepairDate, let invoiceId = pendingInvoiceId else { return }
        
        let name = tempCustomerNameCache[invoiceId] ?? "Unknown Customer"
        repairData[orderId] = RepairOrderData(pickupDate: date.timeIntervalSince1970, customerName: name)
        saveToDefaults()
        
        // Clear pending
        pendingRepairDate = nil
        pendingInvoiceId = nil
    }
    
    func setRepairData(date: Date, invoiceId: String, forOrderId orderId: UUID) {
        let name = tempCustomerNameCache[invoiceId] ?? "Unknown Customer"
        repairData[orderId] = RepairOrderData(pickupDate: date.timeIntervalSince1970, customerName: name)
        saveToDefaults()
    }
    
    func getPickupDate(forOrderId orderId: UUID) -> Date? {
        if let data = repairData[orderId] {
            return Date(timeIntervalSince1970: data.pickupDate)
        }
        return nil
    }
    
    func getCustomerName(forOrderId orderId: UUID) -> String? {
        return repairData[orderId]?.customerName
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
