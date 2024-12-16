import Foundation
import CoreData

@objc(PeerDevice)
public class PeerDevice: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PeerDevice> {
        return NSFetchRequest<PeerDevice>(entityName: "PeerDevice")
    }

    // MARK: - Core Data Attributes
    @NSManaged public var deviceID: String?
    @NSManaged public var lastConnected: Date?
    @NSManaged public var name: String?
    @NSManaged public var bluetoothEvents: NSSet?
    @NSManaged public var chatRooms: NSSet?
    @NSManaged public var fileTransfer: NSSet?
    @NSManaged public var ratings: NSSet?
    @NSManaged public var user: UserProfile?

    // MARK: - Generated Accessors for bluetoothEvents Relationship
    @objc(addBluetoothEventsObject:)
    @NSManaged public func addToBluetoothEvents(_ value: BluetoothEvent)

    @objc(removeBluetoothEventsObject:)
    @NSManaged public func removeFromBluetoothEvents(_ value: BluetoothEvent)

    @objc(addBluetoothEvents:)
    @NSManaged public func addToBluetoothEvents(_ values: NSSet)

    @objc(removeBluetoothEvents:)
    @NSManaged public func removeFromBluetoothEvents(_ values: NSSet)

    // MARK: - Generated Accessors for chatRooms Relationship
    @objc(addChatRoomsObject:)
    @NSManaged public func addToChatRooms(_ value: ChatRoom)

    @objc(removeChatRoomsObject:)
    @NSManaged public func removeFromChatRooms(_ value: ChatRoom)

    @objc(addChatRooms:)
    @NSManaged public func addToChatRooms(_ values: NSSet)

    @objc(removeChatRooms:)
    @NSManaged public func removeFromChatRooms(_ values: NSSet)

    // MARK: - Generated Accessors for fileTransfer Relationship
    @objc(addFileTransferObject:)
    @NSManaged public func addToFileTransfer(_ value: FileTransfer)

    @objc(removeFileTransferObject:)
    @NSManaged public func removeFromFileTransfer(_ value: FileTransfer)

    @objc(addFileTransfer:)
    @NSManaged public func addToFileTransfer(_ values: NSSet)

    @objc(removeFileTransfer:)
    @NSManaged public func removeFromFileTransfer(_ values: NSSet)

    // MARK: - Generated Accessors for ratings Relationship
    @objc(addRatingsObject:)
    @NSManaged public func addToRatings(_ value: UserRating)

    @objc(removeRatingsObject:)
    @NSManaged public func removeFromRatings(_ value: UserRating)

    @objc(addRatings:)
    @NSManaged public func addToRatings(_ values: NSSet)

    @objc(removeRatings:)
    @NSManaged public func removeFromRatings(_ values: NSSet)
}

extension PeerDevice: Identifiable { }
