import SwiftUI
import MultipeerConnectivity

struct ProfilePageView: View {
    @EnvironmentObject private var proximityManager: ProximityManager
    @Binding var hasProfile: Bool
    @Binding var profile: UserProfile?
    @Binding var isCreatingProfile: Bool
    var peer: MCPeerID?

    @State private var showProfileDetails: Bool = false
    @State private var selectedImage: UIImage? = nil
    @State private var username: String = ""
    @State private var bio: String = ""
    @State private var age: Int = 0
    @State private var showImagePicker: Bool = false
    @State private var currentUserProfile: UserProfile? = nil
    @State private var errorMessage: String = ""
    @State private var showProfileAlert = false
    @State private var alertUser: UserProfile?
    @State private var selectedUser: UserProfile? = nil
    @State private var showProfileSheet = false
    @State private var showErrorAlert: Bool = false

    // Show Error Alert
    func showError(_ message: String) {
        errorMessage = message
        showErrorAlert = true
    }

    var body: some View {
        VStack {
            let profileImageName = profile?.avatarURL ?? "default-profile"
            
            // ✅ Profile Image
            ProfileImageView(
                profileImageName: profileImageName,
                size: 100,
                isTappable: true
            ) {
                alertUser = profile
                showProfileAlert = true
            }
            .padding()
            
            if isCreatingProfile {
                // ✅ Editable Fields When Editing
                TextField("Username", text: $username)
                    .uiverseTextFieldStyle()
                    .padding()
                
                TextField("Bio", text: $bio)
                    .uiverseTextFieldStyle()
                    .padding()
                
                TextField("Age", value: $age, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .uiverseTextFieldStyle()
                    .padding()
                
                Button("Save Changes") {
                    validateAndSaveProfile()
                }
                .buttonStyle(UiverseButtonStyle())

            } else {
                // ✅ Display User Info
                Text(profile?.wrappedUsername ?? "No Username")
                    .font(.title)
                
                if showProfileDetails, let profile = profile {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Username: \(profile.wrappedUsername)").font(.headline)
                        Text("Bio: \(profile.wrappedBio)").font(.subheadline).foregroundColor(.gray)
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
                
                // ✅ "Edit Profile" Button for Existing Users
                Button(action: {
                    isCreatingProfile = true
                }) {
                    Text("Edit Profile")
                }
                .buttonStyle(UiverseButtonStyle())
                .padding(.top)
                
                // 🔹 Logout Button
                Button(action: logOutUser) {
                    Text("Log Out")
                }
                .buttonStyle(UiverseButtonStyle())
                .padding(.top)
            }
        }
        .onAppear {
            fetchCurrentUser()  // Reload the profile every time the view appears
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
                .onDisappear {
                    // Update profile image URL after selecting new image
                    if let image = selectedImage {
                        if let savedURL = ImageManager.saveImage(image, withName: "UserProfileImage") {
                            currentUserProfile?.avatarURL = savedURL.absoluteString
                            try? PersistenceController.shared.container.viewContext.save() // Save changes
                            print("✅ Image saved and profile updated at: \(savedURL)")
                        }
                    }
                }
        }
        .alert(isPresented: $showProfileAlert) {
            Alert(
                title: Text(alertUser?.wrappedUsername ?? "Profile"),
                message: Text("Username: \(alertUser?.wrappedUsername ?? "N/A")\nBio: \(alertUser?.wrappedBio ?? "N/A")\nAge: \(alertUser?.age ?? 0)"),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // ✅ Load Existing Profile
    func fetchCurrentUser() {
        let context = PersistenceController.shared.container.viewContext
        // Fetch the logged-in user from ProximityManager
        currentUserProfile = proximityManager.fetchLoggedInUser(context: context)

        if let user = currentUserProfile {
            profile = user  // Update the profile in the view
            username = user.wrappedUsername  // Bind values to UI elements
            bio = user.wrappedBio
            age = Int(user.age)
            hasProfile = true
            print("✅ Loaded existing user: \(user.wrappedUsername)")
        } else {
            print("❌ No saved user profile found.")
        }
    }
    
    func validateAndSaveProfile() {
        guard !username.isEmpty, !bio.isEmpty else {
            showError("Please fill in all fields.")
            return
        }

        // If validation passes, call saveProfileChanges to save the profile
        guard let user = currentUserProfile else { return }
        user.username = username
        user.bio = bio
        user.age = Int16(age)

        // Delegate saving profile to ProximityManager
        ProximityManager.shared.saveProfileChanges(profile: user)

        isCreatingProfile = false
    }

    // ✅ Load Saved Profile Image
    func loadSavedImage() {
        if let loadedImage = ImageManager.loadImage(named: "UserProfileImage") {
            selectedImage = loadedImage
        }
    }
    
    func showProfileInfo(for user: UserProfile) {
        guard selectedUser != user else { return } // ✅ Prevent unnecessary updates
        selectedUser = user
        showProfileSheet = true
    }

    // ✅ Logout Function
    func logOutUser() {
        guard let user = currentUserProfile else { return }
        let context = PersistenceController.shared.container.viewContext

        user.isLoggedIn = false // Mark user as logged out
        do {
            try context.save()
            print("✅ Logged out successfully.")

            // Reset profile data on logout
            hasProfile = false
            profile = nil
        } catch {
            print("❌ Logout failed: \(error.localizedDescription)")
        }
    }
}
