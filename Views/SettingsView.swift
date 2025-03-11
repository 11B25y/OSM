import SwiftUI

struct SettingsView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @Binding var currentUserProfile: UserProfile?
    @ObservedObject var proximityManager: ProximityManager
    @State private var showSubscriptionOptions = false
    @State private var filterDistance: Double = 100
    @State private var showOnlySubscribed = false

    var body: some View {
        List {
            // Account Section
            Section(header: Text("Account")) {
                if let profile = currentUserProfile {
                    HStack {
                        Text("Signed in as")
                        Text(profile.username ?? "Unknown User")
                            .bold()
                    }
                }
            }

            // Subscription Section
            Section(header: Text("Subscription")) {
                Button(action: {
                    showSubscriptionOptions = true
                }) {
                    HStack {
                        Text("Manage Subscription")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                }
            }

            // Peer Filters Section
            Section(header: Text("Peer Filters")) {
                VStack(alignment: .leading) {
                    Text("Discovery Distance: \(Int(filterDistance))m")
                    Slider(value: $filterDistance, in: 10...1000) { changed in
                        if !changed {
                            proximityManager.updateDiscoveryDistance(filterDistance)
                        }
                    }
                }

                Toggle("Show Only Subscribed Users", isOn: $showOnlySubscribed)
                    .onChange(of: showOnlySubscribed) { newValue in
                        proximityManager.updateSubscriptionFilter(newValue)
                    }
            }

            // App Settings Section
            Section(header: Text("App Settings")) {
                NavigationLink(destination: Text("Notifications")) {
                    Text("Notification Settings")
                }

                NavigationLink(destination: Text("Privacy")) {
                    Text("Privacy Settings")
                }
            }

            // Log Out Button
            Section {
                Button(action: {
                    isLoggedIn = false // Log the user out
                }) {
                    HStack {
                        Spacer()
                        Text("Log Out")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showSubscriptionOptions) {
            // Subscription options view
            Text("Subscription Options")
                .presentationDetents([.medium])
        }
    }
}

