import SwiftUI
import CoreAudioKit

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
    
    func makeUIViewController(context: Context) -> AUViewController {
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: AUViewController, context: Context) {}
}
#endif
