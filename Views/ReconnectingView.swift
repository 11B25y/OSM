import SwiftUI

struct ReconnectingView: View {
    @State private var isAnimating = false
    @State private var gradientColors: [Color] = [.blue, .purple, .red, .orange]

    var body: some View {
        ZStack {
            Circle()
                .stroke(AngularGradient(gradient: Gradient(colors: gradientColors),
                                        center: .center),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .frame(width: 80, height: 80)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .animation(.linear(duration: 1).repeatForever(autoreverses: false), value: isAnimating)
                .onAppear {
                    isAnimating = true
                }

            Circle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle().stroke(LinearGradient(gradient: Gradient(colors: [.blue, .purple]),
                                                   startPoint: .topLeading,
                                                   endPoint: .bottomTrailing), lineWidth: 5)
                )
                .scaleEffect(isAnimating ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
        }
    }
}
