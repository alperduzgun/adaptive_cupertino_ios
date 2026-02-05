import Flutter
import UIKit
import os.log

/// Platform View Factory for Adaptive Cupertino FormSection
@available(iOS 15.0, *)
class AdaptiveCupertinoFormSectionFactory: NSObject, FlutterPlatformViewFactory {
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
        return AdaptiveCupertinoFormSectionPlatformView(
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

/// Platform View wrapper for native Inset Grouped Section containers
@available(iOS 15.0, *)
class AdaptiveCupertinoFormSectionPlatformView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private let messenger: FlutterBinaryMessenger
    private let channel: FlutterMethodChannel
    private static let logger = OSLog(subsystem: "com.adaptive_cupertino_ios", category: "FormSectionFactory")

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
            name: "adaptive_cupertino_ios/form_section_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()

        setupSection(arguments: args)
    }

    func view() -> UIView {
        return _view
    }

    private func setupSection(arguments args: Any?) {
        guard let params = args as? [String: Any] else { return }
        
        let header = params["header"] as? String
        let footer = params["footer"] as? String
        let useGlass = params["useGlass"] as? Bool ?? true
        
        // We act as a background container. The children are provided by Flutter as subviews
        // via standard PlatformView composition or we just provide the background.
        // For deep native, we'll provide the high-fidelity glass background and system metrics.
        
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
            
            AdaptiveGlassHelper.configureModernGeometry(for: _view, radius: 20.0)
        } else {
            _view.backgroundColor = .secondarySystemGroupedBackground
            _view.layer.cornerRadius = 20.0
        }
        
        os_log(.info, log: Self.logger, "Native FormSection background initialized.")
    }
}
