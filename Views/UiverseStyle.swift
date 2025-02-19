import SwiftUI

// ✅ UNIVERSAL BUTTON STYLE (Uiverse-like)
struct UiverseButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .font(.system(size: 14, weight: .medium, design: .default))
            .textCase(.uppercase)
            .tracking(2.5)
            .foregroundColor(.black) // ✅ Default text color remains black
            .background(
                configuration.isPressed
                ? LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.white]),
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                : LinearGradient(
                    gradient: Gradient(colors: [Color.white, Color.white]), // Keeps default background white
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            )
            .cornerRadius(45)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.3), value: configuration.isPressed)
    }
}

// ✅ UNIVERSAL TOGGLE STYLE (Custom Switch)
struct UiverseToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            Text(configuration.isOn ? "🌚" : "🌞") // Sun/Moon Emoji
                .font(.system(size: 14))
                .frame(width: 24)

            RoundedRectangle(cornerRadius: 25)
                .fill(configuration.isOn ? Color.green.opacity(0.8) : Color.gray.opacity(0.5))
                .frame(width: 50, height: 25)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .offset(x: configuration.isOn ? 12 : -12)
                        .animation(.easeInOut(duration: 0.3), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

// ✅ UNIVERSAL TEXTFIELD STYLE (For Profile Input Fields)
struct UiverseTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white))
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            .font(.system(size: 14))
    }
}

// ✅ EXTENSION FOR EASY USAGE
extension View {
    func uiverseTextFieldStyle() -> some View {
        self.modifier(UiverseTextFieldStyle())
    }
}

// ✅ CUSTOM TOGGLE COMPONENT
struct CustomToggle: View {
    @Binding var isOn: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30)
                .fill(isOn ? Color.green : Color.gray.opacity(0.4))
                .frame(width: 50, height: 25)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .offset(x: isOn ? 12 : -12)
                        .shadow(radius: 2)
                )
                .animation(.spring(), value: isOn)
        }
        .onTapGesture {
            isOn.toggle()
        }
    }
}

// ✅ CUSTOM BUTTON COMPONENT (Alternative to ButtonStyle)
struct CustomButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .textCase(.uppercase)
                .tracking(2)
                .foregroundColor(.black)
                .padding(.vertical, 14)
                .padding(.horizontal, 36)
                .background(Color.white)
                .cornerRadius(45)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 8)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 45)
                .stroke(Color.black.opacity(0.2), lineWidth: 1)
        )
        .padding(.top, 20)
        .onHover { isHovered in
            if isHovered {
                withAnimation {
                    transformHoverEffect(true)
                }
            } else {
                withAnimation {
                    transformHoverEffect(false)
                }
            }
        }
    }

    private func transformHoverEffect(_ isHovered: Bool) {
        withAnimation(.easeOut(duration: 0.3)) {
            if isHovered {
                // Raised effect
                DispatchQueue.main.async {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
        }
    }
}
