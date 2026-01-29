import UIKit
import os.log

/// Helper class to centralize Liquid Glass (iOS 26+) and standard blur effects.
///
/// CHAOS ENGINEERING PRINCIPLES:
/// - Performance: Reuses effects where possible
/// - Resilience: Graceful fallback to standard blur on older iOS versions
/// - Security: No custom drawing, relies on system-optimized rendering
@available(iOS 15.0, *)
class AdaptiveGlassHelper {
    private static let logger = OSLog(subsystem: "com.adaptive_cupertino_ios", category: "GlassHelper")

    /// Creates a glass effect view appropriate for the current iOS version.
    ///
    /// - Returns: A `UIView` (either a `UIVisualEffectView` or a specialized glass view)
    static func createGlassView() -> UIView {
        if IOSVersionDetector.supportsLiquidGlassSheets() {
            // iOS 26+ Native Liquid Glass
            return createModernGlassView()
        } else {
            // iOS < 26 Standard Fallback
            return createStandardBlurView()
        }
    }

    /// Creates the native iOS 26 Liquid Glass view using UIGlassEffect
    private static func createModernGlassView() -> UIView {
        // Primary: iOS 26+ UIGlassEffect
        // We use UIVisualEffectView as the container.
        let blurView = UIVisualEffectView()
        
        // Use dynamic check to avoid compiler errors on older SDKs
        if #available(iOS 26.0, *),
           let glassEffectClass = NSClassFromString("UIGlassEffect") as? NSObject.Type {
            
            // Try to instantiate UIGlassEffect(glass: .regular, isInteractive: true)
            // Note: Since we can't easily use the specific initializer with dynamic dispatch,
            // we use the generic init if available or property settings.
            // On iOS 26+, UIGlassEffect is expected to be available.
            
            // For now, we'll try to use a generic initialization and set properties via KVC 
            // OR use a selector if we know the signature.
            let glassEffect = glassEffectClass.init()
            
            // Safer property setting: Check if object responds to the setter or has the property
            if glassEffect.responds(to: NSSelectorFromString("setGlass:")) {
                glassEffect.setValue(0, forKey: "glass") // Assuming .regular is 0
            }
            
            if glassEffect.responds(to: NSSelectorFromString("setIsInteractive:")) {
                glassEffect.setValue(true, forKey: "isInteractive")
            }
            
            if let effect = glassEffect as? UIVisualEffect {
                blurView.effect = effect
                os_log(.info, log: logger, "Created native iOS 26 UIGlassEffect view dynamically")
                return blurView
            }
        }
        
        os_log(.error, log: logger, "Failed to create UIGlassEffect dynamically, falling back to standard blur")
        return createStandardBlurView()
    }

    /// Creates the standard fallback blur for older iOS versions
    private static func createStandardBlurView() -> UIView {
        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        
        os_log(.debug, log: logger, "Created standard systemThinMaterial blur view (fallback)")
        return blurView
    }

    /// Configures modern corner geometry for floating elements (iOS 26+)
    ///
    /// - Parameters:
    ///   - view: The view to configure
    ///   - radius: The base corner radius
    static func configureModernGeometry(for view: UIView, radius: CGFloat) {
        view.layer.cornerRadius = radius
        view.clipsToBounds = true
        
        // Use dynamic checking for .containerConcentric
        if #available(iOS 26.0, *) {
            // CALayerCornerCurve is an enum/string. .containerConcentric is projected as a string.
            if view.layer.responds(to: NSSelectorFromString("setCornerCurve:")) {
                view.layer.setValue("containerConcentric", forKey: "cornerCurve")
            } else {
                view.layer.cornerCurve = .continuous
            }
        } else {
            view.layer.cornerCurve = .continuous
        }
    }
}

/// A specialized view that automatically applies the correct glass effect and geometry.
@available(iOS 15.0, *)
class AdaptiveGlassView: UIView {
    private var effectView: UIView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        
        let glass = AdaptiveGlassHelper.createGlassView()
        glass.translatesAutoresizingMaskIntoConstraints = false
        addSubview(glass)
        
        NSLayoutConstraint.activate([
            glass.leadingAnchor.constraint(equalTo: leadingAnchor),
            glass.trailingAnchor.constraint(equalTo: trailingAnchor),
            glass.topAnchor.constraint(equalTo: topAnchor),
            glass.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        self.effectView = glass
        
        // Apply modern geometry by default
        AdaptiveGlassHelper.configureModernGeometry(for: self, radius: 16.0)
    }
}
