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
            // iOS < 26 Standard Fallback (Enhanced with Variant Logic)
            return createStandardBlurView(variant: variant)
        }
    }

    /// Creates the native iOS 26 Liquid Glass view using UIGlassEffect
    /// - Parameters:
    ///   - isInteractive: Whether the effect responds to touch
    ///   - variant: 0: regular, 1: clear, 2: identity (matching iOS 26 variants)
    private static func createModernGlassView(isInteractive: Bool, variant: Int = 0) -> UIView {
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
                glassContainer.isOpaque = false // OPTIMIZATION: Tell engine we are transparent
                glassContainer.translatesAutoresizingMaskIntoConstraints = false
                
                // IMPORTANT: If not interactive, disable ALL interaction on subviews
                // to prevent them from catching touches intended for underlying controls.
                glassContainer.isUserInteractionEnabled = isInteractive
                
                let blurView = UIVisualEffectView(effect: effect)
                blurView.translatesAutoresizingMaskIntoConstraints = false
                blurView.isUserInteractionEnabled = isInteractive
                blurView.layer.allowsGroupOpacity = false
                glassContainer.addSubview(blurView)
                
                NSLayoutConstraint.activate([
                    blurView.leadingAnchor.constraint(equalTo: glassContainer.leadingAnchor),
                    blurView.trailingAnchor.constraint(equalTo: glassContainer.trailingAnchor),
                    blurView.topAnchor.constraint(equalTo: glassContainer.topAnchor),
                    blurView.bottomAnchor.constraint(equalTo: glassContainer.bottomAnchor)
                ])
                
                // TRUE iOS 26: No manual tints or rims. Let the system handle it.
                os_log(.info, log: logger, "Successfully applied Native Liquid Glass (Variant: \(variant))")
                return glassContainer
            }
        }
        
        os_log(.error, log: logger, "Failed to create UIGlassEffect dynamically, falling back to enhanced simulation (Variant: \(variant))")
        return createStandardBlurView(variant: variant)
    }

    /// Creates an enhanced fallback blur for older iOS versions
    private static func createStandardBlurView(variant: Int = 0) -> UIView {
        let style: UIBlurEffect.Style
        let tintAlpha: CGFloat
        let borderAlpha: CGFloat
        
        switch variant {
        case 1: // Clear
            style = .systemThinMaterial
            tintAlpha = 0.0
            borderAlpha = 0.05
        case 2: // Identity (Lensing Simulation)
            style = .systemUltraThinMaterial
            tintAlpha = 0.05
            borderAlpha = 0.15
        default: // Regular
            style = .systemMaterial
            tintAlpha = 0.02
            borderAlpha = 0.1
        }
        
        let blurEffect = UIBlurEffect(style: style)
        let blurView = UIVisualEffectView(effect: blurEffect)
        
        // REMOVED: User feedback indicated this border looks like a "gray frame" artifact.
        // blurView.layer.borderWidth = 0.5
        // blurView.layer.borderColor = UIColor.white.withAlphaComponent(borderAlpha).cgColor

        if tintAlpha > 0 {
            let tint = UIView()
            tint.backgroundColor = UIColor.white.withAlphaComponent(tintAlpha)
            tint.translatesAutoresizingMaskIntoConstraints = false
            blurView.contentView.addSubview(tint)
            NSLayoutConstraint.activate([
                tint.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
                tint.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
                tint.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
                tint.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor)
            ])
        }
        
        // ADDITION: Vibrancy for "Liquid" feel
        if variant != 1 {
            let vibrancyEffect = UIVibrancyEffect(blurEffect: blurEffect, style: .label)
            let vibrancyView = UIVisualEffectView(effect: vibrancyEffect)
            vibrancyView.translatesAutoresizingMaskIntoConstraints = false
            blurView.contentView.addSubview(vibrancyView)
            
            NSLayoutConstraint.activate([
                vibrancyView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
                vibrancyView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
                vibrancyView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
                vibrancyView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor)
            ])
        }
        
        // EXPERIMENTAL: Perspective depth for Identity glass
        if variant == 2 {
            blurView.layer.zPosition = 10
            // Increased scale for more obvious lensing simulation
            blurView.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
        }
        
        return blurView
    }

    /// Configures modern corner geometry for floating elements (iOS 26+)
    ///
    /// - Parameters:
    ///   - view: The view to configure
    ///   - radius: The base corner radius
    static func configureModernGeometry(for view: UIView, radius: CGFloat) {
        // CHAOS SAFETY: Prevent NaN or Infinite radius from crashing QuartzCore
        let safeRadius = radius.isNaN || radius.isInfinite ? 0 : max(0, radius)
        
        view.layer.cornerRadius = safeRadius
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
