import Foundation
import MultipeerConnectivity

struct SelectedPeer: Identifiable {
    var id: UUID
    var peerID: MCPeerID  // Change to MCPeerID to match UserProfile
    var profile: UserProfile?  // Assuming the profile is linked to a UserProfile object
    var displayName: String { peerID.displayName }
}
