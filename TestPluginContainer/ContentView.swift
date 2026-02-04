import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Test Effect Plugin")
                .font(.title)
                .fontWeight(.bold)
            
            Text("This app contains the TestEffectAUv3 Audio Unit extension.")
                .multilineTextAlignment(.center)
                .padding()
            
            Text("Installation Instructions:")
                .font(.headline)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("1. Run this app once to install the extension")
                Text("2. Open AUv3TestHost app")
                Text("3. Tap 'Refresh Plugins'")
                Text("4. Select 'Effect' type")
                Text("5. Find 'Test Effect' in the list")
            }
            .padding()
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
