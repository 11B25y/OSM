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
        self.currentUserProfile = UserProfile.fetchLoggedInUser(context: context)
        setupPeerID()
        
        loadLoggedInProfile()
        
        // Initialize session and other components
        self.session = MCSession(peer: self.peerID, securityIdentity: nil, encryptionPreference: .required)
        self.advertiser = MCNearbyServiceAdvertiser(peer: self.peerID, discoveryInfo: nil, serviceType: serviceType)
        self.browser = MCNearbyServiceBrowser(peer: self.peerID, serviceType: serviceType)
        self.session.delegate = self
        self.advertiser.delegate = self
        self.browser.delegate = self
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        checkBluetoothStatus()
    }
    // MARK: - PeerID Setup
    private func setupPeerID() {
        // Use profile's username if available, otherwise fallback to device name
        if let username = currentUserProfile?.wrappedUsername, !username.isEmpty {
            self.peerID = MCPeerID(displayName: username)
        } else {
            self.peerID = MCPeerID(displayName: UIDevice.current.name)
        }
        
        // Debugging log
        print("PeerID set to: \(peerID.displayName)")
    }
    // MARK: - Method to Get PeerID
    func getPeerID() -> MCPeerID {
        return self.peerID
    }
    
    func populateProfileIfNeeded() {
        if currentUserProfile == nil {
            currentUserProfile = fetchUserProfile(for: peerID)
            if currentUserProfile == nil {
                print("No user profile found; populate as needed.")
            }
        }
        
        // Print the current profile after populating
        print("ProximityManager Profile: \(currentUserProfile?.wrappedUsername ?? "None")")
    }
    
    // MARK: - Method to Update Discovery Distance
    func updateDiscoveryDistance(_ distance: Double) {
        print("Updated discovery distance to: \(distance)")
    }
    
    func updateSubscriptionFilter(_ isSubscribed: Bool) {
        print("Subscription filter updated to show only subscribed users: \(isSubscribed)")
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
            print("Error sending data: \(error.localizedDescription)")
        }
    }
    func sendMessage(_ message: String) {
        guard !message.isEmpty, let messageData = message.data(using: .utf8) else { return }
        send(data: messageData, to: connectedPeers.map { $0.peerID })
    }
    
    // MARK: - Profile Handling
    func createProfile(username: String, email: String, avatarURL: String, bio: String) {
        if let existingProfile = fetchUserProfile(for: peerID) {
            // Update the existing profile
            existingProfile.username = username
            existingProfile.email = email
            existingProfile.avatarURL = avatarURL
            existingProfile.bio = bio
            existingProfile.isLoggedIn = true // Ensure this is set
            existingProfile.peerIDObject = peerID // Use the computed property
            print("Updated existing profile: \(existingProfile.username ?? "Unknown")")
        } else {
            // Create a new profile
            let profile = UserProfile(context: managedObjectContext)
            profile.username = username
            profile.email = email
            profile.avatarURL = avatarURL
            profile.bio = bio
            profile.isLoggedIn = true // Ensure this is set
            profile.peerIDObject = peerID // Use the computed property
            print("Created new profile: \(username)")
        }

        // Save the context
        saveContext()
        print("ProximityManager Profile: \(currentUserProfile?.wrappedUsername ?? "None")")
    }

    /// Fetches an existing profile for a peer or creates a placeholder profile if none exists.
    func fetchOrCreateProfile(for peerID: MCPeerID) -> UserProfile {
        if let existingProfile = fetchUserProfile(for: peerID) {
            return existingProfile
        } else {
            let profile = UserProfile(context: managedObjectContext)
            profile.peerIDObject = peerID
            profile.username = "Unknown User" // Placeholder until updated
            saveProfileChanges(profile)
            print("Created placeholder profile for peer: \(peerID.displayName)")
            return profile
        }
    }

/// fetch user data from core data
    func fetchUserProfile(for peerID: MCPeerID) -> UserProfile? {
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "peerID == %@", peerID.displayName)
        do {
            return try managedObjectContext.fetch(request).first
        } catch {
            print("Error fetching profile for peer \(peerID.displayName): \(error.localizedDescription)")
            return nil
        }
    }

    /// Saves changes to the given profile in Core Data.
    func saveProfileChanges(_ profile: UserProfile) {
        do {
            try managedObjectContext.save()
            print("Profile saved successfully.")
        } catch let error as NSError {
            print("Failed to save profile: \(error), \(error.userInfo)")
        }
    }

    /// Saves the current Core Data context.
    func saveContext() {
        do {
            try managedObjectContext.save()
            print("Context saved successfully.")
        } catch let error as NSError {
            print("Failed to save context: \(error.localizedDescription)")
            self.error = error
        }
    }
    // MARK: - Load Logged-In Profile
    func loadLoggedInProfile() {
        print("Loading logged-in user profile...")
        if let loggedInProfile = UserProfile.fetchLoggedInUser(context: managedObjectContext) {
            self.currentUserProfile = loggedInProfile
            setupPeerID()
            print("Loaded profile: \(loggedInProfile.wrappedUsername)")
        } else {
            print("No logged-in profile found.")
            self.currentUserProfile = nil
        }
    }
    // MARK: - MCSessionDelegate
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("Peer connected: \(peerID.displayName)")
                if !self.connectedPeers.contains(where: { $0.peerID == peerID }) {
                    let profile = self.fetchOrCreateProfile(for: peerID)
                    self.connectedPeers.append(SelectedPeer(id: UUID(), peerID: peerID, profile: profile))
                    print("Connected peer profile: \(profile.wrappedUsername)")
                }
                self.reconnecting = false

            case .notConnected:
                print("Peer disconnected: \(peerID.displayName)")
                self.connectedPeers.removeAll { $0.peerID == peerID }
                if self.connectedPeers.isEmpty {
                    self.restartSession()
                }

            case .connecting:
                print("Peer connecting: \(peerID.displayName)")

            @unknown default:
                print("Unknown state for peer: \(peerID.displayName)")
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let message = String(data: data, encoding: .utf8) {
            DispatchQueue.main.async {
                self.receivedMessages.append("\(peerID.displayName): \(message)")
                print("Message received from \(peerID.displayName): \(message)")
            }
        } else {
            print("Failed to decode received data from \(peerID.displayName)")
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Received stream \(streamName) from peer: \(peerID.displayName)")
        // You can implement stream handling here if required.
    }

    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("Started receiving resource \(resourceName) from peer: \(peerID.displayName)")
        // Handle resource receiving progress here if necessary.
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at url: URL?, withError error: Error?) {
        if let error = error {
            print("Failed to receive resource \(resourceName) from peer \(peerID.displayName): \(error.localizedDescription)")
        } else if let url = url {
            print("Successfully received resource \(resourceName) from peer \(peerID.displayName) at URL: \(url)")
        }
    }
    // MARK: - MCNearbyServiceAdvertiserDelegate
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        DispatchQueue.main.async {
            self.receivedInvitationFromPeer = IdentifiablePeer(peerID: peerID)
            self.currentInvitationHandler = invitationHandler
            print("Received invitation from peer: \(peerID.displayName)")
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async {
            self.error = error
            print("Failed to start advertising: \(error.localizedDescription)")
        }
    }
    
    // MARK: - MCNearbyServiceBrowserDelegate
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async {
            if !self.connectedPeers.contains(where: { $0.peerID == peerID }) {
                // Use fetchOrCreateProfile to ensure a profile is available
                let profile = self.fetchOrCreateProfile(for: peerID)
                self.connectedPeers.append(SelectedPeer(id: UUID(), peerID: peerID, profile: profile))
                print("Found peer with profile: \(profile.wrappedUsername)")
            } else {
                print("Peer already connected: \(peerID.displayName)")
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            // Remove the lost peer from the connectedPeers array
            self.connectedPeers.removeAll { $0.peerID == peerID }
            print("Lost peer: \(peerID.displayName)")
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async {
            // Handle the error if browsing failed to start
            self.error = error
            print("Error starting browsing for peers: \(error.localizedDescription)")
        }
    }
}
