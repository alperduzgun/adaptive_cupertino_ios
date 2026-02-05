import Flutter
import UIKit
import os.log

/// Platform View Factory for Adaptive Cupertino Tooltip
@available(iOS 15.0, *)
class AdaptiveCupertinoTooltipFactory: NSObject, FlutterPlatformViewFactory {
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
        return AdaptiveCupertinoTooltipPlatformView(
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

/// Platform View wrapper for native tooltips/balloons
@available(iOS 15.0, *)
class AdaptiveCupertinoTooltipPlatformView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private let messenger: FlutterBinaryMessenger
    private let channel: FlutterMethodChannel
    private static let logger = OSLog(subsystem: "com.adaptive_cupertino_ios", category: "TooltipFactory")

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        self.messenger = messenger
        self._view = UIView(frame: frame)
        self._view.backgroundColor = .clear
        self._view.isOpaque = false
        self.channel = FlutterMethodChannel(
            name: "adaptive_cupertino_ios/tooltip_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()

        setupTooltip(arguments: args)
    }

    func view() -> UIView {
        return _view
    }

    private func setupTooltip(arguments args: Any?) {
        guard let params = args as? [String: Any] else { return }
        
        // The native tooltip host view just provides the interaction and background
        // The message is passed from Flutter
        let message = params["message"] as? String ?? ""
        let useGlass = params["useGlass"] as? Bool ?? true
        
        if useGlass {
            let glass = AdaptiveGlassView(frame: .zero, isInteractive: true, variant: 0, applyGeometry: true)
            glass.translatesAutoresizingMaskIntoConstraints = false
            _view.addSubview(glass)
            
            NSLayoutConstraint.activate([
                glass.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                glass.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                glass.topAnchor.constraint(equalTo: _view.topAnchor),
                glass.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
            ])
            
            AdaptiveGlassHelper.configureModernGeometry(for: _view, radius: 10.0)
        }
        
        let label = UILabel()
        label.text = message
        label.textColor = .label
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        _view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: _view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: _view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: _view.leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: _view.trailingAnchor, constant: -8)
        ])
        
        os_log(.info, log: Self.logger, "Native Tooltip initialized: %{public}@", message)
    }
}
