import SwiftUI

struct NodeView: View {
    let node: Node
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            if let peer = node.peer, let profileImageURL = peer.profile?.avatarURL {
                ProfileImageView(
                    profileImageName: profileImageURL,
                    size: 50,
                    isTappable: false
                )
                .overlay(Circle().stroke(isSelected ? Color.blue : Color.gray, lineWidth: 2))
                .shadow(radius: isSelected ? 6 : 3)
            } else {
                Circle()
                    .fill(isSelected ? Color.white : Color.gray)
                    .frame(width: 8, height: 8)
            }
            
            Text(node.id)
                .font(.system(size: 10))
                .foregroundColor(.white)
        }
    }
}
