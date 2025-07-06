import SwiftUI

struct MockPeer: Identifiable {
    let id = UUID()
    let name: String
    let age: Int
    let bio: String
    let image: String?
}

struct MockPeerListView: View {
    private let peers: [MockPeer] = [
        MockPeer(name: "Alice", age: 25, bio: "Loves hiking and swift", image: nil),
        MockPeer(name: "Bob", age: 30, bio: "iOS Developer and gamer", image: nil),
        MockPeer(name: "Charlie", age: 28, bio: "Coffee addict", image: nil)
    ]
    @State private var selectedPeer: MockPeer?

    var body: some View {
        NavigationStack {
            List(peers) { peer in
                HStack {
                    ProfileImageView(profileImageName: peer.image, size: 40, isTappable: false)
                    VStack(alignment: .leading) {
                        Text(peer.name).font(.headline)
                        Text(peer.bio).font(.subheadline).foregroundColor(.gray)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedPeer = peer
                }
            }
            .navigationDestination(item: $selectedPeer) { peer in
                MockPeerDetailView(peer: peer)
            }
            .navigationTitle("Mock Peers")
        }
    }
}

struct MockPeerDetailView: View {
    let peer: MockPeer
    @State private var inviteSent = false

    var body: some View {
        VStack(spacing: 20) {
            ProfileImageView(profileImageName: peer.image, size: 100, isTappable: false)
            Text(peer.name).font(.title)
            Text("Age: \(peer.age)")
            Text(peer.bio).padding()
            Button("Send Invite") { inviteSent = true }
                .buttonStyle(PrimaryButtonStyle())
            if inviteSent {
                Text("Invite Sent!").foregroundColor(.green)
            }
            Spacer()
        }
        .padding()
        .navigationTitle(peer.name)
    }
}

