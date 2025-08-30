import SwiftUI
import MapKit
import CoreLocation

// MARK: - MapView
struct MapView: UIViewRepresentable {
    let parkingSpots: [ParkingSpot]
    let userLocation: CLLocation?
    let currentUserID: String?
    @Binding var selectedSpot: ParkingSpot?
    @Binding var centerOnUserLocation: Bool
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        
        // Set initial region based on user location if available, otherwise use default
        if let userLocation = userLocation {
            let initialRegion = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
            mapView.setRegion(initialRegion, animated: false)
        } else {
            // Fallback to San Francisco (default for demo)
            let initialRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            mapView.setRegion(initialRegion, animated: false)
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Remove existing annotations
        uiView.removeAnnotations(uiView.annotations.filter { !($0 is MKUserLocation) })
        
        // Add parking spot annotations
        let annotations = parkingSpots.map { spot in
            ParkingSpotAnnotation(parkingSpot: spot)
        }
        uiView.addAnnotations(annotations)
        
        // Center on user location if requested
        if centerOnUserLocation, let userLocation = userLocation {
            let region = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
            uiView.setRegion(region, animated: true)
            // Reset the flag after centering
            DispatchQueue.main.async {
                self.centerOnUserLocation = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let parkingAnnotation = annotation as? ParkingSpotAnnotation else {
                return nil
            }
            
            let identifier = "ParkingSpot"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                annotationView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            } else {
                annotationView?.annotation = annotation
            }
            
            // Customize marker appearance based on availability and ownership
            let isOwnedByUser = parent.currentUserID == parkingAnnotation.parkingSpot.ownerID
            
            if isOwnedByUser {
                // User's own spots: green if available, orange if unavailable
                annotationView?.markerTintColor = parkingAnnotation.parkingSpot.isAvailable ? .systemGreen : .systemOrange
                annotationView?.glyphImage = UIImage(systemName: "house.fill")
            } else {
                // Other spots: blue if available, gray if unavailable
                annotationView?.markerTintColor = parkingAnnotation.parkingSpot.isAvailable ? .systemBlue : .systemGray
                annotationView?.glyphImage = UIImage(systemName: "car.fill")
            }
            
            return annotationView
        }
        
        func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            guard let annotation = view.annotation as? ParkingSpotAnnotation else { return }
            parent.selectedSpot = annotation.parkingSpot
        }
    }
}

// MARK: - ParkingSpotAnnotation
class ParkingSpotAnnotation: NSObject, MKAnnotation {
    let parkingSpot: ParkingSpot
    
    var coordinate: CLLocationCoordinate2D {
        parkingSpot.coordinate
    }
    
    var title: String? {
        "$\(Int(parkingSpot.hourlyRate))/hr"
    }
    
    var subtitle: String? {
        parkingSpot.address
    }
    
    init(parkingSpot: ParkingSpot) {
        self.parkingSpot = parkingSpot
    }
}

#Preview {
    MapView(
        parkingSpots: [
            ParkingSpot(
                address: "123 Test St",
                latitude: 37.7749,
                longitude: -122.4194,
                hourlyRate: 15.0,
                isAvailable: true,
                availabilityStart: Date(),
                availabilityEnd: Date().addingTimeInterval(3600 * 6),
                maxVehicleSize: .any,
                description: "Test spot",
                imageURL: nil,
                ownerID: "test",
                ownerName: "Test User"
            )
        ],
        userLocation: CLLocation(latitude: 37.7749, longitude: -122.4194),
        currentUserID: "test",
        selectedSpot: .constant(nil),
        centerOnUserLocation: .constant(false)
    )
}