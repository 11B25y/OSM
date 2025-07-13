import Foundation
import MultipeerConnectivity
import CoreBluetooth
import CoreData
import Combine
import CoreLocation

class ProximityManager: NSObject, ObservableObject, CBCentralManagerDelegate, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate {

    
    // MARK: - Singleton Instance
    static let shared = ProximityManager(context: PersistenceController.shared.container.viewContext)

    // MARK: - Properties
    private let serviceType = "proximity1"
    private let storedPeersKey = "storedConnectedPeers"
    
    var peerID: MCPeerID!
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!
    private var centralManager: CBCentralManager?

    // MARK: - Discovery Configuration
    private var maxDiscoveryDistance: Double = 100.0  // Default 100 meters
    private var showSubscribedOnly = false
    private var lastKnownLocations: [MCPeerID: CLLocation] = [:]
    
    @Published var isAdvertising = false
    @Published var isBrowsing = false
    @Published var bluetoothEnabled = false
    @Published var receivedMessages: [String] = []
    @Published var connectedPeers: [SelectedPeer] = []
    @Published var reconnecting = false
    @Published var isScanning = false
    @Published var currentUserProfile: UserProfile?
    @Published var receivedInvitationFromPeer: IdentifiablePeer?
    @Published var error: Error?
    @Published var useMockProfiles = false
    
    private var currentInvitationHandler: ((Bool, MCSession?) -> Void)?
    var managedObjectContext: NSManagedObjectContext
    
    // MARK: - Initializer
    init(context: NSManagedObjectContext) {
        self.managedObjectContext = context
        super.init()

        // 1) Load your real user profile first:
        setupPeerID()             // sets self.peerID from currentUserProfile or device name
        populateProfileIfNeeded() // fetch existing profile if any
        loadLoggedInProfile()     // loads the logged-in profile and assigns peerID accordingly

        // 2) Now create your Multipeer session/advertiser/browser
        session = MCSession(peer: self.peerID,
                            securityIdentity: nil,
                            encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(
            peer: self.peerID,
            discoveryInfo: nil,      // no custom room tag
            serviceType: serviceType
        )
        browser = MCNearbyServiceBrowser(peer: self.peerID,
                                         serviceType: serviceType)

        // 3) Wire up delegates
        session.delegate    = self
        advertiser.delegate = self
        browser.delegate    = self

        // 4) Kick off Bluetooth and discovery
        centralManager = CBCentralManager(delegate: self, queue: nil)
        checkBluetoothStatus()
        loadAndReconnectPeers()
    }
    
    // MARK: - Bluetooth State Management
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
         DispatchQueue.main.async {
             self.bluetoothEnabled = central.state == .poweredOn
             if self.bluetoothEnabled {
                 self.startDiscovery()
                 print("Bluetooth is powered on, starting discovery.")
             } else {
                 self.stopDiscovery()
                 print("Bluetooth is off, stopping discovery.")
             }
         }
    }
    func checkBluetoothStatus() {
        if let central = centralManager {
            centralManagerDidUpdateState(central)
        } else {
            print("⚠️ Central manager is not initialized yet.")
        }
    }
    func populateProfileIfNeeded() {
        guard let validPeerID = peerID else {
            print("Error: PeerID is nil, cannot fetch user profile.")
            return
        }

        if currentUserProfile == nil {
            currentUserProfile = fetchUserProfile(for: validPeerID)
            
            if currentUserProfile == nil {
                print("No user profile found; populate as needed.")
            }
        }
        print("ProximityManager Profile: \(currentUserProfile?.wrappedUsername ?? "None")")
    }

    // MARK: - PeerID Setup
    func setupPeerID() {
        if let username = currentUserProfile?.wrappedUsername, !username.isEmpty {
            self.peerID = MCPeerID(displayName: username)
        } else {
            self.peerID = MCPeerID(displayName: UIDevice.current.name) // Fallback to device name if no username
        }
        print("PeerID set to: \(peerID.displayName)")
    }
    
    // MARK: - PeerID Retrieval
    func getPeerID() -> MCPeerID {
        return self.peerID
    }

    // MARK: - Discovery Methods
    func startDiscovery() {
        if !isAdvertising {
            advertiser.startAdvertisingPeer()  // Start advertising
            isAdvertising = true
        }
        if !isBrowsing {
            browser.startBrowsingForPeers()  // Start browsing for nearby peers
            isBrowsing = true
        }
        isScanning = true
    }

    func stopDiscovery() {
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

    func updateDiscoveryDistance(_ distance: Double) {
        maxDiscoveryDistance = max(0, distance)  // Ensure non-negative
        print("Updated discovery distance to: \(maxDiscoveryDistance) meters")
        
        // Filter existing peers based on new distance
        filterPeersByDistance()
    }

    func updateSubscriptionFilter(_ isSubscribed: Bool) {
        showSubscribedOnly = isSubscribed
        print("Subscription filter updated to show only subscribed users: \(showSubscribedOnly)")
        
        // Filter existing peers based on new subscription setting
        filterPeersBySubscription()
    }

    // MARK: - Location-based Discovery
    private func filterPeersByDistance() {
        DispatchQueue.main.async {
            guard let currentLocation = LocationManager.shared.currentLocation else {
                print("Current location unavailable")
                return
            }

            self.connectedPeers.forEach { peer in
                if let peerLocation = self.lastKnownLocations[peer.peerID] {
                    let distance = currentLocation.distance(from: peerLocation)
                    
                    if distance > self.maxDiscoveryDistance {
                        // Disconnect peers outside range
                        print("Peer \(peer.peerID.displayName) outside range (\(Int(distance))m), disconnecting")
                        self.session.disconnect()
                        self.connectedPeers.removeAll { $0.peerID == peer.peerID }
                    }
                }
            }
        }
    }
    private func filterPeersBySubscription() {
        guard showSubscribedOnly else { return }
        
        DispatchQueue.main.async {
            self.connectedPeers.removeAll { peer in
                guard let profile = peer.profile else { return true }
                let isSubscribed = profile.isPremiumUser
                
                if !isSubscribed {
                    print("Removing unsubscribed peer: \(peer.peerID.displayName)")
                    self.session.disconnect()
                }
                
                return !isSubscribed
            }
        }
    }


    // MARK: - Session Management
    func restartSession() {
        if connectedPeers.isEmpty {
            print("No connected peers to restart the session.")
            return
        }
        reconnecting = true
        print("Restarting session...")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.loadAndReconnectPeers()
        }
    }
    // MARK: - Peer Management
    func saveConnectedPeers() {
        // Save the connected peers into a persistent storage (CoreData or UserDefaults)
        // This can be done using CoreData for better management
        print("Saving connected peers: \(connectedPeers.count)")
        // CoreData or UserDefaults code to persist peers
    }
    
    // Change from private to internal or public
    func loadAndReconnectPeers() {
        // Load saved peers from persistent storage
        // Then attempt to reconnect to them
        print("Loading and reconnecting to saved peers")
        // Reconnect logic
    }
  
    func reconnectToPeer(_ peerID: MCPeerID) {
        print("Attempting to reconnect to \(peerID.displayName)...")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)  // Log invitation attempts
    }

    /// Invite a peer to join the current session.
    /// - Parameter peerID: The peer identifier to invite.
    public func invite(_ peerID: MCPeerID) {
        print("Inviting \(peerID.displayName)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }

     // MARK: - Message Handling
    func sendMessage(_ message: String) {
        guard !message.isEmpty else { return }
        if let data = message.data(using: .utf8) {
            send(data: data, to: connectedPeers.map { $0.peerID })
        }
    }

    func send(data: Data, to peers: [MCPeerID]) {
        guard !peers.isEmpty else { return }
        do {
            try session.send(data, toPeers: peers, with: .reliable)
        } catch {
            print("Error sending data: \(error.localizedDescription)")
        }
    }
    // MARK: - Profile Management
    func createProfile(_ profile: UserProfile) {
        // Store the created profile in ProximityManager
        self.currentUserProfile = profile
        print("ProximityManager Profile: \(profile.wrappedUsername)")
    }
    // Fetch the logged-in user from Core Data
    func fetchLoggedInUser(context: NSManagedObjectContext) -> UserProfile? {
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "isLoggedIn == true")
        request.fetchLimit = 1

        do {
            let results = try context.fetch(request)
            print("Found logged-in user: \(results.first?.wrappedUsername ?? "No User")")
            return results.first
        } catch {
            print("Failed to fetch logged-in user: \(error.localizedDescription)")
            return nil
        }
    }
    // MARK: - Social Media Request Management
    func requestSocialMedia(from requesterID: MCPeerID, to targetID: MCPeerID) {
        guard let targetProfile = fetchUserProfile(for: targetID) else { return }
        
        var requests = targetProfile.socialMediaRequests as? Set<String> ?? []
        requests.insert(requesterID.displayName)
        targetProfile.socialMediaRequests = requests as NSSet
        
        saveProfileChanges(profile: targetProfile) // Corrected argument label here
        
        print("\(requesterID.displayName) requested social media from \(targetID.displayName)")
    }

    func approveSocialMediaRequest(for requesterID: MCPeerID, by targetID: MCPeerID) {
        guard let targetProfile = fetchUserProfile(for: targetID),
              let requesterProfile = fetchUserProfile(for: requesterID) else { return }

        var requests = targetProfile.socialMediaRequests as? Set<String> ?? []
        requests.remove(requesterID.displayName)
        targetProfile.socialMediaRequests = requests as NSSet
        requesterProfile.socialMediaLinks = targetProfile.socialMediaLinks

        saveProfileChanges(profile: targetProfile) // Update to use the correct label
        saveProfileChanges(profile: requesterProfile) // Update to use the correct label
        print("\(targetID.displayName) approved social media request from \(requesterID.displayName)")
    }
    func rejectSocialMediaRequest(for requesterID: MCPeerID, by targetID: MCPeerID) {
        guard let targetProfile = fetchUserProfile(for: targetID) else { return }
        
        if var requests = targetProfile.socialMediaRequests as? Set<String> {
            requests.remove(requesterID.displayName)
            targetProfile.socialMediaRequests = requests as NSSet
            saveProfileChanges(profile: targetProfile)
        }
        
        print("\(targetID.displayName) rejected social media request from \(requesterID.displayName)")
    }

    // MARK: - Profile Caching & Offline Management
    func cachePeerProfile(peerID: MCPeerID, profile: UserProfile, isMatched: Bool = false) {
        let cachedProfile = fetchOrCreateProfile(for: peerID)

        cachedProfile.username = profile.username ?? "Unknown"
        cachedProfile.bio = profile.bio ?? "No bio available"
        cachedProfile.avatarURL = profile.avatarURL
        cachedProfile.email = profile.email ?? "No email"
        cachedProfile.isLoggedIn = isMatched
        
        if isMatched {
            cachedProfile.matchedTimestamp = Date()
        }

        saveProfileChanges(profile:cachedProfile)

        let profileType = isMatched ? "Matched" : "General"
        print("Cached \(profileType) profile for peer: \(peerID.displayName)")
    }

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

    func combinedProfiles(includeMatched: Bool = false, includeLocation: Bool = false) -> [UserProfile] {
        let activePeers = connectedPeers.compactMap { $0.profile }
        let offlineProfiles = fetchOfflineProfiles(includeMatched: includeMatched, includeLocation: includeLocation)
        return activePeers + offlineProfiles
    }

    private func fetchUserProfile(for peerID: MCPeerID) -> UserProfile? {
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "peerID == %@", peerID.displayName)
        return try? managedObjectContext.fetch(request).first
    }

    private func fetchOrCreateProfile(for peerID: MCPeerID) -> UserProfile {
        if let existingProfile = fetchUserProfile(for: peerID) {
            return existingProfile
        }
        let profile = UserProfile(context: managedObjectContext)
        profile.peerIDObject = peerID
        profile.username = "Unknown User"
        saveProfileChanges(profile: profile) // Corrected argument label here
        return profile
    }
    // MARK: - Profile Loading and Management
    func loadCachedProfile() {
        print("Loading last cached user profile...")
        if let lastLoggedProfile = fetchLoggedInUser(context: managedObjectContext) {
            self.currentUserProfile = lastLoggedProfile
            print("Loaded cached profile: \(lastLoggedProfile.wrappedUsername)")
        } else {
            print("No cached profile found.")
        }
    }
    func loadLoggedInProfile() {
        print("Loading logged-in user profile...")
        if let loggedInUser = fetchLoggedInUser(context: managedObjectContext) {
            self.currentUserProfile = loggedInUser
            setupPeerID()
            print("Loaded profile: \(loggedInUser.wrappedUsername)")
        } else {
            print("No logged-in profile found. Checking cache...")
            loadCachedProfile()
        }
        loadAndReconnectPeers()
    }

    func syncPeerLocation(peerID: MCPeerID, location: CLLocation) {
        if let profile = fetchUserProfile(for: peerID) {
            profile.latitude = location.coordinate.latitude
            profile.longitude = location.coordinate.longitude
            saveProfileChanges(profile: profile) // Corrected argument label here
            print("Synced location for peer: \(peerID.displayName)")
        } else {
            print("No profile found for peer \(peerID.displayName). Cannot sync location.")
        }
    }
    
    func saveProfileChanges(profile: UserProfile) {
        do {
            try managedObjectContext.save()
            self.currentUserProfile = fetchLoggedInUser(context: managedObjectContext)
            print("Profile saved and reloaded: \(self.currentUserProfile?.wrappedUsername ?? "No Profile")")
        } catch let error as NSError {
            print("Failed to save profile: \(error.localizedDescription), \(error.userInfo)")
        }
    }
    
    func saveContext() {
        // Perform on background thread
        DispatchQueue.global(qos: .background).async {
            do {
                try self.managedObjectContext.save()
                DispatchQueue.main.async {
                    print("Context saved successfully.")
                }
            } catch let error as NSError {
                DispatchQueue.main.async {
                    print("Failed to save profile: \(error.localizedDescription), \(error.userInfo)")
                }
            } catch {
                DispatchQueue.main.async {
                    print("Failed to save profile: \(error.localizedDescription)")
                }
            }
        }
    }
    func markCurrentUserAsOffline() {
        guard let userProfile = currentUserProfile else {
            print("No logged-in user profile to mark as offline.")
            return
        }
        userProfile.isLoggedIn = false
        saveProfileChanges(profile: userProfile)  // Explicitly pass the profile argument
        saveConnectedPeers()
        print("User marked as offline: \(userProfile.wrappedUsername)")
    }
    // MARK: - MCSessionDelegate
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                print("Peer connected: \(peerID.displayName)")
                // Add peer to the list of connected peers
                let profile = self.fetchOrCreateProfile(for: peerID)
                if !self.connectedPeers.contains(where: { $0.peerID == peerID }) {
                    self.connectedPeers.append(SelectedPeer(id: UUID(), peerID: peerID, profile: profile))
                }

            case .notConnected:
                print("Peer disconnected: \(peerID.displayName)")
                // Remove the peer from the connected list
                self.connectedPeers.removeAll { $0.peerID == peerID }

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
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        print("Received stream \(streamName) from peer: \(peerID.displayName)")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        print("Started receiving resource \(resourceName) from peer: \(peerID.displayName)")
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
            print("Auto-accepting invite from \(peerID.displayName)")
            invitationHandler(true, self.session)
        }
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async {
            self.error = error
            print("Failed to start advertising: \(error.localizedDescription)")
        }
    }
    
    func respondToInvitation(accepted: Bool) {
        currentInvitationHandler?(accepted, accepted ? session : nil)
        receivedInvitationFromPeer = nil
    }
    
    // MARK: - MCNearbyServiceBrowserDelegate
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async {
            if !self.connectedPeers.contains(where: { $0.peerID == peerID }) {
                let profile = self.fetchOrCreateProfile(for: peerID)
                self.connectedPeers.append(SelectedPeer(id: UUID(), peerID: peerID, profile: profile))
                browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 20)
                print("Auto-invited \(peerID.displayName)")
            }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.connectedPeers.removeAll { $0.peerID == peerID }
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async {
            self.error = error
            print("Error starting browsing for peers: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Cleanup
    deinit {
        session.disconnect()
        stopDiscovery()
    }
}
