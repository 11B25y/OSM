import SwiftUI

struct GraphView: View {
    @State private var nodes: [Node] = []

    @State private var selectedNode: Node?
    @State private var isAnimating = true

    let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(.black)
                    .edgesIgnoringSafeArea(.all)

                ForEach(nodes.indices, id: \.self) { index in
                    NodeView(node: nodes[index], isSelected: nodes[index].id == selectedNode?.id)
                        .position(nodes[index].position)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    nodes[index].position = value.location
                                    selectedNode = nodes[index]
                                }
                        )
                }
            }
            .onAppear {
                initializeNodes() // Ensures nodes are correctly initialized with peers
            }
            .onReceive(timer) { _ in
                guard isAnimating else { return }
                updateNodePositions(in: geometry.size)
            }
        }
    }

    private func initializeNodes() {
        // Fetch connected peers and create nodes
        let connectedPeers = fetchConnectedPeers() // Implement this function
        nodes = connectedPeers.map { peer in
            Node(id: peer.peerID.displayName, position: randomPosition(), peer: peer)
        }
    }

    private func fetchConnectedPeers() -> [SelectedPeer] {
        return ProximityManager.shared.connectedPeers
    }
    
    private func randomPosition() -> CGPoint {
        return CGPoint(x: CGFloat.random(in: 50...300), y: CGFloat.random(in: 50...300))
    }

    private func updateNodePositions(in size: CGSize) {
        let repulsionForce: CGFloat = 1000
        let springForce: CGFloat = 0.5
        let damping: CGFloat = 0.8

        for i in nodes.indices {
            var totalForce = CGPoint.zero

            for j in nodes.indices where i != j {
                let dx = nodes[j].position.x - nodes[i].position.x
                let dy = nodes[j].position.y - nodes[i].position.y
                let distance = sqrt(dx * dx + dy * dy)

                if distance > 0 {
                    let force = repulsionForce / (distance * distance)
                    totalForce.x -= force * dx / distance
                    totalForce.y -= force * dy / distance
                }
            }

            let centerForce = CGPoint(
                x: (size.width / 2 - nodes[i].position.x) * springForce,
                y: (size.height / 2 - nodes[i].position.y) * springForce
            )
            totalForce.x += centerForce.x
            totalForce.y += centerForce.y

            nodes[i].velocity.x = (nodes[i].velocity.x + totalForce.x) * damping
            nodes[i].velocity.y = (nodes[i].velocity.y + totalForce.y) * damping
            nodes[i].position.x += nodes[i].velocity.x
            nodes[i].position.y += nodes[i].velocity.y
        }
    }
}
