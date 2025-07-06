import SwiftUI
import MultipeerConnectivity

struct InviteView: View {
    var peer: SelectedPeer? // The peer you are sending the invite to
    
    @State private var isInviteSent = false

    var body: some View {
        VStack {
            if let peer = peer {
                Text("Send invite to \(peer.profile?.wrappedUsername ?? "Unknown User")")
                    .font(.title)
                    .padding()

                Text("Are you sure you want to send an invite to \(peer.profile?.wrappedUsername ?? "Unknown User")?")
                    .padding()

                Button(action: {
                    sendInvite()
                }) {
                    Text("Send Invite")
                        .font(.headline)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                
                if isInviteSent {
                    Text("Invite Sent!")
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
    }

    func sendInvite() {
        if let peer = peer {
            ProximityManager.shared.invite(peer.peerID)
            isInviteSent = true
        }
    }
}
