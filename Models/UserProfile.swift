import Foundation
import CoreData
import MultipeerConnectivity

@objc(UserProfile)
public class UserProfile: NSManagedObject {

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
    @NSManaged public var messages: NSSet?
    @NSManaged public var socialMediaLinks: NSSet?
    @NSManaged public var userRating: UserRating?

    @NSManaged public var peerID: MCPeerID?  // Corrected to MCPeerID

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

    // MARK: - Equatable Conformance
    public static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        return lhs.peerID == rhs.peerID
    }

    // MARK: - Messages Relationship Accessors
    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: Messages)

    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: Messages)

    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)

    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)

    // MARK: - SocialMediaLinks Relationship Accessors
    @objc(addSocialMediaLinksObject:)
    @NSManaged public func addToSocialMediaLinks(_ value: SocialMediaLink)

    @objc(removeSocialMediaLinksObject:)
    @NSManaged public func removeFromSocialMediaLinks(_ value: SocialMediaLink)

    @objc(addSocialMediaLinks:)
    @NSManaged public func addToSocialMediaLinks(_ values: NSSet)

    @objc(removeSocialMediaLinks:)
    @NSManaged public func removeFromSocialMediaLinks(_ values: NSSet)

    // MARK: - PeerDevice Relationship Accessors
    @objc(addPeerDeviceObject:)
    @NSManaged public func addToPeerDevice(_ value: PeerDevice)

    @objc(removePeerDeviceObject:)
    @NSManaged public func removeFromPeerDevice(_ value: PeerDevice)

    @objc(addPeerDevice:)
    @NSManaged public func addToPeerDevice(_ values: NSSet)

    @objc(removePeerDevice:)
    @NSManaged public func removeFromPeerDevice(_ values: NSSet)

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

    // MARK: - Message Management Methods
    public func addMessage(content: String, context: NSManagedObjectContext) {
        let newMessage = Messages.createMessage(content: content, userProfile: self, context: context)
        addToMessages(newMessage)
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

extension UserProfile: Identifiable { }
