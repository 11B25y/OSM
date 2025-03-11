import CoreLocation
import CoreData
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var currentLocation: CLLocation? // Observable property for the current location
    @Published var isSharingLocation: Bool = false // Toggle for user visibility
    @Published var nearbyUsers: [UserProfile] = [] // List of nearby users
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update only if user moves 10 meters
        locationManager.pausesLocationUpdatesAutomatically = false // Keep updates continuous
    }
    
    /// Request location authorization
    func requestAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    /// Enable background updates if authorized
    func enableBackgroundUpdatesIfAuthorized() {
        if locationManager.authorizationStatus == .authorizedAlways {
            locationManager.allowsBackgroundLocationUpdates = true
        } else {
            print("App does not have Always authorization for location updates.")
        }
    }
    
    /// Start location updates and send user location
    func startUpdatingLocation() {
        enableBackgroundUpdatesIfAuthorized()
        locationManager.startUpdatingLocation()
    }
    
    /// Stop location updates
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    /// Handle location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        DispatchQueue.main.async {
            self.currentLocation = location
            if self.isSharingLocation {
                self.updateUserLocation(location)
            }
        }
        
        print("Updated location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
    
    /// Handle location errors
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location Manager Error: \(error.localizedDescription)")
    }
    
    /// Function to update user location in CoreData
    private func updateUserLocation(_ location: CLLocation) {
        let context = PersistenceController.shared.container.viewContext
        
        if let user = UserProfile.fetchLoggedInUser(context: context) {
            user.latitude = location.coordinate.latitude
            user.longitude = location.coordinate.longitude
            
            do {
                try context.save()
                print("User location updated successfully.")
            } catch {
                print("Failed to update location: \(error.localizedDescription)")
            }
        }
    }

/// Fetch nearby users from CoreData (Premium Feature)
  func fetchNearbyUsers() {
      let context = PersistenceController.shared.container.viewContext

      let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
      request.predicate = NSPredicate(format: "latitude != 0 AND longitude != 0")

      do {
          let users = try context.fetch(request)
          DispatchQueue.main.async {
              self.nearbyUsers = users.filter { $0.isLoggedIn && $0.peerID != UserProfile.fetchLoggedInUser(context: context)?.peerID }
          }
      } catch {
          print("Failed to fetch nearby users: \(error.localizedDescription)")
      }
  }
}

