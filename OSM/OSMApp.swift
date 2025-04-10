import SwiftUI
import CoreData
import MultipeerConnectivity

@main
struct osmApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate // Link AppDelegate
    let persistenceController = PersistenceController.shared
    @Environment(\.scenePhase) var scenePhase // Observe scene phase changes
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @State private var showWelcomeScreen = true
    @State private var showProfilePageView = false
    @State private var hasProfile: Bool = false
    @State private var currentUserProfile: UserProfile?
    @State private var showImagePicker: Bool = false
    @State private var isCreatingProfile: Bool = false
    
    // LocationManager initialization
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var proximityManager = ProximityManager(context: PersistenceController.shared.container.viewContext)
    
    init() {
        // Pass the ProximityManager to the AppDelegate
        appDelegate.proximityManager?.loadLoggedInProfile() // Load profile before discovery
        appDelegate.proximityManager?.startDiscovery() // Start discovery on initialization
    }
    
    var body: some Scene {
        WindowGroup {
            if let proximityManager = appDelegate.proximityManager {
                if !hasSeenOnboarding {
                    OnboardingView()
                        .onDisappear {
                            hasSeenOnboarding = true
                        }
                        .environment(\.managedObjectContext, persistenceController.container.viewContext)
                } else {
                    if !isLoggedIn || proximityManager.currentUserProfile == nil {
                        ProfileSignupView(hasProfile: $hasProfile, currentUserProfile: $currentUserProfile)
                            .environmentObject(proximityManager)
                            .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    } else {
                        ExploringView(currentUserProfile: $currentUserProfile, hasProfile: $hasProfile)
                            .environmentObject(proximityManager)
                            .environmentObject(locationManager) // Pass LocationManager to ExploringView
                            .environment(\.managedObjectContext, persistenceController.container.viewContext)
                            .navigationBarItems(trailing: Button(action: {
                                showProfilePageView.toggle()
                            }) {
                                Image(systemName: "person.circle")
                                    .font(.title)
                            })
                            .sheet(isPresented: $showProfilePageView) {
                                if proximityManager.currentUserProfile != nil {
                                    ProfilePageView(
                                        hasProfile: $hasProfile,
                                        profile: $currentUserProfile,
                                        isCreatingProfile: Binding.constant(false),
                                        peer: proximityManager.getPeerID()
                                    )
                                    .environmentObject(proximityManager)
                                    .environmentObject(locationManager) // Pass LocationManager to ProfilePageView
                                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                                } else {
                                    Text("No Profile Data Available")
                                }
                            }
                            .onAppear {
                                proximityManager.populateProfileIfNeeded() // Ensure profile is loaded
                                locationManager.startUpdatingLocation() // Start location updates when the view appears
                            }
                            .onDisappear {
                                locationManager.stopUpdatingLocation() // Stop location updates when the view disappears
                            }
                    }
                }
            } else {
                Text("Error initializing ProximityManager")
            }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                locationManager.startUpdatingLocation()
            case .background:
                locationManager.stopUpdatingLocation()
            default:
                break
            }
        }
    }
}
