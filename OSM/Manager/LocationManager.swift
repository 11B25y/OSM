import CoreLocation
import CoreData
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager() // Singleton instance
    
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation? // Observable property for the current location
    @Published var isSharingLocation: Bool = false // Toggle for user visibility
    @Published var nearbyUsers: [UserProfile] = [] // List of nearby users
    
    override init() { // ✅ Remove `private` if you want to allow instantiation
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    /// Request location authorization based on current status
    func requestAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            locationManager.requestAlwaysAuthorization() // Request always if we have "When in Use" permission
        case .authorizedAlways:
            // Only set background updates if we have "Always" permission
            locationManager.allowsBackgroundLocationUpdates = true
        default:
            print("Location permissions not granted.")
        }
    }
    
    // Start updating location
    func startUpdatingLocation() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            print("Location updates started.")
        } else {
            print("Location services are not enabled.")
        }
    }
    
    // Stop updating location
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        print("Location updates stopped.")
    }
    
    // CLLocationManager delegate method to receive location updates
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()  // Start location updates if authorized
        case .denied, .restricted:
            print("Location access denied or restricted.")
        case .notDetermined:
            print("Location authorization status not determined yet.")
        @unknown default:
            print("Unknown location authorization status.")
        }
    }
    
    // Handle errors in location manager
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }
}
