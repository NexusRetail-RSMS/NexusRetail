//
//  StoreAnnotation.swift
//  NexusRetail
//

import Foundation
import MapKit

class StoreAnnotation: NSObject, MKAnnotation {
    let storeData: StoreMapItem
    let coordinate: CLLocationCoordinate2D

    // MKAnnotation properties
    var title: String? { storeData.name }

    init(storeData: StoreMapItem) {
        self.storeData = storeData
        self.coordinate = storeData.coordinate
        super.init()
    }
}
