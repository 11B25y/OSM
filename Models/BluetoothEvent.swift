import Foundation
import CoreData

@objc(BluetoothEvent)
public class BluetoothEvent: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<BluetoothEvent> {
        return NSFetchRequest<BluetoothEvent>(entityName: "BluetoothEvent")
    }

    @NSManaged public var deviceInfo: String?
    @NSManaged public var eventType: String?
    @NSManaged public var timeStamp: Date?
    @NSManaged public var peer: PeerDevice?  // Relationship to PeerDevice

    // Example method
    func formattedEventDate() -> String? {
        guard let timeStamp = timeStamp else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timeStamp)
    }
}
