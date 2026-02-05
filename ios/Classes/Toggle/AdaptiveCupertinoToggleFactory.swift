import Flutter
import UIKit
import os.log

/// Platform View Factory for Adaptive Cupertino Toggle (Checkbox/Radio)
@available(iOS 15.0, *)
class AdaptiveCupertinoToggleFactory: NSObject, FlutterPlatformViewFactory {
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
        return AdaptiveCupertinoTogglePlatformView(
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

/// Platform View wrapper for Checkbox/Radio using UIButton
@available(iOS 15.0, *)
class AdaptiveCupertinoTogglePlatformView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var button: UIButton!
    private let messenger: FlutterBinaryMessenger
    private let channel: FlutterMethodChannel
    private static let logger = OSLog(subsystem: "com.adaptive_cupertino_ios", category: "ToggleFactory")
    
    private var isChecked: Bool = false
    private var isRadio: Bool = false

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
            name: "adaptive_cupertino_ios/toggle_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()

        setupToggle(arguments: args)
        setupMethodChannel()
    }

    func view() -> UIView {
        return _view
    }

    private func setupToggle(arguments args: Any?) {
        guard let params = args as? [String: Any] else { return }

        isChecked = params["value"] as? Bool ?? false
        isRadio = params["isRadio"] as? Bool ?? false
        let useGlass = params["useGlass"] as? Bool ?? false

        var config: UIButton.Configuration = .plain()
        
        if #available(iOS 26.0, *) {
             if useGlass {
                 config = .glass()
             }
        } else if useGlass {
            let glass = AdaptiveGlassView(frame: .zero, isInteractive: true, variant: 0, applyGeometry: true)
            glass.translatesAutoresizingMaskIntoConstraints = false
            _view.addSubview(glass)
            NSLayoutConstraint.activate([
                glass.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                glass.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                glass.topAnchor.constraint(equalTo: _view.topAnchor),
                glass.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
            ])
        }

        config.imagePadding = 0
        config.contentInsets = .zero

        button = UIButton(configuration: config)
        button.translatesAutoresizingMaskIntoConstraints = false
        _view.addSubview(button)

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: _view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: _view.centerYAnchor),
            button.widthAnchor.constraint(equalTo: _view.widthAnchor),
            button.heightAnchor.constraint(equalTo: _view.heightAnchor)
        ])

        updateImage()
        button.addTarget(self, action: #selector(toggleTapped), for: .touchUpInside)
    }

    private func updateImage() {
        let imageName: String
        if isRadio {
            imageName = isChecked ? "largecircle.fill.circle" : "circle"
        } else {
            imageName = isChecked ? "checkmark.circle.fill" : "circle"
        }
        
        button.configuration?.image = UIImage(systemName: imageName)
    }

    private func setupMethodChannel() {
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            switch call.method {
            case "setValue":
                if let args = call.arguments as? [String: Any],
                   let value = args["value"] as? Bool {
                    self.isChecked = value
                    self.updateImage()
                    result(nil)
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    @objc private func toggleTapped() {
        if isRadio && isChecked { return } // Radio cannot be unselected by tapping
        isChecked.toggle()
        updateImage()
        channel.invokeMethod("onChanged", arguments: ["value": isChecked])
    }
}
