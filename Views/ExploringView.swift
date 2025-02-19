import SwiftUI
import Combine
import MultipeerConnectivity

struct ExploringView: View {
    @EnvironmentObject private var proximityManager: ProximityManager
    @Binding var currentUserProfile: UserProfile?
    @Binding var hasProfile: Bool
    @State private var selectedPeer: SelectedPeer?
    @State private var enlargedProfile: UserProfile?
    @State private var isProfileSelected: Bool = false
    @State private var isCreatingProfile: Bool = false
    @State private var showProfile: Bool = false
    @State private var selectedImage: UIImage?
    @State private var showImagePicker: Bool = false
    @State private var profileImageName: String = "profileImage"
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showError = false
    @State private var errorMessage: String = ""
    @State private var isDarkMode: Bool = false
    @State private var showMenu: Bool = false
    @State private var menuOffset: CGFloat = -300
    @State private var contentOffset: CGFloat = 0
    @State private var menuWidth: CGFloat = UIScreen.main.bounds.width * 0.6

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
                
                        Button(action: {
                            if let userProfile = currentUserProfile {
                                enlargedProfile = userProfile // Assign user profile directly
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
                            connectedPeerBubblesView()
                        }
                        Spacer()
                    }
                    .offset(x: contentOffset)
                    .scaleEffect(showMenu ? 0.8 : 1.0)
                }

                // ✅ PROFILE PAGE SHEET (For when profile icon is tapped)
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

                .sheet(isPresented: $showImagePicker) {
                    ImagePicker(selectedImage: $selectedImage)
                        .onDisappear {
                            if let image = selectedImage {
                                if let savedURL = ImageManager.saveImage(image, withName: "UserProfileImage") {
                                    print("Image saved at: \(savedURL)")
                                }
                            }
                        }
                }

                .onAppear {
                    proximityManager.startDiscovery()
                    setupErrorHandling()
                    // Debugging connected peers
                    print("Connected Peers: \(proximityManager.connectedPeers.map { $0.peerID.displayName })")
                }
                .onDisappear {
                    proximityManager.stopDiscovery()
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

            // Side Menu
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

                            // Page 3 (Empty/Reserved)
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

                            CustomToggle(isOn: $isDarkMode)
                                .frame(width: 6, height: 3) // Smaller than before
                                .scaleEffect(0.25) // Slightly smaller scale
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

    private func toggleMenu() {
        withAnimation {
            showMenu.toggle()
            menuOffset = showMenu ? 0 : -300
            contentOffset = showMenu ? menuWidth : 0
        }
    }

    private func setupErrorHandling() {
        proximityManager.$error
            .compactMap { $0?.localizedDescription }
            .sink { errorDescription in
                errorMessage = errorDescription
                showError = true
            }
            .store(in: &cancellables)
    }

    private func connectedPeerBubblesView() -> some View {
        ZStack {
            ForEach(proximityManager.connectedPeers, id: \.peerID) { peer in
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
                                print("Tapped on peer: \(peer.profile?.wrappedUsername ?? "Unknown")")
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

    private func setAppearance(isDark: Bool) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = isDark ? .dark : .light
            }
        }
    }
}
