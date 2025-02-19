import Foundation
import CoreData
import MultipeerConnectivity

@objc(UserProfile)
public class UserProfile: NSManagedObject {
    // MARK: - Fetch Request
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProfile> {
        return NSFetchRequest<UserProfile>(entityName: "UserProfile")
    }

    // MARK: - Core Data Attributes
    @NSManaged public var age: Int16
    @NSManaged public var avatarURL: String?
    @NSManaged public var bio: String?
    @NSManaged public var email: String?
    @NSManaged public var isLoggedIn: Bool
    @NSManaged public var status: String?
    @NSManaged public var username: String?
    @NSManaged public var peerID: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var matchedTimestamp: Date? // Ensured optional handling
    @NSManaged public var messages: NSSet?
    @NSManaged public var peerDevice: NSSet?
    @NSManaged public var socialMediaLinks: NSSet?
    @NSManaged public var socialMediaRequests: NSSet?
    @NSManaged public var userRating: UserRating?
    @NSManaged public var isPremiumUser: Bool

    // MARK: - Computed Properties
    public var wrappedUsername: String {
        username ?? "Unknown User"
    }

    public var wrappedEmail: String {
        email ?? "No Email Provided"
    }

    public var wrappedStatus: String {
        status ?? "No Status"
    }

    public var wrappedBio: String {
        bio ?? "No Bio"
    }

    public var wrappedAvatarURL: URL? {
        if let urlString = avatarURL {
            return URL(string: urlString)
        }
        return nil
    }

    public var wrappedLatitude: Double {
        latitude
    }

    public var wrappedLongitude: Double {
        longitude
    }

    // MARK: - PeerID Handling
    public var peerIDObject: MCPeerID? {
        get {
            guard let peerIDString = peerID else { return nil }
            return MCPeerID(displayName: peerIDString)
        }
        set {
            peerID = newValue?.displayName
        }
    }

    // MARK: - Equatable Conformance
    public static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        return lhs.peerID == rhs.peerID
    }

    // MARK: - Profile Management Methods
    public func updateProfile(username: String, email: String, bio: String, avatarURL: String, context: NSManagedObjectContext) {
        self.username = username
        self.email = email
        self.bio = bio
        self.avatarURL = avatarURL

        do {
            try context.save()
            print("Profile updated successfully.")
        } catch {
            print("Failed to update profile: \(error.localizedDescription)")
        }
    }

    // MARK: - Fetch Logged-In User Helper
    public class func fetchLoggedInUser(context: NSManagedObjectContext) -> UserProfile? {
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "isLoggedIn == true")
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("Failed to fetch logged-in user: \(error.localizedDescription)")
            return nil
        }
    }
}

// MARK: - Generated Accessors for Relationships
extension UserProfile {
    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: Messages)

    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: Messages)

    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)

    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)

    @objc(addPeerDeviceObject:)
    @NSManaged public func addToPeerDevice(_ value: PeerDevice)

    @objc(removePeerDeviceObject:)
    @NSManaged public func removeFromPeerDevice(_ value: PeerDevice)

    @objc(addPeerDevice:)
    @NSManaged public func addToPeerDevice(_ values: NSSet)

    @objc(removePeerDevice:)
    @NSManaged public func removeFromPeerDevice(_ values: NSSet)

    @objc(addSocialMediaLinksObject:)
    @NSManaged public func addToSocialMediaLinks(_ value: SocialMediaLink)

    @objc(removeSocialMediaLinksObject:)
    @NSManaged public func removeFromSocialMediaLinks(_ value: SocialMediaLink)

    @objc(addSocialMediaLinks:)
    @NSManaged public func addToSocialMediaLinks(_ values: NSSet)

    @objc(removeSocialMediaLinks:)
    @NSManaged public func removeFromSocialMediaLinks(_ values: NSSet)
}

// MARK: - Identifiable Protocol
extension UserProfile: Identifiable {}
