import Foundation
import MultipeerConnectivity
import CoreBluetooth
import CoreData
import Combine
import CoreLocation

class ProximityManager: NSObject, ObservableObject, CBCentralManagerDelegate, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {
    
    // MARK: - Properties
    private let serviceType = "proximity1"
    private let storedPeersKey = "storedConnectedPeers"
    
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
        
        // Load the current user's profile
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
        
        // Initialize Bluetooth Central Manager
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        checkBluetoothStatus()
        
        // Load and attempt to reconnect to previously saved peers
        loadAndReconnectPeers()
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
        guard !connectedPeers.isEmpty else {
            print("No connected peers to restart the session.")
            return
        }
        
        reconnecting = true
        print("Restarting session...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Attempt to reconnect with known peers before resetting session
            self.reconnectToKnownPeers()
        }
    }
    
    // MARK: - Attempt to Reconnect to Known Peers Before Resetting Session
    private func reconnectToKnownPeers() {
        print("Attempting to reconnect to known peers...")
        
        for peer in connectedPeers {
            if session.connectedPeers.contains(peer.peerID) {
                print("Peer already connected: \(peer.peerID.displayName)")
            } else {
                print("Reconnecting to peer: \(peer.peerID.displayName)")
                browser.invitePeer(peer.peerID, to: session, withContext: nil, timeout: 10)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            // If still no connections, restart session fully
            if self.session.connectedPeers.isEmpty {
                self.fullSessionReset()
            } else {
                print("Reconnection successful.")
            }
        }
    }
    
    // Save connected peers before app exits
    func saveConnectedPeers() {
        let peerNames = connectedPeers.map { $0.peerID.displayName }
        UserDefaults.standard.set(peerNames, forKey: storedPeersKey)
        print("Saved known peers: \(peerNames)")
    }

    // Load previously connected peers and attempt reconnection
    func loadAndReconnectPeers() {
        guard let storedPeerNames = UserDefaults.standard.array(forKey: storedPeersKey) as? [String] else { return }
        print("Loading known peers: \(storedPeerNames)")
        
        for peerName in storedPeerNames {
            let peerID = MCPeerID(displayName: peerName)
            reconnectToPeer(peerID)
        }
    }

    // Attempt to reconnect to a specific peer
    func reconnectToPeer(_ peerID: MCPeerID) {
        print("Attempting to reconnect to \(peerID.displayName)...")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    // MARK: - Full Session Reset (If Reconnection Fails)
    private func fullSessionReset() {
        print("Reconnection failed. Resetting session...")
        
        self.session.disconnect()
        self.session = MCSession(peer: self.peerID, securityIdentity: nil, encryptionPreference: .required)
        self.session.delegate = self
        self.stopDiscovery()
        self.startDiscovery()
        
        reconnecting = false
        print("Session fully restarted.")
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
            existingProfile.username = username
            existingProfile.email = email
            existingProfile.avatarURL = avatarURL
            existingProfile.bio = bio
            existingProfile.isLoggedIn = true
            existingProfile.peerIDObject = peerID
            print("Updated existing profile: \(existingProfile.username ?? "Unknown")")
        } else {
            let profile = UserProfile(context: managedObjectContext)
            profile.username = username
            profile.email = email
            profile.avatarURL = avatarURL
            profile.bio = bio
            profile.isLoggedIn = true
            profile.peerIDObject = peerID
            print("Created new profile: \(username)")
        }
        
        saveContext()
        print("ProximityManager Profile: \(currentUserProfile?.wrappedUsername ?? "None")")
    }
    
    func fetchOrCreateProfile(for peerID: MCPeerID) -> UserProfile {
        if let existingProfile = fetchUserProfile(for: peerID) {
            return existingProfile
        } else {
            let profile = UserProfile(context: managedObjectContext)
            profile.peerIDObject = peerID
            profile.username = "Unknown User"
            saveProfileChanges(profile)
            print("Created placeholder profile for peer: \(peerID.displayName)")
            return profile
        }
    }
    
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
    // MARK: - Request Social Media
    func requestSocialMedia(from requesterID: MCPeerID, to targetID: MCPeerID) {
        guard let targetProfile = fetchUserProfile(for: targetID) else {
            print("Target user not found.")
            return
        }
        
        // Store the request in Bob's profile
        if var requests = targetProfile.socialMediaRequests as? Set<String> {
            requests.insert(requesterID.displayName)
            targetProfile.socialMediaRequests = requests as NSSet
        } else {
            targetProfile.socialMediaRequests = [requesterID.displayName] as NSSet
        }
        
        saveProfileChanges(targetProfile)
        print("\(requesterID.displayName) requested social media from \(targetID.displayName)")
    }

    // MARK: - Approve Social Media Request
    func approveSocialMediaRequest(for requesterID: MCPeerID, by targetID: MCPeerID) {
        guard let targetProfile = fetchUserProfile(for: targetID),
              let requesterProfile = fetchUserProfile(for: requesterID) else {
            print("Either requester or target profile not found.")
            return
        }

        // Remove request after approval
        if var requests = targetProfile.socialMediaRequests as? Set<String> {
            requests.remove(requesterID.displayName)
            targetProfile.socialMediaRequests = requests as NSSet
        }

        // Copy social media links to the requester’s view
        requesterProfile.socialMediaLinks = targetProfile.socialMediaLinks

        saveProfileChanges(targetProfile)
        saveProfileChanges(requesterProfile)
        
        print("\(targetID.displayName) approved social media request from \(requesterID.displayName)")
    }

    // MARK: - Reject Social Media Request
    func rejectSocialMediaRequest(for requesterID: MCPeerID, by targetID: MCPeerID) {
        guard let targetProfile = fetchUserProfile(for: targetID) else { return }
        
        if var requests = targetProfile.socialMediaRequests as? Set<String> {
            requests.remove(requesterID.displayName)
            targetProfile.socialMediaRequests = requests as NSSet
            saveProfileChanges(targetProfile)
        }
        
        print("\(targetID.displayName) rejected social media request from \(requesterID.displayName)")
    }
    
    // MARK: - Profile Caching & Offline Handling
    func cachePeerProfile(peerID: MCPeerID, profile: UserProfile, isMatched: Bool = false) {
        let cachedProfile = fetchOrCreateProfile(for: peerID)

        cachedProfile.username = profile.username ?? "Unknown"
        cachedProfile.bio = profile.bio ?? "No bio available"
        cachedProfile.avatarURL = profile.avatarURL
        cachedProfile.email = profile.email ?? "No email"
        cachedProfile.isLoggedIn = isMatched
        
        // Ensure timestamp for matched profiles if necessary
        if isMatched {
            cachedProfile.matchedTimestamp = Date()
        }

        saveProfileChanges(cachedProfile)

        let profileType = isMatched ? "Matched" : "General"
        print("Cached \(profileType) profile for peer: \(peerID.displayName)")
    }

    // MARK: - Fetch Offline Profiles (Optimized)
    func fetchOfflineProfiles(includeMatched: Bool = false, includeLocation: Bool = false) -> [UserProfile] {
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        var predicates: [NSPredicate] = [NSPredicate(format: "isLoggedIn == false")]

        if includeMatched {
            predicates.append(NSPredicate(format: "matchedTimestamp != nil"))
        }
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        do {
            let profiles = try managedObjectContext.fetch(request)
            return includeLocation ? profiles.filter { $0.latitude != 0.0 && $0.longitude != 0.0 } : profiles
        } catch {
            print("Failed to fetch offline profiles: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Auto Load Cached Profile if Needed
    func loadCachedProfile() {
        print("Loading last cached user profile...")
        if let lastLoggedProfile = UserProfile.fetchLoggedInUser(context: managedObjectContext) {
            self.currentUserProfile = lastLoggedProfile
            print("Loaded cached profile: \(lastLoggedProfile.wrappedUsername)")
        } else {
            print("No cached profile found.")
        }
    }

    func loadLoggedInProfile() {
        print("Loading logged-in user profile...")
        if let loggedInProfile = UserProfile.fetchLoggedInUser(context: managedObjectContext) {
            self.currentUserProfile = loggedInProfile
            setupPeerID()
            print("Loaded profile: \(loggedInProfile.wrappedUsername)")
        } else {
            print("No logged-in profile found. Checking cache...")
            loadCachedProfile()
        }
        
        // Attempt to reconnect previously known peers
        loadAndReconnectPeers()
    }

    // MARK: - Combined Profiles (Online + Offline)
    func combinedProfiles(includeMatched: Bool = false, includeLocation: Bool = false) -> [UserProfile] {
        let activePeers = connectedPeers.compactMap { $0.profile } // Peers currently connected
        let offlineProfiles = fetchOfflineProfiles(includeMatched: includeMatched, includeLocation: includeLocation)
        
        return activePeers + offlineProfiles
    }
    
    func syncPeerLocation(peerID: MCPeerID, location: CLLocation) {
        if let profile = fetchUserProfile(for: peerID) {
            profile.latitude = location.coordinate.latitude
            profile.longitude = location.coordinate.longitude
            saveProfileChanges(profile)
            print("Synced location for peer: \(peerID.displayName)")
        } else {
            print("No profile found for peer \(peerID.displayName). Cannot sync location.")
        }
    }
    
    func saveProfileChanges(_ profile: UserProfile) {
        do {
            try managedObjectContext.save()
            print("Profile saved successfully.")
        } catch let error as NSError {
            print("Failed to save profile: \(error), \(error.userInfo)")
        }
    }
    
    func saveContext() {
        do {
            try managedObjectContext.save()
            print("Context saved successfully.")
        } catch let error as NSError {
            print("Failed to save context: \(error.localizedDescription)")
            self.error = error
        }
    }
    
    func markCurrentUserAsOffline() {
        guard let userProfile = currentUserProfile else {
            print("No logged-in user profile to mark as offline.")
            return
        }
        userProfile.isLoggedIn = false
        saveProfileChanges(userProfile)
        
        // Save connected peers before marking offline
        saveConnectedPeers()
        
        print("User marked as offline: \(userProfile.wrappedUsername)")
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
