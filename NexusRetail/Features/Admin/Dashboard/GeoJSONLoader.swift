import Foundation
import CoreLocation
import MapKit
import SwiftUI

// MARK: - GeoJSON Models
struct GeoJSON: Decodable {
    let features: [Feature]
}

struct Feature: Decodable {
    let properties: Properties
    let geometry: Geometry
}

struct Properties: Decodable {
    let name: String
}

struct Geometry: Decodable {
    let type: String
    let coordinates: [CoordinateWrapper]
    
    // We need a custom decoder because coordinates can be Polygon [[[Double]]] or MultiPolygon [[[[Double]]]]
    enum CodingKeys: String, CodingKey {
        case type, coordinates
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        
        if type == "Polygon" {
            let polyCoords = try container.decode([[[Double]]].self, forKey: .coordinates)
            coordinates = [.polygon(polyCoords)]
        } else if type == "MultiPolygon" {
            let multiCoords = try container.decode([[[[Double]]]].self, forKey: .coordinates)
            coordinates = multiCoords.map { .polygon($0) }
        } else {
            coordinates = []
        }
    }
}

enum CoordinateWrapper {
    case polygon([[[Double]]])
}

// MARK: - App Models
struct CountryPolygon: Identifiable {
    let id = UUID()
    let name: String
    let polygons: [[CLLocationCoordinate2D]] // Array of polygons (outer rings)
}

class GeoJSONLoader {
    static func loadCountries() -> [CountryPolygon] {
        guard let url = Bundle.main.url(forResource: "countries", withExtension: "geojson") else {
            print("countries.geojson not found")
            return []
        }
        
        do {
            let data = try Data(contentsOf: url)
            let geoJSON = try JSONDecoder().decode(GeoJSON.self, from: data)
            
            var result: [CountryPolygon] = []
            
            for feature in geoJSON.features {
                var polygons: [[CLLocationCoordinate2D]] = []
                
                for wrapper in feature.geometry.coordinates {
                    if case .polygon(let polyCoords) = wrapper {
                        // Usually the first array is the outer ring
                        if let outerRing = polyCoords.first {
                            let coords = outerRing.compactMap { point -> CLLocationCoordinate2D? in
                                guard point.count >= 2 else { return nil }
                                return CLLocationCoordinate2D(latitude: point[1], longitude: point[0])
                            }
                            polygons.append(coords)
                        }
                    }
                }
                
                result.append(CountryPolygon(name: feature.properties.name, polygons: polygons))
            }
            
            return result
        } catch {
            print("Error parsing GeoJSON: \(error)")
            return []
        }
    }
}
