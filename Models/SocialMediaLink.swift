import Foundation
import CoreData

@objc(SocialMediaLink)
public class SocialMediaLink: NSManagedObject {
    // Custom methods for SocialMediaLink can be added here if necessary
}

extension SocialMediaLink {
    
    // MARK: - Fetch Request
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SocialMediaLink> {
        return NSFetchRequest<SocialMediaLink>(entityName: "SocialMediaLink")
    }

    // MARK: - Attributes
    @NSManaged public var platform: String?
    @NSManaged public var url: String?

    // MARK: - Relationships
    @NSManaged public var userProfile: UserProfile?
    
    // MARK: - Computed Properties for Safe Unwrapping
    public var wrappedPlatform: String {
        platform ?? "Unknown Platform"
    }

    public var wrappedURL: URL? {
        if let urlString = url {
            return URL(string: urlString)
        }
        return nil
    }
    
    // MARK: - Example Method for Constructing Social Media Link
    // You can add methods here to handle specific tasks related to SocialMediaLink
    // For example, checking if a URL is valid, formatting, etc.
}
