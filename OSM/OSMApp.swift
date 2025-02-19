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
    @StateObject private var locationManager = LocationManager()
    @State private var showProfilePageView = false
    @State private var hasProfile: Bool = false
    @State private var currentUserProfile: UserProfile?
    @State private var showImagePicker: Bool = false
    @State private var isCreatingProfile: Bool = false
    
    
    init() {
        // Pass the ProximityManager to the AppDelegate
        appDelegate.proximityManager?.startDiscovery()
        
        // Request location authorization
        locationManager.requestAuthorization()
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
                                    .environmentObject(locationManager) // Pass LocationManager
                                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                                } else {
                                    Text("No Profile Data Available")
                                }
                            }
                            .onAppear {
                                proximityManager.populateProfileIfNeeded() // Ensure profile is loaded
                                locationManager.startUpdatingLocation() // Start location updates
                            }
                            .onDisappear {
                                locationManager.stopUpdatingLocation() // Stop location updates
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
                print("App became active")
                // Restart discovery and attempt reconnection
                appDelegate.proximityManager?.startDiscovery()
                appDelegate.proximityManager?.loadAndReconnectPeers()
                
            case .inactive:
                print("App became inactive")
                // Optionally stop sensitive tasks or save the current state
                
            case .background:
                print("App moved to background")
                // Mark the user offline and stop discovery to save resources
                appDelegate.proximityManager?.markCurrentUserAsOffline()
                appDelegate.proximityManager?.stopDiscovery()
                
            @unknown default:
                print("Unknown scene phase")
            }
        }
    }
}
