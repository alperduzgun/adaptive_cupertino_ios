import Flutter
import UIKit
import os.log

/// Manager for Native iOS Bottom Sheets (Liquid Glass Edition)
///
/// Uses UISheetPresentationController for native behavior and iOS 26 Liquid Glass styling.
@available(iOS 15.0, *)
class AdaptiveCupertinoSheetManager: NSObject, UISheetPresentationControllerDelegate {
    private static let logger = OSLog(subsystem: "com.adaptive_cupertino_ios", category: "SheetManager")
    private static var shared = AdaptiveCupertinoSheetManager()
    
    private static weak var currentFlutterViewController: FlutterViewController?
    private static var activeEngine: FlutterEngine?
    
    /// Presents a native bottom sheet
    static func showSheet(
        messenger: FlutterBinaryMessenger,
        params: [String: Any],
        completion: @escaping (Bool) -> Void
    ) {
        // Self-Healing: Prevent multiple concurrent sheets which might lead to engine leaks
        if activeEngine != nil {
            os_log(.error, log: logger, "Attempted to show sheet while another is already active. Rejecting.")
            completion(false)
            return
        }

        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            os_log(.error, log: logger, "Failed to find root view controller for sheet presentation")
            completion(false)
            return
        }
        
        let contentId = params["contentId"] as? String
        
        // 1. Create a container view controller
        let contentVC = UIViewController()
        contentVC.view.backgroundColor = .clear // Let the glass effect shine through
        
        // 2. Setup the Sheet Presentation Controller
        if let sheet = contentVC.sheetPresentationController {
            sheet.delegate = shared
            configureSheet(sheet, params: params)
        }
        
        // 3. Apply Liquid Glass styling (iOS 26+)
        if IOSVersionDetector.supportsLiquidGlassSheets() {
            applyLiquidGlassEffect(to: contentVC.view)
        } else {
            contentVC.view.backgroundColor = .systemBackground.withAlphaComponent(0.8)
        }
        
        // 4. Handle Content Embedding (Fail Fast Guard)
        if let id = contentId {
            let success = embedFlutterContent(id: id, in: contentVC)
            if !success {
                os_log(.error, log: logger, "Fail Fast: Aborting sheet presentation due to embedding failure")
                completion(false)
                return
            }
        }
        
        // 5. Present
        rootViewController.present(contentVC, animated: true) {
            os_log(.info, log: logger, "Native sheet presented successfully with contentId: %{public}@", contentId ?? "none")
            completion(true)
        }
    }
    
    @discardableResult
    private static func embedFlutterContent(id: String, in parentVC: UIViewController) -> Bool {
        // Isolated Sibling Engine Strategy:
        // We use FlutterEngineGroup to spawn a lightweight sibling engine.
        // This ensures the sheet has its own isolate and navigator,
        // preventing the "saçma" mirroring of the main app's TabBar/AppBar.
        
        guard let pluginInstance = AdaptiveCupertinoPlugin.shared else {
            os_log(.error, log: logger, "Failed to retrieve AdaptiveCupertinoPlugin instance")
            return false
        }
        
        guard let engine = pluginInstance.spawnEngine(withRoute: "/adaptive-sheet?id=\(id)") else {
            os_log(.error, log: logger, "Failed to spawn sibling Flutter engine")
            return false
        }
        
        // Chaos Remediation: Track engine strongly to ensure lifecycle control
        self.activeEngine = engine
        
        let flutterViewController = FlutterViewController(
            engine: engine, 
            nibName: nil, 
            bundle: nil
        )
        
        // Setup as child view controller
        parentVC.addChild(flutterViewController)
        flutterViewController.view.translatesAutoresizingMaskIntoConstraints = false
        flutterViewController.view.backgroundColor = .clear
        parentVC.view.addSubview(flutterViewController.view)
        
        NSLayoutConstraint.activate([
            flutterViewController.view.leadingAnchor.constraint(equalTo: parentVC.view.leadingAnchor),
            flutterViewController.view.trailingAnchor.constraint(equalTo: parentVC.view.trailingAnchor),
            flutterViewController.view.topAnchor.constraint(equalTo: parentVC.view.topAnchor),
            flutterViewController.view.bottomAnchor.constraint(equalTo: parentVC.view.bottomAnchor)
        ])
        
        flutterViewController.didMove(toParent: parentVC)
        self.currentFlutterViewController = flutterViewController
        
        // Phase 2.1: Smooth Transitions
        // Start hidden to prevent "blank first frame" flicker.
        // We wait for the Dart signal (unhide_content) to fade in.
        flutterViewController.view.alpha = 0
        
        let lifecycleChannel = FlutterMethodChannel(
            name: "adaptive_cupertino_ios/sheet_lifecycle",
            binaryMessenger: engine.binaryMessenger
        )
        
        lifecycleChannel.setMethodCallHandler { [weak flutterViewController] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            if call.method == "unhide_content" {
                os_log(.info, log: AdaptiveCupertinoSheetManager.logger, "First frame ready signal received from Dart. Fading in.")
                UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
                    flutterViewController?.view.alpha = 1.0
                } completion: { _ in
                    result(nil)
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }
        
        // Chaos-Proof: Fail-safe timer to ensure content is eventually visible 
        // even if Dart signal fails for some reason.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak flutterViewController] in
            if let vc = flutterViewController, vc.view.alpha < 1.0 {
                os_log(.error, log: AdaptiveCupertinoSheetManager.logger, "Fail-safe: Force-unhiding sheet content after timeout.")
                UIView.animate(withDuration: 0.1) {
                    vc.view.alpha = 1.0
                }
            }
        }
        
        return true
    }
    
    private static func configureSheet(_ sheet: UISheetPresentationController, params: [String: Any]) {
        // Detents
        var detents: [UISheetPresentationController.Detent] = [.medium()]
        if let detentList = params["detents"] as? [String] {
            detents = detentList.compactMap { d -> UISheetPresentationController.Detent? in
                if d == "large" { return .large() }
                if d == "medium" { return .medium() }
                return nil
            }
        }
        sheet.detents = detents
        
        // Gesture Lock: Blocking pass-through touches to the background
        // By setting largestUndimmedDetentIdentifier to nil, the sheet becomes modal in its interaction.
        sheet.largestUndimmedDetentIdentifier = nil
        sheet.prefersScrollingExpandsWhenScrolledToEdge = true
        
        // Grabber
        sheet.prefersGrabberVisible = params["showGrabber"] as? Bool ?? true
        
        // Corner Radius
        if let radius = params["cornerRadius"] as? NSNumber {
            sheet.preferredCornerRadius = CGFloat(truncating: radius)
        } else {
            sheet.preferredCornerRadius = 16.0
        }
    }
    
    private static func applyLiquidGlassEffect(to view: UIView) {
        // Optimization: isInteractive=false (reduces per-frame calculation)
        // applyGeometry=false (sheet controller handles corner clipping)
        let glassView = AdaptiveGlassView(frame: view.bounds, isInteractive: false, applyGeometry: false)
        glassView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(glassView, at: 0)
        
        NSLayoutConstraint.activate([
            glassView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            glassView.topAnchor.constraint(equalTo: view.topAnchor),
            glassView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - UISheetPresentationControllerDelegate
    
    private static var currentChannel: FlutterMethodChannel?
    
    static func setChannel(_ channel: FlutterMethodChannel) {
        currentChannel = channel
    }
    
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        if let id = sheetPresentationController.selectedDetentIdentifier {
            os_log(.info, log: AdaptiveCupertinoSheetManager.logger, "Sheet detent changed to: %{public}@", id.rawValue)
            
            // Notify Dart about the detent change (Resize Bridge)
            AdaptiveCupertinoSheetManager.currentChannel?.invokeMethod("onDetentChanged", arguments: [
                "detent": id.rawValue
            ])
        }
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        os_log(.info, log: AdaptiveCupertinoSheetManager.logger, "Sheet was dismissed by user")
        
        // Chaos Remediation: Explicitly dispose of the isolated sibling engine
        // By nullifying the strong reference, we allow FlutterEngineGroup to reclaim resources.
        if AdaptiveCupertinoSheetManager.activeEngine != nil {
            os_log(.info, log: AdaptiveCupertinoSheetManager.logger, "Disposing of isolated sibling engine")
            AdaptiveCupertinoSheetManager.activeEngine = nil
        }
        
        // Notify Dart to cleanup registry
        AdaptiveCupertinoSheetManager.currentChannel?.invokeMethod("onSheetDismissed", arguments: nil)
    }
}
