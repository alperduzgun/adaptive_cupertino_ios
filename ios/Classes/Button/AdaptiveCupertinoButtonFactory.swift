import Flutter
import UIKit

/// Platform View Factory for Adaptive Cupertino Button
///
/// Creates native iOS buttons with support for modern iOS 26+ styles (Liquid Glass)
/// and fails safe to standard UIButton on older versions.
@available(iOS 15.0, *)
class AdaptiveCupertinoButtonFactory: NSObject, FlutterPlatformViewFactory {
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
        return AdaptiveCupertinoButtonPlatformView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }

    /// Codec for creation parameters
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/// Button style variants
enum AdaptiveButtonStyle: String {
    case glass = "glass"
    case glassProminent = "glassProminent"
    case glassTinted = "glassTinted"
    case filled = "filled"
    case plain = "plain"
}

/// Icon placement options (iOS 15+)
enum IconPlacement: String {
    case leading = "leading"
    case trailing = "trailing"
    case top = "top"
    case bottom = "bottom"
}

/// Platform View wrapper for UIButton with Adaptive configuration
///
/// CHAOS ENGINEERING PRINCIPLES:
/// - Explicit runtime version checks (iOS 26 vs older)
/// - Safe defaults for missing parameters
/// - Generic naming to support future button styles (not just Glass)
@available(iOS 15.0, *)
class AdaptiveCupertinoButtonPlatformView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var button: UIButton!
    private var messenger: FlutterBinaryMessenger
    private let channel: FlutterMethodChannel
    
    // Runtime version check
    private let isIOS26: Bool

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        self.messenger = messenger
        self._view = UIView(frame: frame)
        self.channel = FlutterMethodChannel(
            name: "adaptive_cupertino_ios/glass_button_\(viewId)",
            binaryMessenger: messenger
        )
        // STRICT CHECK: Runtime detection
        self.isIOS26 = IOSVersionDetector.isIOS26OrNewer()
        
        super.init()

        setupButton(arguments: args)
        setupMethodChannel()
    }

    func view() -> UIView {
        return _view
    }

    private func setupButton(arguments args: Any?) {
        guard let params = args as? [String: Any] else {
            setupFallbackButton()
            return
        }

        let title = params["title"] as? String ?? ""
        let styleString = params["style"] as? String ?? "glass"
        let enabled = params["enabled"] as? Bool ?? true
        let tintColor = params["tintColor"] as? String
        let iconName = params["icon"] as? String
        let iconPlacementString = params["iconPlacement"] as? String ?? "leading"

        let style = AdaptiveButtonStyle(rawValue: styleString) ?? .glass
        let iconPlacement = IconPlacement(rawValue: iconPlacementString) ?? .leading

        // Create button based on availability AND runtime check
        if #available(iOS 26.0, *), isIOS26 {
            // Modern iOS 26+ "Liquid Glass" / Pill styles
            button = createModernButton(
                title: title,
                style: style,
                tintColor: tintColor,
                iconName: iconName,
                iconPlacement: iconPlacement
            )
        } else {
            // Fallback for older iOS (Standard Filled/Plain)
            button = createFallbackButton(
                title: title,
                enabled: enabled,
                iconName: iconName
            )
        }

        button.isEnabled = enabled
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        // Add to container view
        _view.addSubview(button)

        // Auto layout constraints
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            button.topAnchor.constraint(equalTo: _view.topAnchor),
            button.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
        ])
    }

    @available(iOS 26.0, *)
    private func createModernButton(
        title: String,
        style: AdaptiveButtonStyle,
        tintColor: String?,
        iconName: String?,
        iconPlacement: IconPlacement
    ) -> UIButton {
        var config: UIButton.Configuration

        switch style {
        case .glass:
            config = UIButton.Configuration.glass()
        case .glassProminent:
            config = UIButton.Configuration.prominentGlass()
        case .glassTinted:
            config = UIButton.Configuration.glass()
            if let colorHex = tintColor {
                 config.baseBackgroundColor = UIColor(hex: colorHex)
            }
        case .filled:
             config = UIButton.Configuration.filled()
        case .plain:
             config = UIButton.Configuration.plain()
        }

        config.title = title
        config.cornerStyle = .large

        // Icon configuration (SF Symbols)
        if let icon = iconName {
            config.image = UIImage(systemName: icon)

            // Icon placement
            switch iconPlacement {
            case .leading:
                config.imagePlacement = .leading
            case .trailing:
                config.imagePlacement = .trailing
            case .top:
                config.imagePlacement = .top
            case .bottom:
                config.imagePlacement = .bottom
            }

            // Icon padding
            config.imagePadding = 8
        }

        // Standard padding for modern look
        config.contentInsets = NSDirectionalEdgeInsets(
            top: 12,
            leading: 20,
            bottom: 12,
            trailing: 20
        )

        let button = UIButton(configuration: config)
        
        // Dynamic configuration update handler
        button.configurationUpdateHandler = { button in
            var config = button.configuration

            switch button.state {
            case .highlighted:
                config?.background.backgroundColorTransformer = .init { color in
                    return color.withAlphaComponent(0.7)
                }
            case .disabled:
                config?.baseForegroundColor = .systemGray
            default:
                break
            }

            button.configuration = config
        }

        return button
    }

    private func createFallbackButton(
        title: String,
        enabled: Bool,
        iconName: String?
    ) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .large
        
        var titleContainer = AttributeContainer()
        titleContainer.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        config.attributedTitle = AttributedString(title, attributes: titleContainer)

        // Icon configuration
        if let icon = iconName {
            config.image = UIImage(systemName: icon)
            config.imagePadding = 8
            config.imagePlacement = .leading
        }

        // Standard padding
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20)

        let button = UIButton(configuration: config)
        button.isEnabled = enabled
        return button
    }

    private func setupFallbackButton() {
        button = createFallbackButton(title: "Button", enabled: true, iconName: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        _view.addSubview(button)

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: _view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: _view.centerYAnchor)
        ])
    }

    private func setupMethodChannel() {
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else {
                result(FlutterError(code: "UNAVAILABLE", message: "View not available", details: nil))
                return
            }

            switch call.method {
            case "setEnabled":
                if let args = call.arguments as? [String: Any],
                   let enabled = args["enabled"] as? Bool {
                    self.button.isEnabled = enabled
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid enabled argument", details: nil))
                }

            case "setTitle":
                if let args = call.arguments as? [String: Any],
                   let title = args["title"] as? String {
                    if #available(iOS 26.0, *), self.isIOS26 {
                         self.button.configuration?.title = title
                    } else {
                        self.button.setTitle(title, for: .normal)
                    }
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid title argument", details: nil))
                }

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    @objc private func buttonTapped() {
        channel.invokeMethod("onPressed", arguments: nil)
    }
}
