//
//  NexusMapView.swift
//  NexusRetail
//

import SwiftUI
import MapKit

/// MKPolygon carrying a normalised customer-footprint intensity (0...1)
/// so the renderer can shade it with the burgundy ramp.
final class FootprintPolygon: MKPolygon {
    var intensity: CGFloat = 0.5
}

struct NexusMapView: UIViewRepresentable {
    
    var stores: [StoreMapItem]
    @Binding var selectedStore: StoreMapItem?
    @Binding var cameraPosition: MapCameraPosition
    /// Per-country customer footprint used to draw the choropleth overlays.
    var footprint: [CountryFootprint] = []
    /// Country boundary polygons (from GeoJSONLoader) used to build overlays.
    var countryPolygons: [CountryPolygon] = []
    /// Fill colour for the footprint overlays (app burgundy).
    var fillColor: UIColor = .systemRed
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsCompass = false
        mapView.showsScale = false
        // Full native interactivity: pan, pinch-zoom, rotate, drag.
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = true
        
        // Register custom annotation views
        mapView.register(StoreAnnotationView.self, forAnnotationViewWithReuseIdentifier: StoreAnnotationView.reuseIdentifier)
        mapView.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // 0. Update footprint choropleth overlays (diffing by signature)
        let signature = footprint
            .map { "\(InteractiveChoroplethMap.canonical($0.country)):\($0.customerCount)" }
            .sorted()
            .joined(separator: ",")
        if signature != context.coordinator.footprintSignature {
            context.coordinator.footprintSignature = signature
            let existing = uiView.overlays.compactMap { $0 as? FootprintPolygon }
            uiView.removeOverlays(existing)

            let maxCustomers = max(footprint.map(\.customerCount).max() ?? 0, 1)
            let byKey = Dictionary(footprint.map { (InteractiveChoroplethMap.canonical($0.country), $0) },
                                   uniquingKeysWith: { a, _ in a })
            for country in countryPolygons {
                guard let fp = byKey[InteractiveChoroplethMap.canonical(country.name)],
                      fp.customerCount > 0 else { continue }
                let t = pow(CGFloat(fp.customerCount) / CGFloat(maxCustomers), 0.6)
                for ring in country.polygons where ring.count > 2 {
                    let poly = FootprintPolygon(coordinates: ring, count: ring.count)
                    poly.intensity = t
                    poly.title = country.name
                    uiView.addOverlay(poly, level: .aboveRoads)
                }
            }
        }

        // 1. Update Annotations safely (diffing)
        let currentAnnotations = uiView.annotations.compactMap { $0 as? StoreAnnotation }
        let currentStoreIds = Set(currentAnnotations.map { $0.storeData.id })
        let newStoreIds = Set(stores.map { $0.id })
        
        // Find which to remove and which to add
        let toRemove = currentAnnotations.filter { !newStoreIds.contains($0.storeData.id) }
        let toAdd = stores.filter { !currentStoreIds.contains($0.id) }.map { StoreAnnotation(storeData: $0) }
        
        if !toRemove.isEmpty {
            uiView.removeAnnotations(toRemove)
        }
        if !toAdd.isEmpty {
            uiView.addAnnotations(toAdd)
        }
        
        // Update selection states on all currently displayed StoreAnnotationViews
        for annotation in currentAnnotations {
            if let annotationView = uiView.view(for: annotation) as? StoreAnnotationView {
                let isSelected = annotation.storeData.id == selectedStore?.id
                annotationView.update(with: annotation.storeData, isSelected: isSelected)
            }
        }
        
        // 2. Update Camera Position
        if !context.coordinator.isAnimatingCamera, cameraPosition != context.coordinator.lastCameraPosition {
            context.coordinator.lastCameraPosition = cameraPosition
            if let region = cameraPosition.region {
                uiView.setRegion(region, animated: true)
            } else if let rect = cameraPosition.rect {
                uiView.setVisibleMapRect(rect, animated: true)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: NexusMapView
        var isAnimatingCamera = false
        var lastCameraPosition: MapCameraPosition?
        var footprintSignature: String = ""
        
        init(_ parent: NexusMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let fp = overlay as? FootprintPolygon {
                let renderer = MKPolygonRenderer(polygon: fp)
                renderer.fillColor = parent.fillColor.withAlphaComponent(0.25 + 0.60 * fp.intensity)
                renderer.strokeColor = parent.fillColor.withAlphaComponent(0.9)
                renderer.lineWidth = 1
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation { return nil }
            
            if annotation is MKClusterAnnotation {
                return mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier, for: annotation)
            }
            
            if annotation is StoreAnnotation {
                return mapView.dequeueReusableAnnotationView(withIdentifier: StoreAnnotationView.reuseIdentifier, for: annotation)
            }
            
            return nil
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let cluster = view.annotation as? MKClusterAnnotation {
                // Zoom into cluster safely using built-in showAnnotations
                isAnimatingCamera = true
                mapView.deselectAnnotation(cluster, animated: false)
                
                // Show member annotations with padding
                mapView.showAnnotations(cluster.memberAnnotations, animated: true)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.isAnimatingCamera = false
                    self.parent.cameraPosition = .region(mapView.region)
                    self.lastCameraPosition = self.parent.cameraPosition
                }
            } else if let storeAnnotation = view.annotation as? StoreAnnotation {
                // Prevent default MKMarker red pin pop by deselecting immediately
                mapView.deselectAnnotation(storeAnnotation, animated: false)
                
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        self.parent.selectedStore = storeAnnotation.storeData
                    }
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            if view.annotation is StoreAnnotation {
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        if self.parent.selectedStore != nil {
                            self.parent.selectedStore = nil
                        }
                    }
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            if !isAnimatingCamera {
                // If user pans, update our internal state so we don't snap back on next render
                self.lastCameraPosition = .region(mapView.region)
            }
        }
    }
}
