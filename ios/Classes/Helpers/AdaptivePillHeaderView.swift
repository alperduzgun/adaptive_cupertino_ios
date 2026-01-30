import UIKit
import os.log

/// A shared, high-fidelity background view for iOS 26+ "Detached Pill" headers.
/// 
/// This view combines:
/// - Native `UIGlassEffect` (on iOS 26+)
/// - Milky white tint for visibility
/// - Glass edge hairline
/// - Capsule geometry (Detached from screen edges)
@available(iOS 15.0, *)
class AdaptivePillHeaderView: UIView {
    private let blurView: UIVisualEffectView = UIVisualEffectView()
    private let whiteTintView = UIView()
    private let innerGlowView = UIView()
    private let gradientMask = CAGradientLayer()
    
    enum Direction {
        case top
        case bottom
    }
    
    private var direction: Direction = .top
    private var isInteractive: Bool = true
    private var useFadingGradient: Bool = false {
        didSet {
            updateGradientVisibility()
        }
    }

    init(frame: CGRect, direction: Direction = .top, isInteractive: Bool = true, useFadingGradient: Bool = false) {
        self.direction = direction
        self.isInteractive = isInteractive
        self.useFadingGradient = useFadingGradient
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear
        
        // 1. Setup Base Glass/Blur Effect
        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)
        
        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        applyGlassEffect()

        // 2. Add "Milky" Tint for extra definition on light backgrounds
        whiteTintView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        whiteTintView.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.addSubview(whiteTintView)
        
        NSLayoutConstraint.activate([
            whiteTintView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
            whiteTintView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
            whiteTintView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
            whiteTintView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor)
        ])

        // 3. Add Glass Edge (thin hairline) - Inside contentView to follow the mask
        innerGlowView.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        innerGlowView.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.addSubview(innerGlowView)
        
        let glowEdgeConstraint = direction == .top 
            ? innerGlowView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor)
            : innerGlowView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor)
            
        NSLayoutConstraint.activate([
            innerGlowView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
            innerGlowView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
            glowEdgeConstraint,
            innerGlowView.heightAnchor.constraint(equalToConstant: 0.5)
        ])

        // 4. Setup Mask for optional fading
        updateGradientColors()
        gradientMask.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientMask.endPoint = CGPoint(x: 0.5, y: 1.0)
        updateGradientVisibility()
        
        // 5. Apply Rounded Capsule Geometry
        layer.cornerRadius = 24
        layer.cornerCurve = .continuous
        clipsToBounds = false // REQUIRED for the 4px liquid bulge to render
    }

    private func applyGlassEffect() {
        if #available(iOS 26.0, *),
           let glassEffectClass = NSClassFromString("UIGlassEffect") as? NSObject.Type {
            os_log("Found UIGlassEffect class via reflection. Applying native liquid glass.", log: OSLog.default, type: .debug)
            let glassEffect = glassEffectClass.init()
            if glassEffect.responds(to: NSSelectorFromString("setGlass:")) {
                glassEffect.setValue(0, forKey: "glass")
            }
            if glassEffect.responds(to: NSSelectorFromString("setIsInteractive:")) {
                glassEffect.setValue(isInteractive, forKey: "isInteractive")
            }
            if let effect = glassEffect as? UIVisualEffect {
                blurView.effect = effect
                

                
                return
            }
            os_log("Failed to cast UIGlassEffect instance to UIVisualEffect.", log: OSLog.default, type: .error)
        }
        
        // Fallback: Ultra Thin Material
        os_log("Using fallback systemUltraThinMaterial for pill header.", log: OSLog.default, type: .debug)
        blurView.effect = UIBlurEffect(style: .systemUltraThinMaterial)
    }

    private func updateGradientColors() {
        // High-Fidelity "Liquid Morph" Gradient (Quartic Easing)
        // Ensure the gradient covers the extra height needed for the bulge.
        if direction == .bottom {
            gradientMask.colors = [
                UIColor.clear.cgColor,
                UIColor.black.withAlphaComponent(0.1).cgColor,
                UIColor.black.withAlphaComponent(0.4).cgColor,
                UIColor.black.withAlphaComponent(0.8).cgColor,
                UIColor.black.cgColor
            ]
            gradientMask.locations = [0.0, 0.15, 0.25, 0.4, 1.0]
        } else {
            gradientMask.colors = [
                UIColor.black.cgColor,
                UIColor.black.withAlphaComponent(0.8).cgColor,
                UIColor.black.withAlphaComponent(0.4).cgColor,
                UIColor.black.withAlphaComponent(0.1).cgColor,
                UIColor.clear.cgColor
            ]
            gradientMask.locations = [0.0, 0.6, 0.75, 0.85, 1.0]
        }
    }
    
    private func updateGradientVisibility() {
        // High Fidelity: Custom Bezier Path for "Liquid Drop" (Center 4px Bulge)
        let rect = bounds // Use original bounds for path logic
        let bulge: CGFloat = 4.0
        let radius: CGFloat = 24.0
        
        // Create base rounded path
        let path = UIBezierPath(roundedRect: rect, cornerRadius: radius)
        
        if useFadingGradient {
            // Apply the "Liquid Morph" deformation to the bottom edge
            if direction == .top {
                // Bottom bulge (Liquid Drop)
                path.move(to: CGPoint(x: radius, y: rect.height))
                path.addQuadCurve(to: CGPoint(x: rect.width - radius, y: rect.height), 
                                 controlPoint: CGPoint(x: rect.width / 2, y: rect.height + bulge))
            } else {
                // Top bulge (Liquid Rise)
                path.move(to: CGPoint(x: radius, y: 0))
                path.addQuadCurve(to: CGPoint(x: rect.width - radius, y: 0), 
                                 controlPoint: CGPoint(x: rect.width / 2, y: -bulge))
            }
            
            let shapeMask = CAShapeLayer()
            shapeMask.path = path.cgPath
            gradientMask.mask = shapeMask
            
            // Mask the blurView with our morphological shape
            blurView.layer.mask = gradientMask
            
            // Critical: Disable clipping on all layers to allow the bulge to bloom
            blurView.layer.masksToBounds = false
            whiteTintView.layer.masksToBounds = false
        } else {
            blurView.layer.mask = nil
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        let rect = bounds
        let bulge: CGFloat = 4.0
        
        // Expand the glass effect views to accommodate the "Liquid Drop" bulge
        // This ensures the blur and tint are not clipped by their own frames.
        let expandedFrame = CGRect(x: 0, y: -bulge, width: rect.width, height: rect.height + (bulge * 2))
        blurView.frame = expandedFrame
        whiteTintView.frame = expandedFrame
        innerGlowView.frame = expandedFrame
        
        gradientMask.frame = expandedFrame
        updateGradientVisibility()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            let isDark = traitCollection.userInterfaceStyle == .dark
            whiteTintView.backgroundColor = UIColor.white.withAlphaComponent(isDark ? 0.04 : 0.08)
            innerGlowView.backgroundColor = UIColor.white.withAlphaComponent(isDark ? 0.1 : 0.2)
        }
    }
    
    func setDirection(_ direction: Direction) {
        self.direction = direction
        updateGradientColors()
    }
}
