//
//  NexusMapView.swift
//  NexusRetail
//

import SwiftUI
import MapKit

struct NexusMapView: UIViewRepresentable {
    
    var stores: [StoreMapItem]
    @Binding var selectedStore: StoreMapItem?
    @Binding var cameraPosition: MapCameraPosition
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsCompass = false
        mapView.showsScale = false
        
        // Register custom annotation views
        mapView.register(StoreAnnotationView.self, forAnnotationViewWithReuseIdentifier: StoreAnnotationView.reuseIdentifier)
        mapView.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
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
        
        init(_ parent: NexusMapView) {
            self.parent = parent
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
