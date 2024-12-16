import SwiftUI

// Mock User Structure for Testing
struct User: Identifiable {
    let id = UUID()
    let name: String
    let age: Int
    let bio: String
    let image: String? // Make this optional so it can be nil if no image is set
}

// Separate View for Profile Image Rendering
struct UserProfileImageView: View {
    let imageName: String?
    let size: CGFloat
    let isTappable: Bool
    var onTap: (() -> Void)?
    
    var body: some View {
        ZStack {
            if let imageName = imageName, let url = URL(string: imageName), let imageData = try? Data(contentsOf: url), let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: size, height: size)
                    .foregroundColor(.gray)
                    .background(Circle().fill(Color.gray.opacity(0.3))) // Circle background for the icon
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .onTapGesture {
            if isTappable {
                onTap?() // Execute the tap closure
            }
        }
    }
    
    private func loadImage(named name: String?) -> UIImage? {
        guard let name = name else { return nil }
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("\(name).jpg")
        return UIImage(contentsOfFile: path.path)
    }
}

struct NearbyUsersView: View {
    // Accept an array of UserProfile as nearby users
    let nearbyUsers: [UserProfile]  // Assuming `UserProfile` is your model
    @Binding var selectedUser: UserProfile?  // Bind the selected user

    var body: some View {
        VStack {
            Text("Nearby Users")
                .font(.headline)
                .padding()

            // Displaying each user's profile icon and name
            ForEach(nearbyUsers) { user in
                VStack {
                    // Profile image using a custom UserProfileImageView
                    UserProfileImageView(imageName: user.wrappedAvatarURL?.absoluteString, size: 40, isTappable: true) {
                        selectedUser = user  // Set the selected user when tapped
                    }
                    
                    Text(user.wrappedUsername) // Use wrappedUsername to ensure it doesn't return nil
                        .font(.system(size: 10))
                }
                .onTapGesture {
                    selectedUser = user  // Set the selected user on tap
                }

                // Displaying user bubbles with a random arrangement in the circle
                ZStack {
                    ForEach(nearbyUsers.indices, id: \.self) { index in
                        let user = nearbyUsers[index]
                        let angle = Double(index) / Double(nearbyUsers.count) * 2 * .pi
                        let x = 150 * cos(angle)
                        let y = 150 * sin(angle)
                        
                        VStack {
                            UserProfileImageView(imageName: user.wrappedAvatarURL?.absoluteString, size: 40, isTappable: true) {
                                selectedUser = user  // Select the user when tapped
                            }
                            Text(user.wrappedUsername)
                                .font(.system(size: 10))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white)
                                .cornerRadius(10)
                                .shadow(radius: 1)
                        }
                        .position(x: 150 + x, y: 150 + y) // Randomized position within a circular area
                        .onTapGesture {
                            withAnimation {
                                selectedUser = user  // Animate selection
                            }
                        }
                    }
                }
                .frame(height: 300)
                .padding()
            }
        }
    }
}
