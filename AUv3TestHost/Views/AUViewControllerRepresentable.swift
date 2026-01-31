import SwiftUI
import CoreAudioKit
import os

#if os(macOS)
struct AUViewControllerRepresentable: NSViewControllerRepresentable {
    let viewController: AUViewController
    
    func makeNSViewController(context: Context) -> AUViewController {
        return viewController
    }
    
    func updateNSViewController(_ nsViewController: AUViewController, context: Context) {}
}
#else
struct AUViewControllerRepresentable: UIViewControllerRepresentable {
    let viewController: AUViewController
    private let log = Logger(subsystem: "com.test.AUv3TestHost", category: "AUViewControllerRepresentable")
    
    func makeUIViewController(context: Context) -> AUViewController {
        log.info("Creating AUViewController for iOS")
        
        // Configure view controller for iOS presentation
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Set background color if needed
        if viewController.view.backgroundColor == nil {
            viewController.view.backgroundColor = .systemBackground
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: AUViewController, context: Context) {
        // Handle any updates to the view controller
        log.debug("Updating AUViewController")
    }
    
    static func dismantleUIViewController(_ uiViewController: AUViewController, coordinator: ()) {
        // Clean up when view controller is removed
        Logger(subsystem: "com.test.AUv3TestHost", category: "AUViewControllerRepresentable")
            .info("Dismantling AUViewController")
    }
}
#endif
