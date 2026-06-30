import Foundation

struct SKU: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var category: String
    var description: String?
    var launchDate: Date?
    var imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case description
        case launchDate = "launch_date"
        case imageUrl = "image_url"
    }
}
