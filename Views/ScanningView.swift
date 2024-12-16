import SwiftUI

struct ScanningView: View {
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack {
            // Pulsating Circle Animation
            Circle()
                .fill(Color.purple.opacity(0.5))
                .frame(width: 100, height: 100)
                .scaleEffect(scale)
                .opacity(1.0 - Double(scale - 1)) // Reduces opacity as it grows
                .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true), value: scale)
            
            // Scanning Label
            Text("Scanning for peers...")
                .foregroundColor(.gray)
                .padding()
        }
        .onAppear {
            scale = 1.5 // Start the animation when the view appears
        }
    }
}
