import SwiftUI
import CoreData
import MultipeerConnectivity
@main
struct osmApp: App {
    let persistenceController = PersistenceController.shared
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @State private var showWelcomeScreen = true
    @StateObject private var proximityManager = ProximityManager(context: PersistenceController.shared.container.viewContext)
    @State private var showProfilePageView = false
    @State private var hasProfile: Bool = false
    @State private var currentUserProfile: UserProfile?
    @State private var showImagePicker: Bool = false
    @State private var isCreatingProfile: Bool = false
    
    var body: some Scene {
        WindowGroup {
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
                                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                            } else {
                                Text("No Profile Data Available")
                            }
                        }
                        .onAppear {
                            proximityManager.populateProfileIfNeeded() // Ensure profile is populated when the view appears
                        }
                }
            }
        }
    }
}
