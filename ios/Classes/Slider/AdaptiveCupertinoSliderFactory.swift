import Flutter
import UIKit
import os.log

/// Factory for creating iOS 26 native slider platform views
@available(iOS 15.0, *)
class AdaptiveCupertinoSliderFactory: NSObject, FlutterPlatformViewFactory {
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
        return AdaptiveCupertinoSliderView(
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

/// Native iOS 26 UISlider platform view
@available(iOS 15.0, *)
class AdaptiveCupertinoSliderView: NSObject, FlutterPlatformView {
    private static let logger = OSLog(subsystem: "com.alper.adaptive_cupertino", category: "Slider")
    
    private var _containerView: UIView
    private var nativeSlider: UISlider!
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
            name: "adaptive_platform_ui/slider_\(viewId)",
            binaryMessenger: messenger
        )

        super.init()

        setupSlider(args)
        
        channel.setMethodCallHandler { [weak self] (call, result) in
            self?.handleMethodCall(call, result: result)
        }
    }

    func view() -> UIView {
        return _containerView
    }

    private func setupSlider(_ args: Any?) {
        nativeSlider = UISlider()
        nativeSlider.translatesAutoresizingMaskIntoConstraints = false
        
        guard let params = args as? [String: Any] else {
            os_log(.error, log: Self.logger, "Invalid arguments for Slider")
            return
        }

        // 1. Initial Values
        if let value = params["value"] as? Double {
            nativeSlider.value = Float(value)
        }
        if let min = params["min"] as? Double {
            nativeSlider.minimumValue = Float(min)
        }
        if let max = params["max"] as? Double {
            nativeSlider.maximumValue = Float(max)
        }

        // 2. Apply Colors
        if let activeValue = params["activeColor"] as? Int {
            nativeSlider.minimumTrackTintColor = UIColor(argb: activeValue)
        }

        if let thumbValue = params["thumbColor"] as? Int {
            nativeSlider.thumbTintColor = UIColor(argb: thumbValue)
        }

        // 3. Enabled State
        nativeSlider.isEnabled = (params["enabled"] as? Bool) ?? true

        // 4. Add Main Slider to View BEFORE Glass Effect
        _containerView.addSubview(nativeSlider)

        // 5. iOS 26 "Liquid Glass" specific enhancements
        if #available(iOS 26.0, *) {
             // TRUE iOS 26: Native adoption, no manual injection needed
        } else if IOSVersionDetector.isIOS26OrNewer() {
             // Experimental Mode (iOS 18-25): Simulate the 26 look
             applyGlassDesign()
        }
        
        NSLayoutConstraint.activate([
            nativeSlider.leadingAnchor.constraint(equalTo: _containerView.leadingAnchor, constant: 4),
            nativeSlider.trailingAnchor.constraint(equalTo: _containerView.trailingAnchor, constant: -4),
            nativeSlider.centerYAnchor.constraint(equalTo: _containerView.centerYAnchor)
        ])

        nativeSlider.addTarget(self, action: #selector(valueChanged), for: .valueChanged)
        nativeSlider.addTarget(self, action: #selector(touchDown), for: .touchDown)
        nativeSlider.addTarget(self, action: #selector(touchUp), for: [.touchUpInside, .touchUpOutside])
        
        os_log(.info, log: Self.logger, "Slider initialized with Liquid Glass (ID: %{public}lld)", viewId)
    }

    private func applyGlassDesign() {
        // In iOS 26 "Liquid Glass", sliders have a thicker, blurred track
        nativeSlider.maximumTrackTintColor = .clear // Hide standard track
        
        // Use the high-fidelity AdaptiveGlassView for the track
        let glassView = AdaptiveGlassView(frame: .zero, isInteractive: false, variant: 0, applyGeometry: true)
        glassView.translatesAutoresizingMaskIntoConstraints = false
        
        _containerView.insertSubview(glassView, belowSubview: nativeSlider)
        
        NSLayoutConstraint.activate([
            glassView.leadingAnchor.constraint(equalTo: nativeSlider.leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: nativeSlider.trailingAnchor),
            glassView.centerYAnchor.constraint(equalTo: nativeSlider.centerYAnchor),
            glassView.heightAnchor.constraint(equalToConstant: 8)
        ])
        
        // Custom geometry adjustment for the thin track
        AdaptiveGlassHelper.configureModernGeometry(for: glassView, radius: 4)
        
        // Custom thumb if supported in iOS 26 (simulated via shadow/glow)
        // REMOVED: Applying shadow to the whole slider layer creates a box shadow artifact.
        // nativeSlider.layer.shadowColor = UIColor.black.cgColor
        // nativeSlider.layer.shadowOpacity = 0.2
        // nativeSlider.layer.shadowOffset = CGSize(width: 0, height: 2)
        // nativeSlider.layer.shadowRadius = 4
    }

    @objc private func valueChanged() {
        let value = nativeSlider.value
        channel.invokeMethod("valueChanged", arguments: ["value": value])
    }
    
    @objc private func touchDown() {
        let value = nativeSlider.value
        channel.invokeMethod("onChangeStart", arguments: ["value": value])
    }
    
    @objc private func touchUp() {
        let value = nativeSlider.value
        channel.invokeMethod("onChangeEnd", arguments: ["value": value])
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
         result(FlutterMethodNotImplemented)
    }
}
