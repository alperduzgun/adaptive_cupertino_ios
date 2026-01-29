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
    
    /// Presents a native bottom sheet
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
        // contentVC.isModalInPresentation = true // REVERTED: Restores native swipe-to-dismiss
        
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
        
        // 4. Present
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
    
    func sheetPresentationControllerDidChangeSelectedDetentIdentifier(_ sheetPresentationController: UISheetPresentationController) {
        if let id = sheetPresentationController.selectedDetentIdentifier {
            os_log(.info, log: AdaptiveCupertinoSheetManager.logger, "Sheet detent changed to: %{public}@", id.rawValue)
        }
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        os_log(.info, log: AdaptiveCupertinoSheetManager.logger, "Sheet was dismissed by user")
    }
}
