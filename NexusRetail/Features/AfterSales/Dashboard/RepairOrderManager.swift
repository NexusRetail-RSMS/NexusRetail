import Foundation

@Observable
class RepairOrderManager {
    static let shared = RepairOrderManager()
    
    // In-memory mapping from Order ID to Pickup Date
    private var pickupDates: [UUID: Date] = [:]
    
    private init() {}
    
    func setPickupDate(_ date: Date, forOrderId orderId: UUID) {
        pickupDates[orderId] = date
    }
    
    func getPickupDate(forOrderId orderId: UUID) -> Date? {
        return pickupDates[orderId]
    }
}
