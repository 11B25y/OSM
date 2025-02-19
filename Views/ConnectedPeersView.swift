import SwiftUI
import MultipeerConnectivity

enum PeerAction: Identifiable {
    case viewProfile
    case sendInvite
    case sendMessage

    var id: String {
        switch self {
        case .viewProfile:
            return "viewProfile"
        case .sendInvite:
            return "sendInvite"
        case .sendMessage:
            return "sendMessage"
        }
    }
}

struct ConnectedPeersView: View {
    @EnvironmentObject var proximityManager: ProximityManager
    @State private var selectedPeer: SelectedPeer? = nil
    @State private var selectedAction: PeerAction? = nil  // Store selected action

    var body: some View {
        VStack {
            Text("Connected Peers")
                .font(.largeTitle)
                .padding()

            // List of connected peers
            List(proximityManager.connectedPeers, id: \.peerID) { peerInfo in
                Button(action: {
                    selectedPeer = peerInfo // Set the selected peer
                    selectedAction = nil  // Reset any previously selected action
                }) {
                    HStack {
                        // Profile Image
                        if let avatarURL = peerInfo.profile?.wrappedAvatarURL {
                            let imageData = try? Data(contentsOf: avatarURL) // Directly use the URL
                            if let uiImage = UIImage(data: imageData ?? Data()) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                            } 
                        }

                        VStack(alignment: .leading) {
                            Text(peerInfo.profile?.wrappedUsername ?? "Unknown User")
                                .font(.headline)
                            Text(peerInfo.profile?.wrappedBio ?? "No Bio")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .contextMenu {
                    Button(action: {
                        selectedAction = .viewProfile  // Set action to view profile
                    }) {
                        Label("View Profile", systemImage: "person.crop.circle")
                    }
                    Button(action: {
                        selectedAction = .sendInvite  // Set action to send invite
                    }) {
                        Label("Send Invite", systemImage: "envelope")
                    }
                    Button(action: {
                        selectedAction = .sendMessage  // Set action to send message
                    }) {
                        Label("Send Message", systemImage: "message")
                    }
                }
            }
            .listStyle(PlainListStyle())

            Spacer()
        }
        // Show the appropriate view based on the selected action
        .sheet(item: $selectedAction) { action in
            switch action {
            case .viewProfile:
                if let selectedPeer = selectedPeer, let profile = selectedPeer.profile {
                    ProfileDetailsView(profile: profile) // Pass the profile directly
                }
            case .sendInvite:
                if let selectedPeer = selectedPeer {
                    InviteView(peer: selectedPeer) // Show the InviteView for sending an invite
                }
            case .sendMessage:
                if let selectedPeer = selectedPeer {
                    MessagingView(peer: selectedPeer)
                }
            }
        }
    }
}
