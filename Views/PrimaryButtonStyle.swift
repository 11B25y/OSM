import SwiftUI
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .padding()
            .foregroundColor(.white)
            .background(configuration.isPressed ? Color.blue.opacity(0.8) : Color.blue)
            .cornerRadius(10)
            .shadow(radius: 5)
            .scaleEffect(configuration.isPressed ? 1.05 : 1)
    }
}
