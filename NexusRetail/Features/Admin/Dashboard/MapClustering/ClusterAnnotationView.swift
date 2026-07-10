//
//  ClusterAnnotationView.swift
//  NexusRetail
//

import UIKit
import MapKit

class ClusterAnnotationView: MKAnnotationView {

    static let reuseIdentifier = "ClusterAnnotationView"

    private let heatmapLayer = CAGradientLayer()

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        canShowCallout = false
        backgroundColor = .clear

        heatmapLayer.type = .radial
        // Warm heatmap colors: deep red center -> orange -> yellow -> transparent
        heatmapLayer.colors = [
            UIColor(red: 220/255, green: 38/255, blue: 38/255, alpha: 0.8).cgColor,   // Intense Red
            UIColor(red: 234/255, green: 88/255, blue: 12/255, alpha: 0.6).cgColor,   // Orange
            UIColor(red: 250/255, green: 204/255, blue: 21/255, alpha: 0.3).cgColor,  // Yellow
            UIColor.clear.cgColor
        ]
        // Radial gradient starts at center and ends at edges
        heatmapLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        heatmapLayer.endPoint = CGPoint(x: 1.0, y: 1.0) // Radius is bounded by this
        heatmapLayer.locations = [0.0, 0.4, 0.7, 1.0]

        layer.addSublayer(heatmapLayer)
    }

    override func prepareForDisplay() {
        super.prepareForDisplay()

        if let cluster = annotation as? MKClusterAnnotation {
            let count = cluster.memberAnnotations.count

            // Base size grows with store count. Min size 60, max size 160
            let baseSize: CGFloat = 60
            let growth = min(100.0, CGFloat(count) * 4.0) // Caps out around 25 stores
            let totalSize = baseSize + growth

            frame = CGRect(x: 0, y: 0, width: totalSize, height: totalSize)
            centerOffset = CGPoint(x: 0, y: 0)
            heatmapLayer.frame = bounds

            // Adjust opacity and color intensity slightly based on density
            let maxOpacity = min(1.0, 0.6 + (CGFloat(count) / 20.0))
            heatmapLayer.opacity = Float(maxOpacity)
        }
    }
}
