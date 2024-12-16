import Foundation
import CoreData

@objc(Messages)
public class Messages: NSManagedObject {
    
    // MARK: - Fetch Request
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Messages> {
        return NSFetchRequest<Messages>(entityName: "Messages")
    }

    // MARK: - Attributes
    @NSManaged public var content: String?
    @NSManaged public var timestamp: Date?

    // MARK: - Relationships
    @NSManaged public var chatRoom: ChatRoom?
    @NSManaged public var userProfile: UserProfile?  // Define a single user profile as the sender

    // Convenience method to add a message
    public static func createMessage(content: String, userProfile: UserProfile, context: NSManagedObjectContext) -> Messages {
        let newMessage = Messages(context: context)
        newMessage.content = content
        newMessage.timestamp = Date()  // Use the current date and time as the message timestamp
        newMessage.userProfile = userProfile
        
        do {
            try context.save()
            print("Message saved successfully")
        } catch {
            print("Failed to save message: \(error.localizedDescription)")
        }
        
        return newMessage
    }
}
