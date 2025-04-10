import SwiftUI

struct Node: Identifiable {
    let id: String
    var position: CGPoint
    var velocity: CGPoint = .zero
    var isSelected: Bool = false
    var peer: SelectedPeer? // Ensure this exists
}
