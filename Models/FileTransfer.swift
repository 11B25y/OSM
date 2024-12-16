import Foundation
import CoreData

@objc(FileTransfer)
public class FileTransfer: NSManagedObject {
    // Add any necessary functions or logic related to FileTransfer here
}

extension FileTransfer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FileTransfer> {
        return NSFetchRequest<FileTransfer>(entityName: "FileTransfer")
    }

    @NSManaged public var fileName: String?
    @NSManaged public var fileSize: Int64
    @NSManaged public var timeStamp: Date?
    @NSManaged public var peer: PeerDevice?

    // Additional functions (optional)
    func formattedFileSize() -> String {
        if fileSize > 1024 * 1024 {
            return "\(fileSize / (1024 * 1024)) MB"
        } else if fileSize > 1024 {
            return "\(fileSize / 1024) KB"
        } else {
            return "\(fileSize) bytes"
        }
    }
}
