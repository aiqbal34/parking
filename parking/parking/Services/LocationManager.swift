import Foundation
import CoreLocation
import MapKit
import Combine

// MARK: - LocationManager
/// Handles location services for the app
class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?
    @Published var isLocationEnabled = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update location when user moves 10 meters
        locationManager.allowsBackgroundLocationUpdates = false
    }
    
    /// Request location permission from user
    func requestLocationPermission() {
        print("Requesting location permission...")
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Start updating location
    func startLocationUpdates() {
        print("Starting location updates...")
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("Location not authorized, requesting permission...")
            requestLocationPermission()
            return
        }
        
        locationManager.startUpdatingLocation()
        isLocationEnabled = true
    }
    
    /// Request location and start updates immediately
    func requestLocationAndStartUpdates() {
        print("Requesting location and starting updates...")
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startLocationUpdates()
        } else {
            requestLocationPermission()
        }
    }
    
    /// Stop updating location
    func stopLocationUpdates() {
        print("Stopping location updates...")
        locationManager.stopUpdatingLocation()
        isLocationEnabled = false
    }
    
    /// Force a single location update
    func requestLocation() {
        print("Requesting single location update...")
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        
        locationManager.requestLocation()
    }
    
    /// Get address from coordinates using reverse geocoding
    func getAddress(from coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let placemark = placemarks?.first else {
                completion(nil)
                return
            }
            
            let address = [
                placemark.subThoroughfare,
                placemark.thoroughfare,
                placemark.locality,
                placemark.administrativeArea,
                placemark.postalCode
            ].compactMap { $0 }.joined(separator: " ")
            
            completion(address)
        }
    }
    
    /// Get coordinates from address using forward geocoding
    func getCoordinates(from address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(address) { placemarks, error in
            if let error = error {
                print("Forward geocoding error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let placemark = placemarks?.first,
                  let location = placemark.location else {
                completion(nil)
                return
            }
            
            completion(location.coordinate)
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        print("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        
        DispatchQueue.main.async {
            self.location = location
            self.errorMessage = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self.errorMessage = "Location access denied. Please enable in Settings."
                case .locationUnknown:
                    self.errorMessage = "Unable to determine location. Please try again."
                case .network:
                    self.errorMessage = "Network error. Please check your connection."
                default:
                    self.errorMessage = "Location error: \(error.localizedDescription)"
                }
            } else {
                self.errorMessage = "Location error: \(error.localizedDescription)"
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Location authorization changed to: \(status.rawValue)")
        
        DispatchQueue.main.async {
            self.authorizationStatus = status
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                print("Location authorized, starting updates...")
                self.startLocationUpdates()
            case .denied, .restricted:
                print("Location access denied or restricted")
                self.errorMessage = "Location access denied. Please enable in Settings."
                self.isLocationEnabled = false
            case .notDetermined:
                print("Location authorization not determined")
                break
            @unknown default:
                break
            }
        }
    }
}