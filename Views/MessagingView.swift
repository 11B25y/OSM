import SwiftUI
import MultipeerConnectivity
import Combine

struct MessagingView: View {
    @EnvironmentObject private var proximityManager: ProximityManager
    @State private var message: String = "" // User's message input
    @State private var messages: [String] = [] // Sent/received messages list
    @State private var isTyping = false
    @State private var cancellables = Set<AnyCancellable>()
    
    var peer: SelectedPeer // Passed from ProximityView or selected peer from the invitation
    var selectedUser: UserProfile?

    var body: some View {
        VStack {
            // ✅ Display peer's avatar and name
            if let avatarURL = peer.profile?.wrappedAvatarURL {
                AsyncImage(url: avatarURL) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 4))
                .shadow(radius: 5)
            }

            Text(peer.profile?.wrappedUsername ?? "Unknown User")
                .font(.headline)

            // ✅ Message List
            MessageListView(messages: messages)

            // ✅ Message Input
            HStack {
                TextField("Enter message", text: $message)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: message) { isTyping = !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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

    /// ✅ Send Message
    private func sendMessage() {
        let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }

        withAnimation {
            messages.append("Me: \(trimmedMessage)")
        }

        if let data = trimmedMessage.data(using: .utf8),
           let peerToSend = selectedUser ?? peer.profile,
           let peerID = peerToSend.peerIDObject {
            
            proximityManager.send(data: data, to: [peerID])
            print("📤 Sent message: \(trimmedMessage) to \(peerID.displayName)")
        }

        message = "" // Clear message input
        isTyping = false
    }

    /// ✅ Setup Incoming Messages
    private func setupMessageReceiving() {
        proximityManager.$receivedMessages
            .dropFirst() // Ignore initial empty state
            .sink { newMessages in
                DispatchQueue.main.async {
                    self.messages.append(contentsOf: newMessages)
                    print("📩 Received messages: \(newMessages)")
                }
            }
            .store(in: &cancellables)
    }
}

// ✅ MessageListView - Displays Messages
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
                                    .background(Color.gray.opacity(0.2))
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
