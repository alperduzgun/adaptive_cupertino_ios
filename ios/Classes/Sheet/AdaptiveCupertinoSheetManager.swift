import Flutter
import UIKit
import os.log

/// Manager for Native iOS Bottom Sheets (Liquid Glass Edition)
///
/// Uses UISheetPresentationController for native behavior and iOS 26 Liquid Glass styling.
@available(iOS 15.0, *)
class AdaptiveCupertinoSheetManager {
    private static let logger = OSLog(subsystem: "com.adaptive_cupertino_ios", category: "SheetManager")
    
    /// Presents a native bottom sheet
    /// 
    /// - Parameters:
    ///   - messenger: The binary messenger for communication
    ///   - arguments: Parameters from Dart (detents, contentId, etc.)
    ///   - completion: Callback when presented
    static func showSheet(
        messenger: FlutterBinaryMessenger,
        params: [String: Any],
        completion: @escaping (Bool) -> Void
    ) {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            os_log(.error, log: logger, "Failed to find root view controller for sheet presentation")
            completion(false)
            return
        }
        
        // 1. Create a container view controller
        let contentVC = UIViewController()
        contentVC.view.backgroundColor = .clear // Let the glass effect shine through
        
        // 2. Setup the Sheet Presentation Controller
        if let sheet = contentVC.sheetPresentationController {
            configureSheet(sheet, params: params)
        }
        
        // 3. Apply Liquid Glass styling (iOS 26+)
        if IOSVersionDetector.supportsLiquidGlassSheets() {
            applyLiquidGlassEffect(to: contentVC.view)
        } else {
            contentVC.view.backgroundColor = .systemBackground.withAlphaComponent(0.8)
        }
        
        // 4. Handle Content Embedding (If we want to show a Flutter widget inside)
        // For now, we'll just demonstrate the native container. 
        // In a full implementation, we would register another PlatformView or pass a Texture.
        
        // 5. Present
        rootViewController.present(contentVC, animated: true) {
            os_log(.info, log: logger, "Native sheet presented successfully")
            completion(true)
        }
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
        
        // Grabber
        sheet.prefersGrabberVisible = params["showGrabber"] as? Bool ?? true
        
        // Floating Geometry (iOS 26+)
        if #available(iOS 26.0, *), IOSVersionDetector.supportsLiquidGlassSheets() {
             // In iOS 26, sheet presentation is floating by default if configured
             // We can influence the edge insets here if needed
        }
        
        // Corner Radius
        if let radius = params["cornerRadius"] as? NSNumber {
            sheet.preferredCornerRadius = CGFloat(truncating: radius)
        } else {
            sheet.preferredCornerRadius = 16.0
        }
    }
    
    private static func applyLiquidGlassEffect(to view: UIView) {
        let glassView = AdaptiveGlassView(frame: view.bounds)
        glassView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(glassView, at: 0)
        
        NSLayoutConstraint.activate([
            glassView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            glassView.topAnchor.constraint(equalTo: view.topAnchor),
            glassView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}
