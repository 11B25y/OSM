import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    var proximityManager: ProximityManager?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize the ProximityManager with the Core Data context
        proximityManager = ProximityManager.shared // ✅ Use the shared instance
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Ensure the user is marked as offline when the app terminates
        proximityManager?.markCurrentUserAsOffline()
    }
}
