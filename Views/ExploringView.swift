import SwiftUI
import Combine
import MultipeerConnectivity


struct ExploringView: View {
    @EnvironmentObject private var proximityManager: ProximityManager
    @Binding var currentUser: UserProfile? // Accept currentUser as a binding
    @Binding var hasProfile: Bool
    @State private var selectedPeer: UserProfile?
    @State private var enlargedProfile: UserProfile?
    @State private var showProfile: Bool = false
    @State private var selectedImage: UIImage?
    @State private var showImagePicker: Bool = false
    @State private var profileImageName: String = "profileImage"
    @State private var cancellables = Set<AnyCancellable>()
    @State private var showError = false
    @State private var errorMessage: String = ""
    @State private var isDarkMode: Bool = false
    @State private var showMenu: Bool = false
    @State private var isMenuVisible: Bool = false
    @State private var showBioEditing: Bool = false
    @State private var showProfileCreationView = false
    @State private var generatedCode: String?
    
    var body: some View {
        ZStack {
            VStack {
                if proximityManager.connectedPeers.isEmpty {
                    Text("No connected peers")
                } else {
                    connectedPeerBubblesView()  // Display connected peers
                }
                
                // Explore Button
                NavigationLink(destination: ProfilePageView(
                    hasProfile: $hasProfile,
                    profile: $currentUserProfile,
                    isCreatingProfile: Binding.constant(false),
                    peer: proximityManager.getPeerID()
                )) {
                    Text("Explore")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top)
                
                VStack {
                    HStack {
                        Text("🌞").font(.system(size: 20))
                        Toggle(isOn: $isDarkMode) {
                            Text("")
                        }
                        .toggleStyle(SwitchToggleStyle(tint: .yellow))
                        .frame(width: 40, height: 20)
                        .scaleEffect(0.5)
                        Text("🌚").font(.system(size: 20))
                    }
                    .padding()
                    .onChange(of: isDarkMode) { _ in
                    }
                }
                .padding(.top)
                .preferredColorScheme(isDarkMode ? .dark : .light)
            }
            
            // ImagePicker presentation
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
        }
        .onAppear {
            proximityManager.startDiscovery()
            setupErrorHandling()
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
                    // Display profile picture and peer name
                    Button(action: {
                        // Compare peerID inside UserProfile
                        if let enlargedProfile = peer.profile {
                            if enlargedProfile.peerID == peer.peerID {
                                // Set the profile when the peerIDs match
                                self.enlargedProfile = enlargedProfile
                                self.currentUser = enlargedProfile  // Update current user with selected profile
                            }
                        }
                    }) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: enlargedProfile?.peerID == peer.peerID ? 60 : 40, height: enlargedProfile?.peerID == peer.peerID ? 60 : 40)
                            .background(Color.white)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(radius: 3)
                    }
                    Text(peer.profile?.wrappedUsername ?? "Unknown User")  // Display username or fallback
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
}
