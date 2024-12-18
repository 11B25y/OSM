import SwiftUI
import CoreData

struct ProfileSignupView: View {
    @Environment(\.managedObjectContext) private var context
    @EnvironmentObject private var proximityManager: ProximityManager
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    
    @Binding var hasProfile: Bool
    @Binding var currentUserProfile: UserProfile?
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var bio: String = ""
    @State private var avatarImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var errorMessage: String = ""
    @State private var age: Int? = nil

    var body: some View {
        NavigationStack {
            VStack {
                Text("Create Your Profile")
                    .font(.largeTitle)
                    .padding()
                
                // Avatar Image Picker
                Button(action: {
                    showImagePicker = true
                }) {
                    ZStack {
                        if let avatarImage = avatarImage {
                            Image(uiImage: avatarImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "camera")
                                        .foregroundColor(.gray)
                                )
                        }
                    }
                }
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(selectedImage: $avatarImage)
                }
                
                // User Info Fields
                TextField("Username", text: $username)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                    .keyboardType(.emailAddress)
                
                TextField("Age", value: $age, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                TextField("Bio", text: $bio)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                // Error Message Display
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Spacer()
                
                // Create Profile Button
                Button("Create Profile") {
                    createProfile()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $hasProfile) {
                ExploringView(currentUserProfile: $currentUserProfile, hasProfile: $hasProfile)
            }
        }
    }
    
    private func createProfile() {
        print("Age value: \(String(describing: age))")
        guard !username.isEmpty, !email.isEmpty, !bio.isEmpty, let validAge = age, validAge > 0 else {
            errorMessage = "Please fill in all fields correctly."
            return
        }
        
        let profile = UserProfile(context: context)
        profile.username = username
        profile.email = email
        profile.bio = bio
        profile.age = Int16(validAge)
        profile.isLoggedIn = true
        
        if let avatarImage = avatarImage {
            let imageName = "avatar_\(username)"
            if let savedURL = ImageManager.saveImage(avatarImage, withName: imageName) {
                profile.avatarURL = savedURL.absoluteString
            }
        }
        
        do {
            try context.save()
            proximityManager.currentUserProfile = profile
            currentUserProfile = profile
            hasProfile = true
            print("hasProfile in ProfileSignupView (inside createProfile): \(hasProfile)")
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
        }
    }
}
