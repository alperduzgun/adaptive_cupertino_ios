import Flutter
import UIKit
import os.log

/// Factory for creating iOS 26 native segmented control platform views
@available(iOS 15.0, *)
class AdaptiveCupertinoSegmentedControlFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return AdaptiveCupertinoSegmentedControlView(
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

/// Native iOS 26 UISegmentedControl platform view
@available(iOS 15.0, *)
class AdaptiveCupertinoSegmentedControlView: NSObject, FlutterPlatformView {
    private static let logger = OSLog(subsystem: "com.alper.adaptive_cupertino", category: "SegmentedControl")
    
    private var _containerView: UIView
    private var segmentedControl: UISegmentedControl!
    private var channel: FlutterMethodChannel
    private var viewId: Int64

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        self.viewId = viewId
        _containerView = UIView(frame: frame)
        channel = FlutterMethodChannel(
            name: "adaptive_platform_ui/ios26_segmented_control_\(viewId)",
            binaryMessenger: messenger
        )

        super.init()

        setupSegmentedControl(args)
        
        channel.setMethodCallHandler { [weak self] (call, result) in
            self?.handleMethodCall(call, result: result)
        }
    }

    func view() -> UIView {
        return _containerView
    }

    private func setupSegmentedControl(_ args: Any?) {
        segmentedControl = UISegmentedControl()
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        guard let params = args as? [String: Any] else {
            os_log(.error, log: Self.logger, "Invalid arguments for SegmentedControl")
            return
        }

        // 1. Setup Segments (Labels or SF Symbols)
        if let sfSymbols = params["sfSymbols"] as? [String] {
            for (index, symbol) in sfSymbols.enumerated() {
                // FAILSAFE: Use a default icon if systemName fails, but avoid forced unwrap
                let image = UIImage(systemName: symbol) ?? UIImage(systemName: "questionmark.circle") ?? UIImage()
                segmentedControl.insertSegment(with: image, at: index, animated: false)
            }
        } else if let labels = params["labels"] as? [String] {
            for (index, label) in labels.enumerated() {
                segmentedControl.insertSegment(withTitle: label, at: index, animated: false)
            }
        }

        // 2. Set Selected Index
        if let selectedIndex = params["selectedIndex"] as? Int {
            segmentedControl.selectedSegmentIndex = selectedIndex
        }

        // 3. Apply Colors
        if let tintValue = params["tintColor"] as? Int {
            segmentedControl.selectedSegmentTintColor = UIColor(argb: tintValue)
        }

        if let textValue = params["textColor"] as? Int {
            let textColor = UIColor(argb: textValue)
            segmentedControl.setTitleTextAttributes([.foregroundColor: textColor], for: .normal)
        }

        // 4. Enabled State
        segmentedControl.isEnabled = (params["enabled"] as? Bool) ?? true

        // 5. User Interface Style
        if let isDark = params["isDark"] as? Bool {
            segmentedControl.overrideUserInterfaceStyle = isDark ? .dark : .light
        }

        _containerView.addSubview(segmentedControl)
        
        NSLayoutConstraint.activate([
            segmentedControl.leadingAnchor.constraint(equalTo: _containerView.leadingAnchor),
            segmentedControl.trailingAnchor.constraint(equalTo: _containerView.trailingAnchor),
            segmentedControl.topAnchor.constraint(equalTo: _containerView.topAnchor),
            segmentedControl.bottomAnchor.constraint(equalTo: _containerView.bottomAnchor)
        ])

        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        
        os_log(.info, log: Self.logger, "SegmentedControl initialized (ID: %{public}lld, segments: %{public}d)", 
               viewId, segmentedControl.numberOfSegments)
    }

    @objc private func segmentChanged() {
        let index = segmentedControl.selectedSegmentIndex
        channel.invokeMethod("valueChanged", arguments: ["index": index])
        
        // Haptic feedback
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setSelectedIndex":
            if let args = call.arguments as? [String: Any],
               let index = args["index"] as? Int {
                segmentedControl.selectedSegmentIndex = index
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing index", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
