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
    @State private var currentUserProfile: UserProfile? = nil
    @State private var showProfilePage: Bool = false
    @State private var showImagePicker: Bool = false
    @State private var isCreatingProfile: Bool = false
    @State private var currentUser: UserProfile?
    @State private var profile: UserProfile?
    @State private var showProfileCreationView = false
    @State private var navigateToExploring = false
    @State private var nearbyUsers: [UserProfile] = []

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).edgesIgnoringSafeArea(.all)

                VStack {
                    if !hasProfile {
                        ProfileSignupView(hasProfile: $hasProfile, currentUserProfile: $currentUserProfile)
                    } else {
                        if let profile = currentUserProfile {
                            Text("Welcome \(profile.username ?? "Guest")")
                        } else {
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
                                    profile: $currentUserProfile,
                                    isCreatingProfile: $isCreatingProfile,
                                    peer: proximityManager.getPeerID()
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
                        profile: $currentUserProfile,
                        isCreatingProfile: Binding.constant(false),
                        peer: proximityManager.getPeerID()
                    )
                }
                .onReceive(proximityManager.$error.compactMap { $0 }) { error in
                    errorMessage = error.localizedDescription
                    showError = true
                }
                .navigationDestination(isPresented: $navigateToExploring) {
                    ExploringView(currentUserProfile: $currentUserProfile, hasProfile: $hasProfile)
                }
                .onChange(of: hasProfile) { oldValue, newValue in
                    if newValue {
                        navigateToExploring = true  // Trigger programmatic navigation
                    }
                }
            }
        }
    }
}

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
            VStack(spacing: 10) {
                Text("\(user.name), \(user.age)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(user.bio)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let success = Bool.random()
            if success {
                inviteStatus = .pending
            } else {
                isShowingError = true
                errorMessage = "Failed to send invite. Please try again."
            }
        }
    }
    
    private func sendMessage() {
        print("Messaging \(user.name)")
    }
}

struct NavigationLinksView: View {
    @Binding var currentUserProfile: UserProfile? // Ensure it's correctly bound here
    @Binding var hasProfile: Bool
    @EnvironmentObject var proximityManager: ProximityManager // Use @EnvironmentObject here

    var body: some View {
        VStack {
            NavigationLink(
                destination: ExploringView(
                    currentUserProfile: $currentUserProfile,
                    hasProfile: $hasProfile
                )
            ) {
                Text("Explore")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            NavigationLink(
                destination: SettingsView(
                    currentUserProfile: $currentUserProfile,
                    proximityManager: proximityManager
                )
            ) {
                Text("Settings")
            }
            .padding(.top)
        }
    }
}
