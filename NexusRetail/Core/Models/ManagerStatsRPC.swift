import Foundation

struct ManagerStatsRPC: Decodable {
    let id: UUID
    let name: String?
    let email: String?
    let phone: String?
    let address: String?
    let imageUrl: String?
    let createdAt: String?
    let storeName: String?
    let country: String?
    let revenue: Double?
    let productsSold: Int?
    let performanceScore: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case phone
        case address
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case storeName = "store_name"
        case country
        case revenue
        case productsSold = "products_sold"
        case performanceScore = "performance_score"
    }
}
