import Flutter
import UIKit
import os.log

/// Platform View Factory for Adaptive Cupertino FloatingActionButton
@available(iOS 15.0, *)
class AdaptiveCupertinoFloatingActionButtonFactory: NSObject, FlutterPlatformViewFactory {
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
        return AdaptiveCupertinoFloatingActionButtonPlatformView(
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

/// Platform View wrapper for native high-fidelity glass FABs
@available(iOS 15.0, *)
class AdaptiveCupertinoFloatingActionButtonPlatformView: NSObject, FlutterPlatformView {
    private var _view: FABContainerView
    private let button: UIButton
    private let messenger: FlutterBinaryMessenger
    private let channel: FlutterMethodChannel
    private static let logger = OSLog(subsystem: "com.adaptive_cupertino_ios", category: "FABFactory")
    
    // Keep reference to glass for layout updates
    private weak var glassView: UIView?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        self.messenger = messenger
        self._view = FABContainerView(frame: frame)
        self._view.backgroundColor = .clear
        self._view.isOpaque = false
        self.button = UIButton(type: .system)
        self.channel = FlutterMethodChannel(
            name: "adaptive_cupertino_ios/fab_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()

        setupFAB(arguments: args)
    }

    func view() -> UIView {
        return _view
    }

    private func setupFAB(arguments args: Any?) {
        guard let params = args as? [String: Any] else { return }
        
        let iconName = params["icon"] as? String ?? "plus"
        let useGlass = params["useGlass"] as? Bool ?? true
        
        button.setImage(UIImage(systemName: iconName, withConfiguration: UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)), for: .normal)
        button.tintColor = .label
        button.translatesAutoresizingMaskIntoConstraints = false
        _view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: _view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: _view.centerYAnchor),
            button.widthAnchor.constraint(equalTo: _view.widthAnchor),
            button.heightAnchor.constraint(equalTo: _view.heightAnchor)
        ])
        
        if useGlass {
            // Initialize Glass WITHOUT internal geometry (we handle it in FABContainerView)
            let glass = AdaptiveGlassView(frame: .zero, isInteractive: true, variant: 0, applyGeometry: false)
            glass.translatesAutoresizingMaskIntoConstraints = false
            glass.isUserInteractionEnabled = false // Let touches pass to button
            
            _view.insertSubview(glass, at: 0)
            self.glassView = glass // Save reference
            
            NSLayoutConstraint.activate([
                glass.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                glass.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                glass.topAnchor.constraint(equalTo: _view.topAnchor),
                glass.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
            ])
            
            // Register glass view with container for layout updates
            _view.glassContent = glass
        }
        
        button.addTarget(self, action: #selector(onPressed), for: .touchUpInside)
        
        // Shadow configuration (Geometry handled in layoutSubviews)
        _view.layer.shadowColor = UIColor.black.cgColor
        _view.layer.shadowOffset = CGSize(width: 0, height: 4)
        _view.layer.shadowRadius = 8
        _view.layer.shadowOpacity = 0.2
        
        os_log(.info, log: Self.logger, "Native FAB initialized.")
    }

    @objc private func onPressed() {
        // Haptic feedback for premium feel
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
        
        channel.invokeMethod("onPressed", arguments: nil)
    }
}

/// Custom container to handle circular layout and shadows
class FABContainerView: UIView {
    weak var glassContent: UIView?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let radius = bounds.height / 2
        
        // 1. Update Shadow Path (to prevent square shadow)
        layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: radius).cgPath
        
        // 2. Update Glass Geometry explicitly
        if let glass = glassContent {
            glass.layer.cornerRadius = radius
            glass.clipsToBounds = true
            
            // Ensure modern corner curve for smoothness
            if #available(iOS 13.0, *) {
                glass.layer.cornerCurve = .circular // FABs are usually perfect circles
            }
        }
    }
}
