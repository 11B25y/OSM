import SwiftUI
import Combine
import MultipeerConnectivity

struct ExploringView: View {
    @EnvironmentObject private var proximityManager: ProximityManager
    @EnvironmentObject var locationManager: LocationManager
    @Binding var currentUserProfile: UserProfile?
    @Binding var hasProfile: Bool
    
    @State private var selectedPeer: SelectedPeer?
    @State private var enlargedProfile: UserProfile?
    @State private var isProfileSelected: Bool = false
    @State private var isCreatingProfile: Bool = false
    @State private var showProfile: Bool = false
    @State private var selectedImage: UIImage?
    @State private var showImagePicker: Bool = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showError = false
    @State private var errorMessage: String = ""
    @State private var isDarkMode: Bool = false
    @State private var showMenu: Bool = false
    @State private var menuOffset: CGFloat = -300
    @State private var contentOffset: CGFloat = 0
    @State private var menuWidth: CGFloat = UIScreen.main.bounds.width * 0.6
    @State private var isRefreshing = false

    var body: some View {
        ZStack {
            NavigationStack {
                VStack(spacing: 0) {
                    // ✅ HEADER: Hamburger Menu + Profile Icon
                    HStack {
                        // Hamburger Menu Button
                        Button(action: toggleMenu) {
                            Image(systemName: "line.horizontal.3")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .padding(10)
                                .foregroundColor(.black)
                        }
                        Spacer()
                
                        // Profile Icon Button
                        Button(action: {
                            if let userProfile = currentUserProfile {
                                enlargedProfile = userProfile
                                showProfile = true
                            }
                        }) {
                            Image(systemName: "person.circle")
                                .resizable()
                                .frame(width: 24, height: 24)
                                .foregroundColor(.black)
                                .padding(10)
                        }
                    }
                    .padding(.horizontal)

                    // ✅ MAIN CONTENT: Connected Users or No Peers Message
                    VStack {
                        if proximityManager.connectedPeers.isEmpty {
                            Text("No connected peers")
                                .padding()
                        } else {
                            List {
                                ForEach(proximityManager.connectedPeers) { peer in
                                    HStack {
                                        Text(peer.peerID.displayName)
                                        Spacer()
                                        Button("Invite") {
                                            proximityManager.invite(peer.peerID)
                                        }
                                        Button("Message") {
                                            selectedPeer = peer
                                        }
                                    }
                                }
                            }
                            .refreshable {
                                // Refresh action: Reload peers or data here
                                refreshPeers()
                            }                        }
                        Spacer()
                    }
                    .offset(x: contentOffset)
                    .scaleEffect(showMenu ? 0.8 : 1.0)
                }

                // ✅ PROFILE PAGE SHEET
                .sheet(isPresented: $showProfile) {
                    if let profile = currentUserProfile {
                        ProfilePageView(
                            hasProfile: $hasProfile,
                            profile: .constant(profile),
                            isCreatingProfile: $isCreatingProfile
                        )
                    }
                }

                // ✅ NAVIGATION DESTINATION FOR PROFILE PAGE
                .navigationDestination(for: UserProfile.self) { profile in
                    ProfilePageView(
                        hasProfile: $hasProfile,
                        profile: $currentUserProfile,
                        isCreatingProfile: $isCreatingProfile
                    )
                }

                // ✅ IMAGE PICKER SHEET
                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(selectedImage: $selectedImage)
                        .onDisappear {
                            if let image = selectedImage {
                                if let savedURL = ImageManager.saveImage(image, withName: "UserProfileImage") {
                                    print("✅ Image saved at: \(savedURL)")
                                }
                            }
                        }
                }
                // Show MessagingView when a peer is selected
                .sheet(item: $selectedPeer) { peer in
                    MessagingView(peer: peer)
                }

                .onAppear {
                    // Ensure the logged-in user profile is loaded when the view appears
                    proximityManager.loadLoggedInProfile()  // Call the method directly
                    proximityManager.loadAndReconnectPeers() // Reload peers
                    proximityManager.populateProfileIfNeeded() // Ensure profile is populated if needed

                    proximityManager.startDiscovery() // Start discovery
                    setupErrorHandling() // Existing error handling setup
                    print("🔍 Connected Peers: \(proximityManager.connectedPeers.map { $0.peerID.displayName })")
                }
                .onDisappear {
                    proximityManager.stopDiscovery() // Keep this as it is for stopping discovery
                }
                .alert(isPresented: $showError) {
                    Alert(
                        title: Text("Error"),
                        message: Text(errorMessage),
                        dismissButton: .default(Text("OK"))
                    )
                }
                .preferredColorScheme(isDarkMode ? .dark : .light)
            }

            // ✅ SIDE MENU
            if showMenu {
                HStack {
                    VStack {
                        // Menu Items
                        VStack(spacing: 20) {
                            
                            // Settings Page
                            NavigationLink(destination:
                                SettingsView(
                                    currentUserProfile: $currentUserProfile,
                                    proximityManager: proximityManager
                                )
                            ) {
                                HStack {
                                    Image(systemName: "gear")
                                    Text("Settings")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                            }

                            // Coming Soon Placeholder
                            NavigationLink(destination: Text("Coming Soon")) {
                                HStack {
                                    Image(systemName: "star")
                                    Text("Coming Soon")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding()
                            }

                            Spacer()

                            // ✅ CUSTOM DARK MODE TOGGLE
                            CustomToggle(isOn: $isDarkMode)
                                .frame(width: 6, height: 3)
                                .scaleEffect(0.25)
                                .padding(.vertical, 2)
                                .padding(.trailing, 10)
                        }
                        .frame(width: menuWidth)
                        .frame(maxHeight: .infinity)
                        .background(Color(UIColor.systemBackground))
                        .offset(x: menuOffset)
                    }
                    Spacer()
                }
                .background(
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .onTapGesture {
                            toggleMenu()
                        }
                )
                .transition(.move(edge: .leading))
            }
        }
    }

    // Refresh method for updating peers
    private func refreshPeers() {
        // Start the refreshing state
        isRefreshing = true
        
        // Perform the logic to reload peers from ProximityManager
        proximityManager.loadAndReconnectPeers() // No need for await if this isn't async
        
        // End the refreshing state
        isRefreshing = false
    }

    /// ✅ Toggle Side Menu
    private func toggleMenu() {
        withAnimation {
            showMenu.toggle()
            menuOffset = showMenu ? 0 : -300
            contentOffset = showMenu ? menuWidth : 0
        }
    }

    /// ✅ Error Handling
    private func setupErrorHandling() {
        proximityManager.$error
            .compactMap { $0?.localizedDescription }
            .sink { errorDescription in
                errorMessage = errorDescription
                showError = true
            }
            .store(in: &cancellables)
    }

    /// ✅ Connected Peer Bubbles
    private func connectedPeerBubblesView() -> some View {
        ZStack {
            ForEach(proximityManager.connectedPeers) { peer in
                VStack {
                    Button(action: {
                        self.selectedPeer = peer
                        self.enlargedProfile = peer.profile
                        self.isProfileSelected = true
                    }) {
                        ProfileImageView(
                            profileImageName: peer.profile?.avatarURL,
                            size: enlargedProfile?.peerIDObject == peer.peerID ? 60 : 40,
                            isTappable: true,
                            onTap: {
                                print("👤 Tapped on peer: \(peer.profile?.wrappedUsername ?? "Unknown")")
                            }
                        )
                    }

                    Text(peer.profile?.wrappedUsername ?? "Unknown User")
                        .font(.system(size: 10))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 1)
                }
            }
        }
    }

    /// ✅ Set Appearance for Dark Mode
    private func setAppearance(isDark: Bool) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = isDark ? .dark : .light
            }
        }
    }
}
