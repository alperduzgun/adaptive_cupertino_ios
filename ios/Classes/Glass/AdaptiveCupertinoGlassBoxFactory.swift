import Flutter
import UIKit

/// Factory for native liquid glass containers.
@available(iOS 15.0, *)
class AdaptiveCupertinoGlassBoxFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        print("🏭 GlassBoxFactory: Creating view with ID: \(viewId)")
        NSLog("🏭 GlassBoxFactory: Creating view with ID: \(viewId)")
        return AdaptiveCupertinoGlassBoxView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

@available(iOS 15.0, *)
class AdaptiveCupertinoGlassBoxView: NSObject, FlutterPlatformView {
    private let _view: UIView
    private var glassView: AdaptiveGlassView?
    private var shouldAnimateEntry: Bool = false
    private var hasAnimatedEntry: Bool = false

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _view = AdaptiveGlassBoxContainerView(frame: frame) // Use custom view to hook lifecycle
        _view.backgroundColor = .clear
        super.init()

        setupView(arguments: args)
    }

    func view() -> UIView {
        return _view
    }

    private func setupView(arguments args: Any?) {
        guard let params = args as? [String: Any] else {
            NSLog("🔴 GlassBox: Invalid arguments")
            return
        }

        let variant = params["variant"] as? Int ?? 0
        let radius = params["borderRadius"] as? CGFloat ?? 20.0
        let glassEffectID = params["glassEffectID"] as? String
        
        NSLog("🔍 GlassBox: Setup View. ID: \(String(describing: glassEffectID))")
        
        // Use the centralized helper for high-fidelity glass
        let glass = AdaptiveGlassView(frame: .zero, isInteractive: false, variant: variant, applyGeometry: true)
        glass.translatesAutoresizingMaskIntoConstraints = false
        _view.addSubview(glass)

        NSLayoutConstraint.activate([
            glass.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            glass.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            glass.topAnchor.constraint(equalTo: _view.topAnchor),
            glass.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
        ])
        
        AdaptiveGlassHelper.configureModernGeometry(for: _view, radius: radius)
        self.glassView = glass

        if glassEffectID != nil {
            NSLog("🟢 GlassBox: Morph Mode Detected. Preparing initial state.")
            self.shouldAnimateEntry = true
            glass.alpha = 0.0
        }
        
        // Inject the animation handler into the container view
        if let container = _view as? AdaptiveGlassBoxContainerView {
            container.onDidMoveToWindow = { [weak self] in
                NSLog("⚡ GlassBox: didMoveToWindow trigger")
                self?.triggerEntryAnimation()
            }
            // Also trigger on layout to be safe
            container.onLayoutSubviews = { [weak self] in
                 if self?.shouldAnimateEntry == true && self?.hasAnimatedEntry == false {
                     NSLog("⚡ GlassBox: layoutSubviews trigger")
                     self?.triggerEntryAnimation()
                 }
            }
        }
    }
    
    private func triggerEntryAnimation() {
        guard shouldAnimateEntry, !hasAnimatedEntry, let glass = glassView else {
            // Log only if we expected to animate but something blocked it
            if shouldAnimateEntry && !hasAnimatedEntry {
                 NSLog("⚠️ GlassBox: Animation NOT triggered (glassView nil?)")
            }
            return
        }
        
        hasAnimatedEntry = true
        NSLog("🚀 GlassBox: STARTING ANIMATION")
        
        // "Liquid" Spring Animation
        // Delay slightly to allow Flutter frame to settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NSLog("✨ GlassBox: Executing UIView.animate")
            glass.transform = CGAffineTransform(scaleX: 0.8, y: 0.8) // Start small
            
            UIView.animate(
                withDuration: 0.8,
                delay: 0.0,
                usingSpringWithDamping: 0.6, // More bounce
                initialSpringVelocity: 0.5,
                options: [.allowUserInteraction, .curveEaseOut, .layoutSubviews],
                animations: {
                    glass.transform = .identity
                    glass.alpha = 1.0
                    NSLog("💫 GlassBox: Animating inside block")
                },
                completion: { completed in
                    NSLog("🏁 GlassBox: Animation completed: \(completed)")
                }
            )
        }
    }
}

/// Helper class to detect lifecycle events
class AdaptiveGlassBoxContainerView: UIView {
    var onDidMoveToWindow: (() -> Void)?
    var onLayoutSubviews: (() -> Void)?
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            NSLog("📦 Container: didMoveToWindow (window attached)")
            onDidMoveToWindow?()
        } else {
            NSLog("📦 Container: didMoveToWindow (window detached)")
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Reduce log noise, only log first few times or if vital
        // NSLog("📦 Container: layoutSubviews")
        onLayoutSubviews?()
    }
}
