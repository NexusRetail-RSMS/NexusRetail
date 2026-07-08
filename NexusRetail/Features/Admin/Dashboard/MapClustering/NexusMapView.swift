//
//  NexusMapView.swift
//  NexusRetail
//
//  UIViewRepresentable wrapping MKMapView with:
//  - Annotation diffing (no full-reload flickering)
//  - One-shot camera updates (no feedback loop)
//  - Clustering support via StoreAnnotationView
//  - User interaction preservation
//

import SwiftUI
import MapKit

struct NexusMapView: UIViewRepresentable {
    
    var stores: [StoreMapItem]
    @Binding var selectedStore: StoreMapItem?
    
    /// One-shot camera target. When set to a non-nil region, the map animates
    /// to it and the coordinator clears it back to nil. This prevents the
    /// feedback loop where updateUIView constantly calls setRegion.
    @Binding var targetRegion: MKCoordinateRegion?
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsCompass = false
        mapView.showsScale = false
        
        // Register custom annotation views
        mapView.register(StoreAnnotationView.self, forAnnotationViewWithReuseIdentifier: StoreAnnotationView.reuseIdentifier)
        mapView.register(ClusterAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        
        // Apply initial region if provided
        if let region = targetRegion {
            mapView.setRegion(region, animated: false)
            DispatchQueue.main.async {
                self.targetRegion = nil
            }
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // 1. Diff annotations — only add/remove what changed
        updateAnnotations(on: uiView)
        
        // 2. Update selection highlight on visible annotation views
        updateSelectionState(on: uiView)
        
        // 3. Apply one-shot camera move (only when targetRegion is non-nil)
        if let region = targetRegion {
            uiView.setRegion(region, animated: true)
            
            // Clear the target so we don't re-apply on next render
            DispatchQueue.main.async {
                self.targetRegion = nil
            }
        }
    }
    
    // MARK: - Annotation Diffing
    
    private func updateAnnotations(on mapView: MKMapView) {
        let currentAnnotations = mapView.annotations.compactMap { $0 as? StoreAnnotation }
        let currentIds = Set(currentAnnotations.map { $0.storeData.id })
        let newIds = Set(stores.map { $0.id })
        
        // Remove annotations no longer in the data set
        let toRemove = currentAnnotations.filter { !newIds.contains($0.storeData.id) }
        if !toRemove.isEmpty {
            mapView.removeAnnotations(toRemove)
        }
        
        // Add new annotations not yet on the map
        let toAdd = stores.filter { !currentIds.contains($0.id) }.map { StoreAnnotation(storeData: $0) }
        if !toAdd.isEmpty {
            mapView.addAnnotations(toAdd)
        }
    }
    
    // MARK: - Selection State
    
    private func updateSelectionState(on mapView: MKMapView) {
        let allAnnotations = mapView.annotations.compactMap { $0 as? StoreAnnotation }
        for annotation in allAnnotations {
            if let view = mapView.view(for: annotation) as? StoreAnnotationView {
                let isSelected = annotation.storeData.id == selectedStore?.id
                view.update(with: annotation.storeData, isSelected: isSelected)
            }
        }
    }
    
    // MARK: - Coordinator
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: NexusMapView
        
        init(_ parent: NexusMapView) {
            self.parent = parent
        }
        
        // MARK: Annotation Views
        
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

        
        // MARK: Selection
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let cluster = view.annotation as? MKClusterAnnotation {
                // Zoom into cluster — this is an intentional camera move
                mapView.deselectAnnotation(cluster, animated: false)
                mapView.showAnnotations(cluster.memberAnnotations, animated: true)
                
            } else if let storeAnnotation = view.annotation as? StoreAnnotation {
                // Select store — do NOT move the camera
                mapView.deselectAnnotation(storeAnnotation, animated: false)
                
                DispatchQueue.main.async {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        self.parent.selectedStore = storeAnnotation.storeData
                    }
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            // Only clear selection if it was a store annotation
            // and the user actually deselected (not just a re-render)
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
        

    }
}
