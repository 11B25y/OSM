import SwiftUI

struct SideMenuView: View {
    @Binding var isMenuOpen: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button(action: {
                print("Navigate to Home")
            }) {
                Text("Home")
                    .font(.title2)
            }

            Button(action: {
                print("Navigate to Profile")
            }) {
                Text("Profile")
                    .font(.title2)
            }

            Button(action: {
                print("Navigate to Settings")
            }) {
                Text("Settings")
                    .font(.title2)
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .frame(width: 250)
        .offset(x: isMenuOpen ? 0 : -300) // Slide effect for the menu
        .animation(.easeInOut(duration: 0.3), value: isMenuOpen)
    }
}
