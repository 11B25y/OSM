import Foundation
import CoreData

@objc(UserRating)
public class UserRating: NSManagedObject {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserRating> {
        return NSFetchRequest<UserRating>(entityName: "UserRating")
    }
    
    @NSManaged public var rating: Float
    @NSManaged public var timestamp: Date?
    @NSManaged public var peer: PeerDevice?  // Relationship to PeerDevice
}
