import SwiftUI
import CoreBluetooth
import CoreLocation

struct OnboardingView: View {
    @State private var currentStep = 0 // Track current step in onboarding
    @AppStorage("hasSeenOnboarding") var hasSeenOnboarding: Bool = false // Store onboarding completion status
    
    let onboardingData = [
        OnboardingStep(title: "Welcome to Proximity App", description: "Connect with nearby users seamlessly using advertising, browsing, and messaging features.", imageName: "network"),
        OnboardingStep(title: "Start Advertising", description: "Advertise your presence to nearby users for quick discovery.", imageName: "antenna.radiowaves.left.and.right"),
        OnboardingStep(title: "Browse Nearby Users", description: "Find users near you to exchange messages and files.", imageName: "magnifyingglass"),
        OnboardingStep(title: "Send Messages", description: "Communicate with nearby users instantly.", imageName: "message.fill"),
        OnboardingStep(title: "Request Permissions", description: "We need Bluetooth and Location permissions to offer the best experience.", imageName: "location.fill")
    ]
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Display the current onboarding step
            OnboardingStepView(step: onboardingData[currentStep])
                .transition(.slide)
            
            Spacer()
            
            // Button to move to the next onboarding step
            Button(action: {
                if currentStep < onboardingData.count - 1 {
                    currentStep += 1
                } else {
                    // Request permissions and move to the main app
                    requestPermissions()
                }
            }) {
                Text(currentStep == onboardingData.count - 1 ? "Get Started" : "Next")
                    .font(.headline)
                    .frame(width: 280, height: 50)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
            .padding(.bottom, 60)
        }
        .background(Color(.systemBackground))
        .edgesIgnoringSafeArea(.all)
    }
    
    // Request necessary permissions after onboarding
    func requestPermissions() {
        requestBluetoothPermission()
        requestLocationPermission()
        hasSeenOnboarding = true // Mark onboarding as complete
    }
    
    func requestBluetoothPermission() {
        let manager = CBCentralManager() // This will prompt the Bluetooth permission
        _ = manager.state // Access the state to trigger permission request
    }
    
    func requestLocationPermission() {
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization() // Request location access
    }
}

struct OnboardingStep {
    let title: String
    let description: String
    let imageName: String
}

struct OnboardingStepView: View {
    let step: OnboardingStep
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: step.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
            
            Text(step.title)
                .font(.largeTitle)
                .bold()
            
            Text(step.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding()
    }
}
