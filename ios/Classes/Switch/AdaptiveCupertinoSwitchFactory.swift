import Flutter
import UIKit
import os.log

/// Factory for creating iOS 26 native switch platform views
@available(iOS 15.0, *)
class AdaptiveCupertinoSwitchFactory: NSObject, FlutterPlatformViewFactory {
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
        return AdaptiveCupertinoSwitchView(
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

/// Native iOS 26 UISwitch platform view
@available(iOS 15.0, *)
class AdaptiveCupertinoSwitchView: NSObject, FlutterPlatformView {
    private static let logger = OSLog(subsystem: "com.alper.adaptive_cupertino", category: "Switch")
    
    private var _containerView: UIView
    private var nativeSwitch: UISwitch!
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
        _containerView.backgroundColor = .clear
        _containerView.isOpaque = false
        channel = FlutterMethodChannel(
            name: "adaptive_platform_ui/switch_\(viewId)",
            binaryMessenger: messenger
        )

        super.init()

        setupSwitch(args)
        
        channel.setMethodCallHandler { [weak self] (call, result) in
            self?.handleMethodCall(call, result: result)
        }
    }

    func view() -> UIView {
        return _containerView
    }

    private func setupSwitch(_ args: Any?) {
        nativeSwitch = UISwitch()
        nativeSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        guard let params = args as? [String: Any] else {
            os_log(.error, log: Self.logger, "Invalid arguments for Switch")
            return
        }

        // 1. Initial State
        if let isOn = params["isOn"] as? Bool {
            nativeSwitch.isOn = isOn
        }

        // 2. Apply Colors
        if let activeValue = params["activeColor"] as? Int {
            nativeSwitch.onTintColor = UIColor(argb: activeValue)
        }

        if let thumbValue = params["thumbColor"] as? Int {
            nativeSwitch.thumbTintColor = UIColor(argb: thumbValue)
        }

        // 3. Enabled State
        nativeSwitch.isEnabled = (params["enabled"] as? Bool) ?? true
        
        // 4. Add to hierarchy FIRST (Critical for constraints in applyGlassDesign)
        _containerView.addSubview(nativeSwitch)
        
        // Center the switch in the container
        NSLayoutConstraint.activate([
            nativeSwitch.centerXAnchor.constraint(equalTo: _containerView.centerXAnchor),
            nativeSwitch.centerYAnchor.constraint(equalTo: _containerView.centerYAnchor)
        ])

        // 5. iOS 26 "Liquid Glass" specific enhancements
        // Now safe to call, as nativeSwitch is in the hierarchy
        if #available(iOS 26.0, *) {
             // TRUE iOS 26: Native adoption, no manual injection needed
        } else if IOSVersionDetector.isIOS26OrNewer() {
             // Experimental Mode (iOS 18-25): Simulate the 26 look
             applyGlassDesign()
        }

        nativeSwitch.addTarget(self, action: #selector(valueChanged), for: .valueChanged)

        nativeSwitch.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
        
        os_log(.info, log: Self.logger, "Switch initialized with Liquid Glass (ID: %{public}lld)", viewId)
    }

    private func applyGlassDesign() {
        // In iOS 26 "Liquid Glass", switches have a subtle backdrop blur when off
        // Use high-fidelity AdaptiveGlassView
        let glassView = AdaptiveGlassView(frame: .zero, isInteractive: false, variant: 0, applyGeometry: true)
        glassView.translatesAutoresizingMaskIntoConstraints = false
        
        _containerView.insertSubview(glassView, belowSubview: nativeSwitch)
        
        NSLayoutConstraint.activate([
            glassView.centerXAnchor.constraint(equalTo: nativeSwitch.centerXAnchor),
            glassView.centerYAnchor.constraint(equalTo: nativeSwitch.centerYAnchor),
            glassView.widthAnchor.constraint(equalTo: nativeSwitch.widthAnchor),
            glassView.heightAnchor.constraint(equalTo: nativeSwitch.heightAnchor)
        ])
        
        // Match the switch's pill shape exactly
        AdaptiveGlassHelper.configureModernGeometry(for: glassView, radius: 16)
    }

    @objc private func valueChanged() {
        let value = nativeSwitch.isOn
        channel.invokeMethod("valueChanged", arguments: ["value": value])
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setValue":
            if let args = call.arguments as? [String: Any],
               let value = args["value"] as? Bool {
                nativeSwitch.setOn(value, animated: true)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing value", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
