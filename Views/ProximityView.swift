import SwiftUI
import MultipeerConnectivity

struct ProximityView: View {
    @EnvironmentObject private var proximityManager: ProximityManager
    @EnvironmentObject var locationManager: LocationManager
    @State private var message: String = ""
    @State private var messages: [String] = []
    @State private var animateStatusChange = false
    @State private var nearbyUsers: [UserProfile] = []
    @State private var selectedUser: UserProfile? = nil
    @State private var showMessageView = false
    @State private var currentUserProfile: UserProfile?
    @State private var hasProfile = false
    @State private var navigateToMapView = false
    @State private var showUpgradeAlert = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 20) {
                if proximityManager.reconnecting {
                    VStack {
                        ReconnectingView()
                        Text("Reconnecting...")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                } else {
                    Text("No action needed")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                
                VStack {
                    if proximityManager.isBrowsing {
                        Text("Scanning for peers...")
                            .font(.headline)
                            .foregroundColor(.gray)
                    } else {
                        Text("No connected peers found")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                
                if proximityManager.isBrowsing && !nearbyUsers.isEmpty {
                    NearbyUsersView(nearbyUsers: nearbyUsers, selectedUser: $selectedUser)
                        .padding()
                }
                
                if !proximityManager.connectedPeers.isEmpty {
                    List(proximityManager.connectedPeers, id: \.peerID) { peerEntry in
                        HStack {
                            if let avatarURL = peerEntry.profile?.avatarURL, let url = URL(string: avatarURL) {
                                Image(uiImage: UIImage(contentsOfFile: url.path) ?? UIImage())
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .shadow(radius: 5)
                            } else {
                                // Removed the default profile icon
                            }
                            
                            VStack(alignment: .leading) {
                                Text(peerEntry.displayName)
                                    .font(.headline)
                                if let status = peerEntry.profile?.status {
                                    Text(status)
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                        .onTapGesture {
                            self.selectedUser = peerEntry.profile
                            showMessageView = true
                        }
                    }
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(10)
                }
                
                VStack(spacing: 10) {
                    TextField("Enter your message...", text: $message)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    
                    Button(action: sendMessage) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("Send Message")
                        }
                        .font(.headline)
                        .padding()
                        .foregroundColor(.white)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .scaleEffect(animateStatusChange ? 1.1 : 1)
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(messages, id: \.self) { msg in
                            HStack {
                                if msg.hasPrefix("Me:") {
                                    Spacer()
                                    Text(msg)
                                        .padding()
                                        .background(Color.blue.opacity(0.7))
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                        .transition(.slide)
                                        .animation(.spring(), value: messages)
                                } else {
                                    Text(msg)
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(10)
                                        .transition(.slide)
                                        .animation(.spring(), value: messages)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .shadow(radius: 5)
                
                Spacer()
                
                VStack(spacing: 10) {
                    Button(action: {
                        withAnimation(.spring()) {
                            proximityManager.startDiscovery()
                            animateStatusChange = true
                        }
                    }) {
                        Text("Start Exploring")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .scaleEffect(animateStatusChange ? 1.05 : 1)
                    
                    Button(action: {
                        withAnimation(.spring()) {
                            proximityManager.stopDiscovery()
                            animateStatusChange = true
                        }
                    }) {
                        Text("Stop Exploring")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .scaleEffect(animateStatusChange ? 1.05 : 1)
                }
                .padding()
            }
            
            // ✅ FLOATING MAP BUTTON (Bottom Right)
            Button(action: {
                if let currentUser = currentUserProfile, currentUser.isPremiumUser {
                    navigateToMapView = true
                } else {
                    showUpgradeAlert = true
                }
            }) {
                Image(systemName: "map.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.white, Color.purple]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                            .shadow(radius: 5)
                    )
            }
            .padding(.trailing, 20)
            .padding(.bottom, 30)
            
            .navigationDestination(isPresented: $navigateToMapView) {
                UserMapView(users: locationManager.nearbyUsers)
            }
            .alert("Premium Feature", isPresented: $showUpgradeAlert) {
                Button("OK", role: .cancel) {}
                Button("Upgrade Now") {
                    // Redirect to subscription page (if implemented)
                }
            } message: {
                Text("This feature is only available for premium users. Upgrade to access!")
            }
            
            .alert(item: $proximityManager.receivedInvitationFromPeer) { peer in
                Alert(
                    title: Text("Invitation from \(peer.displayName)"),
                    message: Text("Do you want to accept the invitation?"),
                    primaryButton: .default(Text("Accept")) {
                        proximityManager.respondToInvitation(accepted: true)
                    },
                    secondaryButton: .cancel(Text("Decline")) {
                        proximityManager.respondToInvitation(accepted: false)
                    }
                )
            }
        }
    }
    
    func sendMessage() {
        guard !message.isEmpty else { return }
        
        withAnimation {
            messages.append("Me: \(message)")
        }
        
        if let data = message.data(using: .utf8), let peer = selectedUser, let peerID = peer.peerIDObject {
            proximityManager.send(data: data, to: [peerID])
        }
        
        message = ""
    }
}
