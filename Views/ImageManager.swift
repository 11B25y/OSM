import UIKit

class ImageManager {
    // Save image to document directory and return its URL
    static func saveImage(_ image: UIImage, withName name: String) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        let filename = getDocumentsDirectory().appendingPathComponent("\(name).jpg")
        do {
            try data.write(to: filename)
            return filename
        } catch {
            print("Error saving image: \(error.localizedDescription)")
            return nil
        }
    }
    
    // Load image from document directory
    static func loadImage(named name: String) -> UIImage? {
        let path = getDocumentsDirectory().appendingPathComponent("\(name).jpg")
        return UIImage(contentsOfFile: path.path)
    }
    
    // Helper function to get the documents directory URL
    private static func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}
