import SwiftUI
import MapKit

struct UserMapView: View {
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194), // Default location (SF)
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )

    let users: [UserProfile] // Nearby users

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: users) { user in
            MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: user.latitude, longitude: user.longitude)) {
                VStack {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                    Text(user.wrappedUsername)
                        .font(.caption)
                        .background(Color.white.opacity(0.7))
                        .cornerRadius(5)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
