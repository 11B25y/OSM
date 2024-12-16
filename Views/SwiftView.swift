import SwiftUI

struct SwiftView: View {
    @EnvironmentObject var proximityManager: ProximityManager

    var body: some View {
        VStack {
            Text("Bluetooth Status")
            Circle()
                .fill(proximityManager.bluetoothEnabled ? Color.green : Color.red)
                .frame(width: 100, height: 100)

            // Add other UI elements and logic here
        }
        .onAppear {
            // Check Bluetooth status when the view appears
            proximityManager.checkBluetoothStatus()
        }
    }
}
