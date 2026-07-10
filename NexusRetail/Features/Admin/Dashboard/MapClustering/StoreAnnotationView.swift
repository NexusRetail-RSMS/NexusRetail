//
//  StoreAnnotationView.swift
//  NexusRetail
//

import UIKit
import MapKit

import SwiftUI

class StoreAnnotationView: MKAnnotationView {

    static let reuseIdentifier = "StoreAnnotationView"

    private var hostingController: UIHostingController<StoreMarkerView>?

    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        clusteringIdentifier = "StoreCluster"
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        clusteringIdentifier = "StoreCluster"
        setup()
    }

    private func setup() {
        canShowCallout = false // We handle selection purely in SwiftUI
        backgroundColor = .clear
        displayPriority = .defaultHigh
        collisionMode = .circle
    }

    /// Updates the SwiftUI view with the latest state
    func update(with store: StoreMapItem, isSelected: Bool) {
        let view = StoreMarkerView(store: store, isSelected: isSelected)

        if let hc = hostingController {
            hc.rootView = view
            hc.view.layoutIfNeeded()
        } else {
            let hc = UIHostingController(rootView: view)
            hc.view.backgroundColor = .clear
            hc.view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(hc.view)

            NSLayoutConstraint.activate([
                hc.view.centerXAnchor.constraint(equalTo: centerXAnchor),
                hc.view.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
            self.hostingController = hc
            hc.view.layoutIfNeeded()
        }

        let size = hostingController?.view.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize) ?? CGSize(width: 44, height: 50)
        self.frame = CGRect(origin: .zero, size: size)

        // Offset so the pointer is exactly at the coordinate
        self.centerOffset = CGPoint(x: 0, y: -size.height / 2)
    }

    override func prepareForDisplay() {
        super.prepareForDisplay()

        // Initial render (unselected by default)
        if let storeAnnotation = annotation as? StoreAnnotation {
            update(with: storeAnnotation.storeData, isSelected: false)
        }
    }
}
