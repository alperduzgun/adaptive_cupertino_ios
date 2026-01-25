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

        _containerView.addSubview(nativeSwitch)
        
        // Center the switch in the container
        NSLayoutConstraint.activate([
            nativeSwitch.centerXAnchor.constraint(equalTo: _containerView.centerXAnchor),
            nativeSwitch.centerYAnchor.constraint(equalTo: _containerView.centerYAnchor)
        ])

        nativeSwitch.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
        
        os_log(.info, log: Self.logger, "Switch initialized (ID: %{public}lld)", viewId)
    }

    @objc private func valueChanged() {
        let value = nativeSwitch.isOn
        channel.invokeMethod("valueChanged", arguments: ["value": value])
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Handle potential messages from Flutter if we add dynamic invalidation later
        result(FlutterMethodNotImplemented)
    }
}
