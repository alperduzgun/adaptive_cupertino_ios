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

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        _view = UIView(frame: frame)
        _view.backgroundColor = .clear
        super.init()

        setupView(arguments: args)
    }

    func view() -> UIView {
        return _view
    }

    private func setupView(arguments args: Any?) {
        guard let params = args as? [String: Any] else { return }

        let variant = params["variant"] as? Int ?? 0
        let radius = params["borderRadius"] as? CGFloat ?? 20.0
        
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
    }
}
