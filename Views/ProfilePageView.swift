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
    @State private var errorMessage = ""
    @State private var showProfileAlert = false
    @State private var alertUser: UserProfile?
    @State private var selectedUser: UserProfile? = nil
    @State private var showProfileSheet = false
    
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
                
                Button("Save Changes") {  // ✅ Changed "Create Profile" to "Save Changes"
                    saveProfileChanges()
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
            fetchCurrentUser() // ✅ Ensure updated profile is loaded
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(selectedImage: $selectedImage)
                .onDisappear {
                    if let image = selectedImage {
                        if let savedURL = ImageManager.saveImage(image, withName: "UserProfileImage") {
                            currentUserProfile?.avatarURL = savedURL.absoluteString // ✅ Update profile image URL
                            try? PersistenceController.shared.container.viewContext.save()
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
    }
    
    // ✅ Load Existing Profile
    func fetchCurrentUser() {
        let context = PersistenceController.shared.container.viewContext
        currentUserProfile = UserProfile.fetchLoggedInUser(context: context)
        if let user = currentUserProfile {
            profile = user
            username = user.wrappedUsername
            bio = user.wrappedBio
            age = Int(user.age)
            hasProfile = true
            print("✅ Loaded existing user: \(user.wrappedUsername)")
        } else {
            print("❌ No saved user profile found.")
        }
    }
    
    // ✅ Save Profile Changes (Instead of Creating a New Profile)
    func saveProfileChanges() {
        guard let user = currentUserProfile else { return }
        let context = PersistenceController.shared.container.viewContext

        user.username = username
        user.bio = bio
        user.age = Int16(age)

        do {
            try context.save()
            print("✅ Profile updated successfully.")
            isCreatingProfile = false
        } catch {
            print("❌ Failed to save profile: \(error.localizedDescription)")
        }
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

        user.isLoggedIn = false // ✅ Mark user as logged out
        do {
            try context.save()
            print("✅ Logged out successfully.")

            // ✅ Navigate back to profile creation
            hasProfile = false
            profile = nil
        } catch {
            print("❌ Logout failed: \(error.localizedDescription)")
        }
    }
}
