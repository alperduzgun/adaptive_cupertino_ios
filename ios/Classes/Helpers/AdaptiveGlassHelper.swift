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
    /// - Parameter isInteractive: Whether the effect should respond to real-time interaction (iOS 26+)
    /// - Returns: A `UIView` (either a `UIVisualEffectView` or a specialized glass view)
    static func createGlassView(isInteractive: Bool = true) -> UIView {
        if IOSVersionDetector.supportsLiquidGlassSheets() {
            // iOS 26+ Native Liquid Glass
            return createModernGlassView(isInteractive: isInteractive)
        } else {
            // iOS < 26 Standard Fallback
            return createStandardBlurView()
        }
    }

    /// Creates the native iOS 26 Liquid Glass view using UIGlassEffect
    private static func createModernGlassView(isInteractive: Bool) -> UIView {
        // Container to hold both the effect and a subtle tint
        let container = UIView()
        container.backgroundColor = .clear
        
        let blurView = UIVisualEffectView()
        blurView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(blurView)
        
        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            blurView.topAnchor.constraint(equalTo: container.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        if #available(iOS 26.0, *),
           let glassEffectClass = NSClassFromString("UIGlassEffect") as? NSObject.Type {
            
            let glassEffect = glassEffectClass.init()
            
            if glassEffect.responds(to: NSSelectorFromString("setGlass:")) {
                glassEffect.setValue(0, forKey: "glass") // 0 = .regular
            }
            
            if glassEffect.responds(to: NSSelectorFromString("setIsInteractive:")) {
                glassEffect.setValue(isInteractive, forKey: "isInteractive")
            }
            
            if let effect = glassEffect as? UIVisualEffect {
                blurView.effect = effect
                blurView.layer.allowsGroupOpacity = false
                
                // ADDITION: Subtle "Milky" milky tint for Liquid Glass definition
                // This makes the glass visible on pure white or system gray backgrounds.
                let tint = UIView()
                tint.backgroundColor = UIColor.white.withAlphaComponent(0.08)
                tint.translatesAutoresizingMaskIntoConstraints = false
                container.addSubview(tint)
                
                NSLayoutConstraint.activate([
                    tint.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                    tint.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                    tint.topAnchor.constraint(equalTo: container.topAnchor),
                    tint.bottomAnchor.constraint(equalTo: container.bottomAnchor)
                ])
                
                os_log(.info, log: logger, "Successfully applied Native Liquid Glass effect with Milky Tint")
                return container
            }
        }
        
        os_log(.error, log: logger, "Failed to create UIGlassEffect dynamically, falling back to standard thin material")
        return createStandardBlurView()
    }

    /// Creates the standard fallback blur for older iOS versions
    /// Creates the standard fallback blur for older iOS versions
    private static func createStandardBlurView() -> UIView {
        // Upgrade: Use UltraThin material for that "floating" Liquid look
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        
        // Simulating the "Immersive Border" of iOS 26
        // We add a subtle white glow/border to the view containing this highlight
        blurView.layer.borderWidth = 0.5
        blurView.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        
        os_log(.debug, log: logger, "Created simulated Liquid Glass (UltraThin + Border)")
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
    private var isInteractive: Bool = true
    private var applyGeometry: Bool = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    /// Convenience initializer for optimized performance
    convenience init(frame: CGRect, isInteractive: Bool, applyGeometry: Bool = true) {
        self.init(frame: frame)
        self.isInteractive = isInteractive
        self.applyGeometry = applyGeometry
        // Re-setup if needed or just use properties in setup()
        refresh()
    }

    private func setup() {
        backgroundColor = .clear
        refresh()
    }

    private func refresh() {
        // Cleaning up old view if needed (mostly for convenience init usage)
        effectView?.removeFromSuperview()
        
        let glass = AdaptiveGlassHelper.createGlassView(isInteractive: isInteractive)
        glass.translatesAutoresizingMaskIntoConstraints = false
        addSubview(glass)
        
        NSLayoutConstraint.activate([
            glass.leadingAnchor.constraint(equalTo: leadingAnchor),
            glass.trailingAnchor.constraint(equalTo: trailingAnchor),
            glass.topAnchor.constraint(equalTo: topAnchor),
            glass.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        self.effectView = glass
        
        if applyGeometry {
            AdaptiveGlassHelper.configureModernGeometry(for: self, radius: 16.0)
        } else {
            // Ensure no clipping overhead
            self.layer.cornerRadius = 0
            self.clipsToBounds = false
        }
    }
}
