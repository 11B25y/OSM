import SwiftUI

struct ProfileDetailsView: View {
    var profile: UserProfile  // Directly pass the UserProfile
    
    var body: some View {
        VStack {
            // Profile Image
            ProfileImageView(
                profileImageName: profile.avatarURL ?? "default-profile",
                size: 100,
                isTappable: false
            )
            
            // Profile Information
            Text(profile.username ?? "Unknown User")
                .font(.title)
                .padding()
            
            Text("Age: \(profile.age)")
                .font(.subheadline)
                .padding()
            
            Text(profile.bio ?? "No bio available")
                .font(.body)
                .padding()
            
            // Edit Profile button
            Button(action: {
                // Add your edit profile action here
                print("Edit Profile Tapped")
            }) {
                Text("Edit Profile")
                    .foregroundColor(.blue)
                    .padding()
            }
        }
    }
}
