import SwiftUI
import MultipeerConnectivity

struct ContentView: View {
    @EnvironmentObject private var proximityManager: ProximityManager
    @State private var selectedPeer: SelectedPeer?
    @State private var selectedUser: UserProfile? = nil
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isShowingAlert = false
    @State private var hasProfile: Bool = false
    @State private var currentUserProfile: UserProfile?
    @State private var showProfilePage: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var isCreatingProfile: Bool = false  // This is to allow editing profile
    @State private var currentUser: UserProfile? // Declare as state in parent view
    @State private var profile: UserProfile?
    @State private var showProfileCreationView = false
    @State private var navigateToExploring = false
    @State private var nearbyUsers: [UserProfile] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemBackground).edgesIgnoringSafeArea(.all)
                
                VStack {
                         if !hasProfile {
                             // ProfileSignupView is shown when the user doesn't have a profile
                             ProfileSignupView(hasProfile: $hasProfile, currentUserProfile: $currentUserProfile) // Pass bindings here
                         } else {
                        // Main content when profile exists
                        if let profile = currentUserProfile {
                            Text("Welcome \(profile.username)")
                        }
                        else {
                            if proximityManager.isScanning {
                                ScanningView()
                            } else if proximityManager.connectedPeers.isEmpty {
                                NearbyUsersView(nearbyUsers: nearbyUsers, selectedUser: $selectedUser)
                            } else {
                                ConnectedPeersView()
                            }
                            if showProfilePage {
                                ProfilePageView(
                                    hasProfile: $hasProfile,
                                    profile: $currentUserProfile, isCreatingProfile: $isCreatingProfile,  // Pass the Binding to allow mutation
                                    peer: proximityManager.getPeerID()  // Correct binding for profile
                                )
                                .padding()
                            }
                            
                            if let user = selectedUser {
                                Text("Selected User: \(user.wrappedUsername)") 
                            } else {
                                Text("Select a user to view their profile and connect")
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                        }
                    }
                }
                .navigationTitle("Proximity Network")
                .onAppear {
                    if !isShowingAlert && hasProfile {
                        isShowingAlert = true
                        proximityManager.startDiscovery()
                    }
                }
                .onDisappear {
                    isShowingAlert = false
                    proximityManager.stopDiscovery()
                }
                .alert(item: $proximityManager.receivedInvitationFromPeer) { peer in
                    if !isShowingAlert {
                        isShowingAlert = true
                        return Alert(
                            title: Text("Received Invitation"),
                            message: Text("You have received an invitation from \(peer.peerID.displayName)"),
                            primaryButton: .default(Text("Accept")) {
                                proximityManager.respondToInvitation(accepted: true)
                                isShowingAlert = false
                            },
                            secondaryButton: .cancel(Text("Decline")) {
                                proximityManager.respondToInvitation(accepted: false)
                                isShowingAlert = false
                            }
                        )
                    } else {
                        return Alert(
                            title: Text("Notice"),
                            message: Text("An alert is already being shown."),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
                .alert(isPresented: $showError) {
                    Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")) {
                        isShowingAlert = false
                    })
                }
                .sheet(item: $selectedPeer) { peer in
                    ProfilePageView(
                        hasProfile: $hasProfile,
                        profile: $currentUserProfile,  // Profile argument comes first
                        isCreatingProfile: Binding.constant(false),  // isCreatingProfile argument comes second
                        peer: proximityManager.getPeerID()
                    )
                }
                .onReceive(proximityManager.$error.compactMap { $0 }) { error in
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
               .onChange(of: hasProfile) { newValue in
                   if newValue {
                       navigateToExploring = true // Trigger navigation once profile is created
                   }
               }
               .sheet(isPresented: $navigateToExploring) {
                   // Once profile is created, navigate to ExploringView
                   ExploringView(currentUser: $currentUserProfile)
    }
    }
}

    // Subview for displaying a selected user's profile
    struct SelectedUserProfileView: View {
        let user: User
        @Binding var selectedUser: User?
        @State private var inviteStatus: InviteStatus = .notSent
        @State private var isShowingError = false
        @State private var errorMessage = ""
        
        enum InviteStatus {
            case notSent, pending, accepted
        }
        
        var body: some View {
            VStack(spacing: 20) {
                // User info
                VStack(spacing: 10) {
                    Text("\(user.name), \(user.age)")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(user.bio)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Interaction buttons
                HStack(spacing: 20) {
                    Button(action: { selectedUser = nil }) {
                        Label("Dismiss", systemImage: "xmark.circle")
                    }
                    .accessibilityLabel("Dismiss profile")
                    
                    switch inviteStatus {
                    case .notSent:
                        Button(action: sendInvite) {
                            Label("Send Invite", systemImage: "envelope")
                        }
                        .accessibilityLabel("Send invite to \(user.name)")
                    case .pending:
                        Label("Invite Pending", systemImage: "clock")
                            .foregroundColor(.orange)
                    case .accepted:
                        Button(action: sendMessage) {
                            Label("Message", systemImage: "message")
                        }
                        .accessibilityLabel("Send message to \(user.name)")
                    }
                }
                .labelStyle(IconOnlyLabelStyle())
                .buttonStyle(BorderedButtonStyle())
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(15)
            .shadow(radius: 5)
            .alert(isPresented: $isShowingError) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
        }
        
        private func sendInvite() {
            // Simulating network request
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                // In a real app, you'd handle success/failure based on the response
                let success = Bool.random()
                if success {
                    inviteStatus = .pending
                    // In a real app, you'd listen for updates to change this to .accepted
                } else {
                    isShowingError = true
                    errorMessage = "Failed to send invite. Please try again."
                }
            }
        }
        
        private func sendMessage() {
            print("Messaging \(user.name)")
            // Implement actual messaging logic here
        }
    }
    
    // Subview for navigation links
struct NavigationLinksView: View {
    @Binding var currentUser: UserProfile?
    var body: some View {
        VStack {
            NavigationLink(
                "Explore Connected Peers",
                destination: ExploringView(currentUser: $currentUser)
            )
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            NavigationLink(destination: SettingsView()) {
                Text("Settings")
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
    }
}
    

