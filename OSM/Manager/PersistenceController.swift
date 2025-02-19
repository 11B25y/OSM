import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Model") // ✅ Ensure correct Core Data model name

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        // Ensure Core Data automatically migrates stores if possible
        container.persistentStoreDescriptions.forEach { description in
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }

        // Load Persistent Store
        container.loadPersistentStores { [weak self] storeDescription, error in
            if let error = error as NSError? {
                print("❌ Persistent store loading error: \(error.localizedDescription)")

                // Reset Core Data store if migration fails
                if error.code == NSPersistentStoreIncompatibleVersionHashError ||
                   error.code == NSPersistentStoreOpenError {
                    self?.resetPersistentStore()
                }
            }
        }
    }

    // MARK: - Reset Persistent Store if Migration Fails
    private func resetPersistentStore() {
        guard let storeURL = container.persistentStoreDescriptions.first?.url else { return }
        let fileManager = FileManager.default

        do {
            try fileManager.removeItem(at: storeURL)
            print("🗑 Deleted incompatible Core Data store. Restarting...")

            container.loadPersistentStores { _, error in
                if let error = error as NSError? {
                    fatalError("❌ Persistent store reload error: \(error), \(error.userInfo)")
                }
            }
        } catch {
            fatalError("❌ Failed to delete old Core Data store: \(error.localizedDescription)")
        }
    }

    // MARK: - Save Context
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data changes saved successfully.")
            } catch {
                let nserror = error as NSError
                fatalError("❌ Unresolved Core Data error: \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
