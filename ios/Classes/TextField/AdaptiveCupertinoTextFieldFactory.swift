import Flutter
import UIKit
import os.log

/// Platform View Factory for Adaptive Cupertino TextField
@available(iOS 15.0, *)
class AdaptiveCupertinoTextFieldFactory: NSObject, FlutterPlatformViewFactory {
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
        return AdaptiveCupertinoTextFieldPlatformView(
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

/// Platform View wrapper for UITextField with Glass support
@available(iOS 15.0, *)
class AdaptiveCupertinoTextFieldPlatformView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var textField: UITextField!
    private let messenger: FlutterBinaryMessenger
    private let channel: FlutterMethodChannel
    private static let logger = OSLog(subsystem: "com.adaptive_cupertino_ios", category: "TextFieldFactory")

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
            name: "adaptive_cupertino_ios/text_field_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()

        setupTextField(arguments: args)
        setupMethodChannel()
    }

    func view() -> UIView {
        return _view
    }

    private func setupTextField(arguments args: Any?) {
        guard let params = args as? [String: Any] else {
            os_log(.error, log: Self.logger, "Invalid arguments for TextField")
            return
        }

        let placeholder = params["placeholder"] as? String ?? ""
        let text = params["text"] as? String ?? ""
        let useGlass = params["useGlass"] as? Bool ?? false
        let borderRadius = params["borderRadius"] as? CGFloat ?? 12.0
        let obscureText = params["obscureText"] as? Bool ?? false
        let keyboardTypeString = params["keyboardType"] as? String ?? "text"

        textField = UITextField()
        textField.text = text
        textField.placeholder = placeholder
        textField.isSecureTextEntry = obscureText
        
        switch keyboardTypeString {
        case "number": textField.keyboardType = .numberPad
        case "email": textField.keyboardType = .emailAddress
        case "phone": textField.keyboardType = .phonePad
        case "url": textField.keyboardType = .URL
        default: textField.keyboardType = .default
        }

        textField.borderStyle = .none
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        // CHAOS SAFETY: Padding to prevent text from touching edges
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        textField.leftView = paddingView
        textField.leftViewMode = .always
        textField.rightView = paddingView
        textField.rightViewMode = .always

        if useGlass {
            // Apply native glass background
            // FIX: precise clipping handled by parent _view (applyGeometry: false)
            let glass = AdaptiveGlassView(frame: .zero, isInteractive: true, variant: 0, applyGeometry: false)
            glass.translatesAutoresizingMaskIntoConstraints = false
            _view.addSubview(glass)
            
            NSLayoutConstraint.activate([
                glass.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                glass.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                glass.topAnchor.constraint(equalTo: _view.topAnchor),
                glass.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
            ])
            
            AdaptiveGlassHelper.configureModernGeometry(for: _view, radius: borderRadius)
        } else {
            _view.backgroundColor = .systemBackground
            _view.layer.cornerRadius = borderRadius
        }

        _view.addSubview(textField)

        NSLayoutConstraint.activate([
            textField.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            textField.topAnchor.constraint(equalTo: _view.topAnchor),
            textField.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
        ])
        
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)
    }

    private func setupMethodChannel() {
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }

            switch call.method {
            case "setText":
                if let args = call.arguments as? [String: Any],
                   let text = args["text"] as? String {
                    self.textField.text = text
                    result(nil)
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    @objc private func textChanged() {
        channel.invokeMethod("onChanged", arguments: ["text": textField.text ?? ""])
    }
}
