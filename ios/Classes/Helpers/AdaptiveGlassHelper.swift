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
    /// - Parameters:
    ///   - isInteractive: Whether the effect should respond to real-time interaction (iOS 26+)
    ///   - variant: The visual variant (0: regular, 1: clear, 2: identity)
    /// - Returns: A `UIView` (either a `UIVisualEffectView` or a specialized glass view)
    static func createGlassView(isInteractive: Bool = true, variant: Int = 0) -> UIView {
        if IOSVersionDetector.supportsLiquidGlassSheets() {
            // iOS 26+ Native Liquid Glass
            return createModernGlassView(isInteractive: isInteractive, variant: variant)
        } else {
            // iOS < 26 Standard Fallback
            return createStandardBlurView()
        }
    }

    /// Creates the native iOS 26 Liquid Glass view using UIGlassEffect
    /// - Parameters:
    ///   - isInteractive: Whether the effect responds to touch
    ///   - variant: 0: regular, 1: clear, 2: identity (matching iOS 26 variants)
    private static func createModernGlassView(isInteractive: Bool, variant: Int = 0) -> UIView {
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
            
            // Set Variant (.regular, .clear, .identity)
            if glassEffect.responds(to: NSSelectorFromString("setGlass:")) {
                glassEffect.setValue(variant, forKey: "glass")
            }
            
            // Set Interactivity
            if glassEffect.responds(to: NSSelectorFromString("setIsInteractive:")) {
                glassEffect.setValue(isInteractive, forKey: "isInteractive")
            }
            
            // LENSING (Real-time light bending)
            if glassEffect.responds(to: NSSelectorFromString("setRefraction:")) {
                glassEffect.setValue(2.5, forKey: "refraction")
            }
            
            if let effect = glassEffect as? UIVisualEffect {
                // Use GlassContainerView as the root container to handle masking
                let glassContainer = GlassContainerView()
                glassContainer.isInteractive = isInteractive
                glassContainer.backgroundColor = .clear
                glassContainer.translatesAutoresizingMaskIntoConstraints = false
                
                // IMPORTANT: If not interactive, disable ALL interaction on subviews
                // to prevent them from catching touches intended for underlying controls.
                glassContainer.isUserInteractionEnabled = isInteractive
                
                blurView.effect = effect
                blurView.isUserInteractionEnabled = isInteractive
                blurView.layer.allowsGroupOpacity = false
                glassContainer.addSubview(blurView)
                
                NSLayoutConstraint.activate([
                    blurView.leadingAnchor.constraint(equalTo: glassContainer.leadingAnchor),
                    blurView.trailingAnchor.constraint(equalTo: glassContainer.trailingAnchor),
                    blurView.topAnchor.constraint(equalTo: glassContainer.topAnchor),
                    blurView.bottomAnchor.constraint(equalTo: glassContainer.bottomAnchor)
                ])
                
                // 1. ADDITION: Subtle "Milky" tint
                if variant != 1 {
                    let tint = UIView()
                    tint.isUserInteractionEnabled = false // Decorative
                    tint.backgroundColor = UIColor.white.withAlphaComponent(0.04)
                    tint.translatesAutoresizingMaskIntoConstraints = false
                    glassContainer.addSubview(tint)
                    
                    NSLayoutConstraint.activate([
                        tint.leadingAnchor.constraint(equalTo: glassContainer.leadingAnchor),
                        tint.trailingAnchor.constraint(equalTo: glassContainer.trailingAnchor),
                        tint.topAnchor.constraint(equalTo: glassContainer.topAnchor),
                        tint.bottomAnchor.constraint(equalTo: glassContainer.bottomAnchor)
                    ])
                }
                
                // 2. SURFACE HIGHLIGHT: 0.5pt white rim for depth definition
                let rim = UIView()
                rim.isUserInteractionEnabled = false // Decorative
                rim.backgroundColor = .clear
                rim.layer.borderWidth = 0.5
                rim.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
                rim.translatesAutoresizingMaskIntoConstraints = false
                glassContainer.addSubview(rim)
                
                NSLayoutConstraint.activate([
                    rim.leadingAnchor.constraint(equalTo: glassContainer.leadingAnchor),
                    rim.trailingAnchor.constraint(equalTo: glassContainer.trailingAnchor),
                    rim.topAnchor.constraint(equalTo: glassContainer.topAnchor),
                    rim.bottomAnchor.constraint(equalTo: glassContainer.bottomAnchor)
                ])
                
                // 3. FEATHERED MASK (Scroll Edge Effect)
                let maskLayer = CAGradientLayer()
                maskLayer.colors = [
                    UIColor.black.withAlphaComponent(0.0).cgColor,
                    UIColor.black.cgColor,
                    UIColor.black.cgColor,
                    UIColor.black.withAlphaComponent(0.0).cgColor
                ]
                maskLayer.locations = [0.0, 0.05, 0.95, 1.0]
                glassContainer.layer.mask = maskLayer
                glassContainer.maskLayer = maskLayer
                
                os_log(.info, log: logger, "Successfully applied Native Liquid Glass (Variant: \(variant)) with Rim & Tints")
                return glassContainer
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
    private var variant: Int = 0 // 0: regular, 1: clear, 2: identity
    private var applyGeometry: Bool = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        // Default to no interaction to prevent blocking native controls
        self.isUserInteractionEnabled = false
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    /// Convenience initializer for optimized performance
    convenience init(frame: CGRect, isInteractive: Bool, variant: Int = 0, applyGeometry: Bool = true) {
        self.init(frame: frame)
        self.isInteractive = isInteractive
        self.isUserInteractionEnabled = isInteractive // Only enable if specifically requested
        self.variant = variant
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
        
        self.isUserInteractionEnabled = isInteractive // SYNC STATE
        
        let glass = AdaptiveGlassHelper.createGlassView(isInteractive: isInteractive, variant: variant)
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

/// A specialized container that handles gradient masking and layout for feathered edges.
class GlassContainerView: UIView {
    var maskLayer: CAGradientLayer?
    var isInteractive: Bool = false

    override func layoutSubviews() {
        super.layoutSubviews()
        maskLayer?.frame = bounds
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // If not interactive, we want this entire view AND IT'S SUBVIEWS to be invisible to hits.
        if !isInteractive {
            return nil
        }
        return super.hitTest(point, with: event)
    }
}
