import SwiftUI
import MultipeerConnectivity
import Combine

struct MessagingView: View {
    @EnvironmentObject private var proximityManager: ProximityManager
    let peer: SelectedPeer

    @State private var draftMessage: String = ""
    @State private var messages: [String] = []
    @State private var isTyping = false
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        VStack(spacing: 16) {
            // Peer avatar & name
            if let url = peer.profile?.wrappedAvatarURL {
                AsyncImage(url: url) { image in
                    image.resizable()
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .shadow(radius: 4)
            }
            Text(peer.profile?.wrappedUsername ?? "Unknown")
                .font(.headline)

            Divider()

            // Message history
            MessageListView(messages: messages)

            Divider()

            // Typing indicator (optional)
            if isTyping {
                Text("\(peer.profile?.wrappedUsername ?? "User") is typing...")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // Input field + send button
            HStack {
                TextField("Message…", text: $draftMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: draftMessage) { text in
                        isTyping = !text.trimmingCharacters(in: .whitespaces).isEmpty
                    }

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .padding(8)
                        .background(draftMessage.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(draftMessage.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .navigationTitle(peer.profile?.wrappedUsername ?? "Chat")
        .onAppear(perform: setupSubscriptions)
    }

    private func sendMessage() {
        let text = draftMessage.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, let peerID = peer.profile?.peerIDObject else { return }

        // Append to local UI
        messages.append("Me: \(text)")
        proximityManager.sendMessage(text)

        draftMessage = ""
        isTyping = false
    }

    private func setupSubscriptions() {
        proximityManager.$receivedMessages
            .sink { all in
                let prefix = "\(peer.peerID.displayName):"
                let newMsgs = all.filter { $0.hasPrefix(prefix) }
                DispatchQueue.main.async {
                    for msg in newMsgs {
                        if !messages.contains(msg) {
                            messages.append(msg)
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
}

struct MessageListView: View {
    var messages: [String]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(messages.indices, id: \.self) { i in
                        let msg = messages[i]
                        HStack {
                            if msg.hasPrefix("Me:") {
                                Spacer()
                                Text(msg)
                                    .padding(8)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            } else {
                                Text(msg)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                Spacer()
                            }
                        }
                        .id(i)
                    }
                }
                .padding(.horizontal)
            }
            .onChange(of: messages.count) { _ in
                proxy.scrollTo(messages.count - 1, anchor: .bottom)
            }
        }
    }
}
