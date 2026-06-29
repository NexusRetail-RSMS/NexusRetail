import SwiftUI
import Observation

enum AdminTab: Hashable {
    case dashboard
    case stores
    case products
    case transfers
    case managers
}

@Observable
class AdminNavigationStore {
    var selectedTab: AdminTab = .dashboard
    
    // For navigating deep into managers list
    var selectedManagerID: UUID?
    
    func navigateToManagerProfile(managerID: UUID) {
        selectedManagerID = managerID
        selectedTab = .managers
    }
}
