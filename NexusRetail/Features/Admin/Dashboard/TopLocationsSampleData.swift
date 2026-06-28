//
//  TopLocationsSampleData.swift
//  NexusRetail
//

import Foundation
import SwiftUI

struct TopLocationsSampleData {
    static func salesData(for timeRange: StoreChartTimeRange) -> [String: (color: Color, value: String)] {
        let multiplier: Double
        switch timeRange {
        case .month: multiplier = 1.0
        case .quarter: multiplier = 3.0
        }
        
        func scale(_ val: Double) -> String {
            let num = val * multiplier
            if num >= 1000 {
                return String(format: "%.1fk", num / 1000)
            } else {
                return String(format: "%.0f", num)
            }
        }
        
        return [
            "United States of America": (Color(hex: "007AFF"), scale(15700)),
            "India": (Color(hex: "F4A261"), scale(4900)),
            "Australia": (Color(hex: "F4A261"), scale(4900)),
            "Germany": (Color(hex: "E9C46A"), scale(2400)),
            "France": (Color(hex: "E9C46A"), scale(2400)),
            "Brazil": (Color(hex: "F4A261"), scale(2100)),
            "Argentina": (Color(hex: "E9C46A"), scale(1500)),
            "South Africa": (Color(hex: "F4A261"), scale(2100)),
            "Algeria": (Color(hex: "F4A261"), scale(2100)),
            "Nigeria": (Color(hex: "F4A261"), scale(2100)),
            "Indonesia": (Color(hex: "E9C46A"), scale(1800))
        ]
    }
}
