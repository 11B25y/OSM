import SwiftUICore
struct PeerBubbleView: View {
    let peer: IdentifiablePeer // Peer being displayed in the bubble

    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 80, height: 80) // Adjust bubble size

                Text(peer.displayName.prefix(1)) // Display initial for the peer
                    .font(.largeTitle)
                    .foregroundColor(.white)
            }

            Text(peer.displayName)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(10)
        .shadow(radius: 4)
        .onTapGesture {
            print("Tapped on peer: \(peer.displayName)")
            // Add action for tapping on a peer (e.g., send invitation)
        }
    }
}
