import CoreAudioKit
import SwiftUI
import AVFoundation

/// View Controller for the Test Effect UI
public class EffectViewController: AUViewController {
    
    private var audioUnit: TestEffectAudioUnit?
    
    public init(audioUnit: TestEffectAudioUnit) {
        self.audioUnit = audioUnit
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let audioUnit = audioUnit else { return }
        
        // Create SwiftUI view
        let effectView = EffectView(audioUnit: audioUnit)
        let hostingController = UIHostingController(rootView: effectView)
        
        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // Setup constraints
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        // Set preferred size
        preferredContentSize = CGSize(width: 300, height: 200)
    }
}

/// SwiftUI view for the effect parameters
struct EffectView: View {
    let audioUnit: TestEffectAudioUnit
    
    @State private var gain: Float = 1.0
    @State private var bypass: Bool = false
    
    // Timer for polling parameter changes from the audio unit
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Test Effect")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 16) {
                // Bypass toggle
                HStack {
                    Text("Bypass")
                        .font(.headline)
                    Spacer()
                    Toggle("", isOn: $bypass)
                        .onChange(of: bypass) { oldValue, newValue in
                            setBypass(newValue)
                        }
                }
                
                // Gain slider
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gain")
                        .font(.headline)
                    HStack {
                        Text("0.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: $gain, in: 0.0...2.0)
                            .onChange(of: gain) { oldValue, newValue in
                                setGain(newValue)
                            }
                        Text("2.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(String(format: "%.2f", gain))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Parameter display
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Gain = \(String(format: "%.2f", gain)), Bypass = \(bypass ? "On" : "Off")")
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
            .padding()
        }
        .padding()
        .onAppear {
            loadParameters()
        }
        .onReceive(timer) { _ in
            // Poll parameters from audio unit
            if let parameterTree = audioUnit.parameterTree {
                if let gainParam = parameterTree.parameter(withAddress: 0) {
                    let currentGain = gainParam.value
                    if abs(currentGain - gain) > 0.01 {
                        gain = currentGain
                    }
                }
                if let bypassParam = parameterTree.parameter(withAddress: 1) {
                    let currentBypass = bypassParam.value >= 0.5
                    if currentBypass != bypass {
                        bypass = currentBypass
                    }
                }
            }
        }
    }
    
    private func loadParameters() {
        guard let parameterTree = audioUnit.parameterTree else { return }
        
        if let gainParam = parameterTree.parameter(withAddress: 0) {
            gain = gainParam.value
        }
        
        if let bypassParam = parameterTree.parameter(withAddress: 1) {
            bypass = bypassParam.value >= 0.5
        }
    }
    
    private func setGain(_ value: Float) {
        guard let parameterTree = audioUnit.parameterTree,
              let gainParam = parameterTree.parameter(withAddress: 0) else { return }
        gainParam.value = value
    }
    
    private func setBypass(_ value: Bool) {
        guard let parameterTree = audioUnit.parameterTree,
              let bypassParam = parameterTree.parameter(withAddress: 1) else { return }
        bypassParam.value = value ? 1.0 : 0.0
    }
}
