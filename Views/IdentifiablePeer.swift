import MultipeerConnectivity

struct IdentifiablePeer: Identifiable {
    let peerID: MCPeerID
    var id: String { peerID.displayName } // Use displayName as the unique identifier
    
    var displayName: String {
        peerID.displayName
    }
}
