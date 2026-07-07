import Foundation

@Observable
class RepairOrderManager {
    static let shared = RepairOrderManager()
    
    private let defaultsKey = "savedRepairOrders"
    
    // In-memory mapping from Order ID to Pickup Date, initialized from UserDefaults
    private(set) var pickupDates: [UUID: Date] = [:]
    
    private init() {
        loadFromDefaults()
    }
    
    func setPickupDate(_ date: Date, forOrderId orderId: UUID) {
        pickupDates[orderId] = date
        saveToDefaults()
    }
    
    func getPickupDate(forOrderId orderId: UUID) -> Date? {
        return pickupDates[orderId]
    }
    
    func isRepairOrder(_ orderId: UUID) -> Bool {
        return pickupDates.keys.contains(orderId)
    }
    
    private func saveToDefaults() {
        // Convert to string keys for JSON serialization
        var dictToSave: [String: TimeInterval] = [:]
        for (key, date) in pickupDates {
            dictToSave[key.uuidString] = date.timeIntervalSince1970
        }
        if let data = try? JSONEncoder().encode(dictToSave) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
    
    private func loadFromDefaults() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let savedDict = try? JSONDecoder().decode([String: TimeInterval].self, from: data) {
            var loadedDates: [UUID: Date] = [:]
            for (keyStr, timeInt) in savedDict {
                if let uuid = UUID(uuidString: keyStr) {
                    loadedDates[uuid] = Date(timeIntervalSince1970: timeInt)
                }
            }
            self.pickupDates = loadedDates
        }
    }
}
