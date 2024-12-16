import Foundation
import CoreData

@objc(ChatRoom)
public class ChatRoom: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChatRoom> {
        return NSFetchRequest<ChatRoom>(entityName: "ChatRoom")
    }

    @NSManaged public var roomID: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var peerDevice: NSSet?
    @NSManaged public var messages: NSSet?

    // Custom Logic or Methods
}

// MARK: - Generated Accessors for peerDevice
extension ChatRoom {

    @objc(addPeerDeviceObject:)
    @NSManaged public func addToPeerDevice(_ value: PeerDevice)

    @objc(removePeerDeviceObject:)
    @NSManaged public func removeFromPeerDevice(_ value: PeerDevice)

    @objc(addPeerDevice:)
    @NSManaged public func addToPeerDevice(_ values: NSSet)

    @objc(removePeerDevice:)
    @NSManaged public func removeFromPeerDevice(_ values: NSSet)

}

// MARK: - Generated Accessors for messages
import CoreData

// Assuming ChatRoom is related to Messages
extension ChatRoom {
    
    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: Messages) // Use "Messages" here to match the entity
    
    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: Messages)
    
    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)
    
    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)
}

extension ChatRoom : Identifiable {

}
