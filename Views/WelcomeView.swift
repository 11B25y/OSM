import SwiftUI
struct WelcomeView: View {
    @Binding var showWelcomeScreen: Bool
    var body: some View {
        VStack {
            Text("Welcome to OSM")
                .font(.largeTitle)
                .padding()

            Text("Connect with nearby devices effortlessly.")
                .font(.subheadline)
                .padding()

            // "Get Started" button that navigates to the main view directly
            Button(action: {
                showWelcomeScreen = false // Hides the WelcomeView and shows the main content
            }) {
                Text("Get Started")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .padding()
        }
    }
}
