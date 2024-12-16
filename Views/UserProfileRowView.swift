import SwiftUICore
import UIKit
struct UserProfileRowView: View {
    @State private var profileImageName: String = "profileImage"
    @State private var showImagePicker: Bool = false
    let user: User // Assuming this user object holds the actual profile image
    
    var body: some View {
        HStack {
            // Display profile image if available, else fallback to system icon
            if let imageURL = user.image, let uiImage = UIImage(contentsOfFile: imageURL) {
                Image(uiImage: uiImage)
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            } else {
                ProfileImageView(
                    profileImageName: profileImageName,
                    size: 40,
                    isTappable: true
                ) {
                    showImagePicker = true // Trigger image picker when the profile image is tapped
                }
                VStack(alignment: .leading) {
                    Text(user.name)
                        .font(.headline)
                    Text(user.bio)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
        }
    }
}
