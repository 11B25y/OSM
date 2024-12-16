import Foundation
import MultipeerConnectivity
import CoreBluetooth
import CoreData
import Combine

class ProximityManager: NSObject, ObservableObject, CBCentralManagerDelegate, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    // MARK: - Properties
    private let serviceType = "proximity1"

    var peerID: MCPeerID!
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!
    private var centralManager: CBCentralManager!

    @Published var isAdvertising: Bool = false
    @Published var isBrowsing: Bool = false
    @Published var bluetoothEnabled: Bool = false
    @Published var receivedMessages: [String] = []
    @Published var connectedPeers: [SelectedPeer] = [] // Updated to use SelectedPeer
    @Published var reconnecting: Bool = false
    @Published var isScanning: Bool = false
    @Published var currentUserProfile: UserProfile?
    @Published var receivedInvitationFromPeer: IdentifiablePeer?
    @Published var error: Error?
    @Published var useMockProfiles: Bool = false // Flag for using mock profiles (currently unused)

    private var currentInvitationHandler: ((Bool, MCSession?) -> Void)?
    // MARK: - Core Data
    var managedObjectContext: NSManagedObjectContext

    // MARK: - Initializer
    init(context: NSManagedObjectContext) {
        self.managedObjectContext = context
        super.init()
        
        // Fetch the logged-in user profile
        self.currentUserProfile = UserProfile.fetchLoggedInUser(context: context)
        setupPeerID()
        
        // Initialize session, advertiser, and browser
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        self.advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        
        // Set delegates
        self.session.delegate = self
        self.advertiser.delegate = self
        self.browser.delegate = self
        
        // Initialize Bluetooth central manager
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // Check Bluetooth status after initialization
        checkBluetoothStatus()
    }

    // MARK: - PeerID Setup
    private func setupPeerID() {
        // Use profile's username if available, otherwise use the device name as a fallback
        if let username = currentUserProfile?.wrappedUsername, !username.isEmpty {
            self.peerID = MCPeerID(displayName: username)
        } else {
            self.peerID = MCPeerID(displayName: UIDevice.current.name)
        }

        // Print the profile username after setup
        print("ProximityManager Profile: \(currentUserProfile?.wrappedUsername ?? "None")")
    }

    // MARK: - Method to Get PeerID
    func getPeerID() -> MCPeerID {
        return self.peerID
    }

    func populateProfileIfNeeded() {
        if currentUserProfile == nil {
            currentUserProfile = fetchUserProfile()
            if currentUserProfile == nil {
                // Optionally create a new profile or handle the case
                print("No user profile found; populate as needed.")
            }
        }
        
        // Print the current profile after populating
        print("ProximityManager Profile: \(currentUserProfile?.wrappedUsername ?? "None")")
    }
    
    // MARK: - Start and Stop Exploring
    func startDiscovery() {
        print("Starting discovery process...")
        
        if !useMockProfiles {
            if !isAdvertising {
                advertiser.startAdvertisingPeer()
                isAdvertising = true
                print("Started advertising peer on \(peerID.displayName)")
            }
            if !isBrowsing {
                browser.startBrowsingForPeers()
                isBrowsing = true
                print("Started browsing for peers on \(peerID.displayName)")
            }
        }

        isScanning = true
    }

    func stopDiscovery() {
        print("Stopping discovery process...")
        if isAdvertising {
            advertiser.stopAdvertisingPeer()
            isAdvertising = false
        }
        if isBrowsing {
            browser.stopBrowsingForPeers()
            isBrowsing = false
        }
        isScanning = false
    }
    
    // MARK: - Restart Session
    func restartSession() {
        if connectedPeers.isEmpty {
            print("No connected peers to restart the session.")
            return
        }

        reconnecting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.session.disconnect()
            self.session = MCSession(peer: self.peerID, securityIdentity: nil, encryptionPreference: .required)
            self.session.delegate = self
            self.stopDiscovery()
            self.startDiscovery()
            self.reconnecting = false
            print("Session restarted.")
        }
    }

    // MARK: - Bluetooth State Management
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        DispatchQueue.main.async {
            self.bluetoothEnabled = central.state == .poweredOn
            if self.bluetoothEnabled {
                self.startDiscovery()
            } else {
                self.stopDiscovery()
            }
        }
    }
    
    func checkBluetoothStatus() {
        if let central = centralManager {
            centralManagerDidUpdateState(central)
        }
    }
    
    deinit {
        session.disconnect()
        stopDiscovery()
    }

    // MARK: - Invitation Handling
    func respondToInvitation(accepted: Bool) {
        currentInvitationHandler?(accepted, accepted ? session : nil)
        cleanUpAfterInvitation()
    }

    private func cleanUpAfterInvitation() {
        receivedInvitationFromPeer = nil
        currentInvitationHandler = nil
    }

    // MARK: - Sending Data
    func send(data: Data, to peers: [MCPeerID]) {
        guard !peers.isEmpty else { return }
        
        do {
            try session.send(data, toPeers: peers, with: .reliable)
        } catch {
            self.error = error
        }
    }

    func sendMessage(_ message: String) {
        guard !message.isEmpty, let messageData = message.data(using: .utf8) else { return }
        send(data: messageData, to: connectedPeers.map { $0.peerID })  // Corrected: use peerID
    }

    // MARK: - Profile Handling
    func createProfile(username: String, email: String, avatarURL: String, bio: String) {
        if let existingProfile = fetchUserProfile() {
            existingProfile.username = username
            existingProfile.email = email
            existingProfile.avatarURL = avatarURL
            existingProfile.bio = bio
            existingProfile.isLoggedIn = true
        } else {
            let profile = UserProfile(context: managedObjectContext)
            profile.username = username
            profile.email = email
            profile.avatarURL = avatarURL
            profile.bio = bio
            profile.isLoggedIn = true
        }

        // Save the context and print the profile username after creation
        saveContext()

        // Log the profile creation
        print("ProximityManager Profile: \(currentUserProfile?.wrappedUsername ?? "None")")
    }

    func fetchUserProfile() -> UserProfile? {
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        do {
            return try managedObjectContext.fetch(request).first
        } catch {
            return nil
        }
    }

    func saveContext() {
        do {
            try managedObjectContext.save()
        } catch {
            self.error = error
        }
    }

    func saveProfileChanges(_ profile: UserProfile) {
        // Core Data save logic
        do {
            try managedObjectContext.save()  // Save the profile
            print("Profile saved successfully.")
        } catch {
            print("Failed to save profile: \(error.localizedDescription)")
        }
    }

    // MARK: - MCSessionDelegate
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                // If the peer isn't already in the list, add it to connectedPeers
                if !self.connectedPeers.contains(where: { $0.peerID == peerID }) {
                    self.connectedPeers.append(SelectedPeer(id: UUID(), peerID: peerID, profile: nil)) // Store peer info
                }
                self.reconnecting = false
            case .connecting:
                break
            case .notConnected:
                // Remove peer from connectedPeers when disconnected
                self.connectedPeers.removeAll { $0.peerID == peerID }
                
                // Restart session if no peers are connected
                if self.connectedPeers.isEmpty {
                    self.restartSession()
                }
            @unknown default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let message = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.receivedMessages.append("\(peerID.displayName): \(message)") // Append the message to the received messages list
            }
        }
    }

    func fetchUserProfile(for peerID: MCPeerID) -> UserProfile? {
        // Implement your logic here to fetch a profile based on the peerID
        // This can be an API call, or fetching from a local store based on peerID.
        // For now, returning nil as a placeholder.
        return nil
    }

    func session(_: MCSession, didReceive stream: InputStream, withName: String, fromPeer: MCPeerID) {}
    func session(_: MCSession, didStartReceivingResourceWithName: String, fromPeer: MCPeerID, with: Progress) {}
    func session(_: MCSession, didFinishReceivingResourceWithName: String, fromPeer: MCPeerID, at: URL?, withError: Error?) {}

    // MARK: - MCNearbyServiceAdvertiserDelegate
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        DispatchQueue.main.async {
            self.receivedInvitationFromPeer = IdentifiablePeer(peerID: peerID)
            self.currentInvitationHandler = invitationHandler
        }
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async {
            self.error = error
        }
    }
    
    // MARK: - MCNearbyServiceBrowserDelegate
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        // Here, we create a SelectedPeer with peerID and profile if necessary
        if !self.connectedPeers.contains(where: { $0.peerID == peerID }) {
            self.connectedPeers.append(SelectedPeer(id: UUID(), peerID: peerID, profile: nil))
        }
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 60)
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        self.connectedPeers.removeAll { $0.peerID == peerID }
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        self.error = error
    }
}
