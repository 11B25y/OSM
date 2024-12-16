import SwiftUI
struct SettingsView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false

    var body: some View {
        VStack {
            // Other settings options here
            Spacer()
            
            // Log Out Button
            Button(action: {
                isLoggedIn = false // Log the user out
            }) {
                Text("Log Out")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .navigationTitle("Settings")
    }
}
