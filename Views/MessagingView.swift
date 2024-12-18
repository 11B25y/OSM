import SwiftUI
import MultipeerConnectivity
import Combine

struct MessagingView: View {
    @EnvironmentObject private var proximityManager: ProximityManager
    @State private var message: String = "" // User's message input
    @State private var messages: [String] = [] // Sent/received messages list
    @State private var isTyping = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var animateStatusChange = false
    
    var peer: SelectedPeer // Passed from ProximityView or selected peer from the invitation

    var body: some View {
        VStack {
            // Display peer's avatar and name
            if let avatarURL = peer.profile?.wrappedAvatarURL {
                AsyncImage(url: avatarURL) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                .shadow(radius: 5)
            }

            Text(peer.profile?.wrappedUsername ?? "Unknown User")
                .font(.headline)

            // Message List - using MessageListView
            MessageListView(messages: messages)

            // Message Input
            HStack {
                TextField("Enter message", text: $message)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: message) {
                        isTyping = !message.isEmpty
                    }
                
                Button("Send") {
                    sendMessage()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()

            if isTyping {
                Text("\(peer.profile?.wrappedUsername ?? "Unknown User") is typing...")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .onAppear {
            setupMessageReceiving()
        }
    }

    // Function to send message
    private func sendMessage() {
        guard !message.isEmpty else { return }
        let formattedMessage = "Me: \(message)"
        messages.append(formattedMessage)
        
        if let data = message.data(using: .utf8) {
            // Send message to the peer using peer.peerID
            proximityManager.send(data: data, to: [peer.peerID])
        }
        
        message = "" // Clear the message input after sending
    }

    // Function to setup message receiving
    private func setupMessageReceiving() {
        proximityManager.$receivedMessages
            .dropFirst() // Ignore initial values
            .sink { newMessages in
                // Append any new messages from peers into the local messages list
                messages.append(contentsOf: newMessages)
            }
            .store(in: &cancellables)
    }
}

// MessageListView - displays the list of messages
struct MessageListView: View {
    var messages: [String]
    
    var body: some View {
        ScrollViewReader { scrollViewProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(messages.indices, id: \.self) { index in
                        let message = messages[index]
                        HStack {
                            if message.hasPrefix("Me:") {
                                Spacer()
                                Text(message)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            } else {
                                Text(message)
                                    .padding()
                                    .background(Color.gray)
                                    .cornerRadius(10)
                                Spacer()
                            }
                        }
                        .id(index)
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) { _, _ in
                scrollViewProxy.scrollTo(messages.count - 1)
            }
        }
    }
}
