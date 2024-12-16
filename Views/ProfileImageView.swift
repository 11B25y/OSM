import Foundation
import SwiftUI
import UIKit

struct ProfileImageView: View {
    let profileImageName: String? // Optional profile image name
    let size: CGFloat             // The size of the image view (circle)
    let isTappable: Bool          // Determines if the image is tappable
    var onTap: (() -> Void)?      // Optional closure for the tap action

    var body: some View {
        ZStack {
            // If profileImageName exists, try to load the image from file
            if let image = loadImage(named: profileImageName) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                // Fallback to a system icon if image is not available
                Image(systemName: "person.crop.circle.fill") // Default icon if image is nil
                    .resizable()
                    .frame(width: size, height: size)
                    .foregroundColor(.gray)
                    .background(Circle().fill(Color.gray.opacity(0.3))) // Circle background for the icon
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .shadow(radius: 3)
        .onTapGesture {
            if isTappable {
                onTap?()  // Trigger the tap action passed from the parent view (SignupView)
            }
        }
    }

    // Load the image from the file system or from URL
    private func loadImage(named name: String?) -> UIImage? {
        guard let name = name else { return nil }

        // Check if the name corresponds to a local file in the document directory
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("\(name).jpg")
        
        // Attempt to load image from file path
        if let image = UIImage(contentsOfFile: path.path) {
            return image
        }

        // If not found in the file system, attempt to load it from a URL if it's a valid URL
        if let url = URL(string: name), let data = try? Data(contentsOf: url), let uiImage = UIImage(data: data) {
            return uiImage
        }

        return nil
    }
}
