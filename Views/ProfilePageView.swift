import SwiftUI
import MultipeerConnectivity

struct ProfilePageView: View {
    @EnvironmentObject private var proximityManager: ProximityManager
    @Binding var hasProfile: Bool
    @Binding var profile: UserProfile?
    @Binding var isCreatingProfile: Bool // Use the binding passed from the parent view
    var peer: MCPeerID?
    
    @State private var showProfileDetails: Bool = false
    @State private var selectedImage: UIImage? = nil
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var age: Int = 0
    @State private var showImagePicker: Bool = false
    @State private var currentUserProfile: UserProfile? = nil
    @State private var errorMessage = ""

    var body: some View {
        VStack {
            // Profile Image Section
            let profileImageName = profile?.avatarURL ?? "default-profile" // Set the profile image name based on the profile's avatar URL

            ProfileImageView(
                profileImageName: profileImageName, // Pass the profile image name
                size: 100,                          // Adjust the size as needed
                isTappable: true                    // Make it tappable
            ) {
                showProfileDetails.toggle()  // Trigger the profile details toggle when tapped
            }
            // Other profile sections (username, bio, etc.)
            if isCreatingProfile {
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                TextField("Bio", text: $bio)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                // TextField for age (Binding to the `age` variable)
                TextField("Age", value: $age, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Create Profile") {
                    hasProfile = true
                    saveProfileChanges()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            } else {
                Text(profile?.wrappedUsername ?? "No Username")
                    .font(.title)
                
                if showProfileDetails, let profile = profile {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username: \(profile.wrappedUsername)")
                            .font(.headline)
                        Text("Bio: \(profile.wrappedBio)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        if profile.age > 0 {
                            Text("Age: \(profile.age)")
                        } else {
                            Text("Age: Not set")
                        }
                        if let email = profile.email, !email.isEmpty {
                            Text("Email: \(email)")
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            if !isCreatingProfile {
                username = profile?.wrappedUsername ?? ""
                bio = profile?.wrappedBio ?? ""
                age = Int(profile?.age ?? 0)
            }
            loadSavedImage()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
                .onDisappear {
                    if let image = selectedImage {
                        if let savedURL = ImageManager.saveImage(image, withName: "UserProfileImage") {
                            print("Image saved at: \(savedURL)")
                        }
                    }
                }
        }
    }

    func loadSavedImage() {
        if let loadedImage = ImageManager.loadImage(named: "UserProfileImage") {
            selectedImage = loadedImage
        }
    }

    func saveProfileChanges() {
        let newProfile = UserProfile(context: proximityManager.managedObjectContext)
        newProfile.username = username
        newProfile.bio = bio
        newProfile.age = Int16(age)
        saveProfileChanges(newProfile)
    }

    func saveProfileChanges(_ profile: UserProfile) {
        // Call ProximityManager's function to save the profile to Core Data
        proximityManager.saveProfileChanges(profile)  // Call from ProximityManager

        // After saving, update state
        currentUserProfile = profile
        hasProfile = true  // Trigger UI update
    }

    func showProfileInfo(for user: UserProfile) {
        let alert = UIAlertController(title: user.wrappedUsername, message: "Username: \(user.wrappedUsername)\nBio: \(user.wrappedBio)\nAge: \(user.age)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Edit Photo", style: .default, handler: { _ in
            showImagePicker = true // Now this works because showImagePicker is within scope
        }))
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first {
            window.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
}
