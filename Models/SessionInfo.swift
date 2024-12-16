import Foundation
import CoreData

@objc(SessionInfo)
public class SessionInfo: NSManagedObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SessionInfo> {
        return NSFetchRequest<SessionInfo>(entityName: "SessionInfo")
    }

    @NSManaged public var sessionID: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var messages: NSSet?  // Relationship to Message

    // Custom function to format session duration
    func sessionDuration() -> TimeInterval? {
        guard let start = startDate, let end = endDate else {
            return nil
        }
        return end.timeIntervalSince(start)
    }
}
