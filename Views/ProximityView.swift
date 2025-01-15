import SwiftUI
import MultipeerConnectivity

struct ProximityView: View {
    @EnvironmentObject private var proximityManager: ProximityManager
    @State private var message: String = "" // User's message input
    @State private var messages: [String] = [] // Sent/received messages list
    @State private var animateStatusChange = false // Animation trigger
    @State private var nearbyUsers: [UserProfile] = [] // Store nearby users
    @State private var selectedUser: UserProfile? = nil // Selected user for interaction
    @State private var showMessageView = false // Flag to control showing the message view
    @State private var currentUserProfile: UserProfile?
    @State private var hasProfile = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Check if we are reconnecting
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
                // Ensure something is always rendered even if reconnecting is false
                Text("No action needed")
                    .font(.headline)
                    .foregroundColor(.gray)
            }

            // Display whether scanning for peers or not
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

            // Display nearby users when browsing
            if proximityManager.isBrowsing && !nearbyUsers.isEmpty {
                NearbyUsersView(nearbyUsers: nearbyUsers, selectedUser: $selectedUser)
                    .padding()
            }

            // Display connected peers with profile and avatar info
            if !proximityManager.connectedPeers.isEmpty {
                List(proximityManager.connectedPeers, id: \.peerID) { peerEntry in
                    HStack {
                        // Display the avatar if available
                        if let avatarURL = peerEntry.profile?.avatarURL, let url = URL(string: avatarURL) {
                            Image(uiImage: UIImage(contentsOfFile: url.path) ?? UIImage())
                                .resizable()
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(radius: 5)
                        } else {
                            // Default image if avatar URL is not available
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.gray)
                                .background(Circle().fill(Color.gray.opacity(0.3))) // Circle background for the icon
                        }

                        // Display the peer's name and status
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
                        // Set selected peer on tap
                        self.selectedUser = peerEntry.profile
                        showMessageView = true // Show the message view when a user is selected
                    }
                }
                .padding()
                .background(Color(.systemGray5))
                .cornerRadius(10)
            
                    
                    // Message input and send button with animations
                    VStack(spacing: 10) {
                        TextField("Enter your message...", text: $message)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)
                        
                        Button(action: {
                            sendMessage() // Call sendMessage when the button is pressed
                        }) {
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
                            .scaleEffect(animateStatusChange ? 1.1 : 1) // Animation based on the state
                        }
                    }
                    .padding()
                    
                    // Sent/received messages display with animation
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
                    
                    // Buttons for starting/stopping exploring with bounce animations
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
                    
                    // The alert modifier should be placed directly on the view
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
        }
        
        // Move the sendMessage function here
        func sendMessage() {
            guard !message.isEmpty else { return }
            
            withAnimation {
                messages.append("Me: \(message)")
            }
            
            if let data = message.data(using: .utf8) {
                // Ensure that the selectedUser is of type UserProfile and extract peerID from it
                if let peer = selectedUser, let peerID = peer.peerIDObject {
                    proximityManager.send(data: data, to: [peerID])
                }
            }
            
            message = "" // Clear the message field after sending
        }
    }

