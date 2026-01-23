import Flutter
import UIKit

/// Platform View Factory for Adaptive Cupertino AppBar
@available(iOS 15.0, *)
class AdaptiveCupertinoAppBarFactory: NSObject, FlutterPlatformViewFactory {
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
        return AdaptiveCupertinoAppBarPlatformView(
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

/// Platform View wrapper for UINavigationBar
@available(iOS 15.0, *)
class AdaptiveCupertinoAppBarPlatformView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var navigationBar: UINavigationBar!
    private var navigationItem: UINavigationItem!
    private var messenger: FlutterBinaryMessenger
    private let channel: FlutterMethodChannel
    private var topPadding: CGFloat = 0

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        self.messenger = messenger
        self._view = UIView(frame: frame)
        self.channel = FlutterMethodChannel(
            name: "adaptive_cupertino_ios/app_bar_\(viewId)",
            binaryMessenger: messenger
        )

        // Parse top padding from Dart
        if let params = args as? [String: Any], let padding = params["topPadding"] as? NSNumber {
            self.topPadding = CGFloat(truncating: padding)
        }

        super.init()

        setupNavigationBar(arguments: args)
        setupMethodChannel()
    }

    func view() -> UIView {
        return _view
    }

    private func setupNavigationBar(arguments args: Any?) {
        navigationBar = UINavigationBar()
        navigationBar.backgroundColor = .clear
        navigationBar.translatesAutoresizingMaskIntoConstraints = false

        // 1. Ensure the container view is fully transparent
        _view.backgroundColor = .clear
        _view.isOpaque = false

        // 2. Create navigation item
        navigationItem = UINavigationItem()

        // Setup appearance based on iOS version
        if #available(iOS 18.0, *) {
            setupLiquidGlassAppearance()
        } else {
            setupStandardAppearance()
        }

        // Parse configuration from arguments
        if let params = args as? [String: Any] {
            configureFromParams(params)
        }

        navigationBar.items = [navigationItem]

        // Add to container view
        _view.addSubview(navigationBar)

        // Auto layout constraints: Pin to topPadding to stay within SafeArea
        NSLayoutConstraint.activate([
            navigationBar.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            navigationBar.topAnchor.constraint(equalTo: _view.topAnchor, constant: topPadding),
            navigationBar.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
        ])
    }

    @available(iOS 18.0, *)
    private func setupLiquidGlassAppearance() {
        let appearance = UINavigationBarAppearance()

        // Use fully transparent background configuration
        appearance.configureWithTransparentBackground()
        
        // Add true Liquid Glass effect: Ultra Thin material for premium transparency
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.02) // Barely visible tint

        // Remove shadow for cleaner look
        appearance.shadowColor = .clear

        // Title styling
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
            .foregroundColor: UIColor.label
        ]

        // Large title styling
        appearance.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 34, weight: .bold),
            .foregroundColor: UIColor.label
        ]

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance

        // Enable translucency
        navigationBar.isTranslucent = true
    }

    private func setupStandardAppearance() {
        navigationBar.barTintColor = .systemBackground
        navigationBar.tintColor = .systemBlue
        navigationBar.isTranslucent = true
    }

    private func configureFromParams(_ params: [String: Any]) {
        print("📱 [Swift AppBar] Received params: \(params)")

        // Set title
        if let title = params["title"] as? String {
            navigationItem.title = title
            print("   ✅ Title set: \(title)")
        }

        // Set large title preference
        if let largeTitle = params["largeTitle"] as? Bool {
            navigationBar.prefersLargeTitles = largeTitle
            print("   ✅ Large title: \(largeTitle)")
        }

        // Setup leading button
        if let leadingData = params["leading"] as? [String: Any] {
            print("   🔍 Leading data: \(leadingData)")
            if let button = createBarButtonItem(from: leadingData, isLeading: true) {
                navigationItem.leftBarButtonItem = button
                print("   ✅ Leading button created")
            } else {
                print("   ❌ Leading button creation failed")
            }
        } else {
            print("   ⚠️ No leading data")
        }

        // Setup trailing buttons
        if let trailingArray = params["trailing"] as? [[String: Any]] {
            print("   🔍 Trailing array: \(trailingArray)")
            var buttons: [UIBarButtonItem] = []
            for (index, buttonData) in trailingArray.enumerated() {
                if let button = createBarButtonItem(from: buttonData, isLeading: false, index: index) {
                    buttons.append(button)
                    print("   ✅ Trailing button \(index) created")
                } else {
                    print("   ❌ Trailing button \(index) failed")
                }
            }
            navigationItem.rightBarButtonItems = buttons
            print("   ✅ Total trailing buttons: \(buttons.count)")
        } else {
            print("   ⚠️ No trailing data")
        }
    }

    private func createBarButtonItem(from data: [String: Any], isLeading: Bool, index: Int = 0) -> UIBarButtonItem? {
        guard let type = data["type"] as? String else { return nil }

        switch type {
        case "icon":
            // 1. Try SF Symbols first (if provided)
            if let iconName = data["iconName"] as? String,
               let image = UIImage(systemName: iconName) {
                let button = UIBarButtonItem(
                    image: image,
                    style: .plain,
                    target: self,
                    action: isLeading ? #selector(leadingTapped) : #selector(trailingTapped(_:))
                )
                button.tag = index
                return button
            }

            // 2. Fallback to Unicode with proper font mapping
            if let iconCode = data["iconCode"] as? Int {
                let iconString = String(format: "%C", iconCode)
                let button = UIBarButtonItem(
                    title: iconString,
                    style: .plain,
                    target: self,
                    action: isLeading ? #selector(leadingTapped) : #selector(trailingTapped(_:))
                )
                button.tag = index

                // Apply correct icon font (CupertinoIcons or MaterialIcons)
                let family = data["iconFamily"] as? String ?? ""
                let fontSize: CGFloat = 24.0
                var font: UIFont?

                if family.contains("CupertinoIcons") {
                    font = UIFont(name: "CupertinoIcons", size: fontSize)
                } else if family.contains("MaterialIcons") {
                    font = UIFont(name: "MaterialIcons-Regular", size: fontSize)
                }

                if let iconFont = font {
                    let attributes: [NSAttributedString.Key: Any] = [.font: iconFont]
                    button.setTitleTextAttributes(attributes, for: .normal)
                    button.setTitleTextAttributes(attributes, for: .highlighted)
                }

                return button
            }
            return nil

        default:
            return nil
        }
    }

    @objc private func leadingTapped() {
        channel.invokeMethod("onLeadingTapped", arguments: nil)
    }

    @objc private func trailingTapped(_ sender: UIBarButtonItem) {
        channel.invokeMethod("onTrailingTapped", arguments: ["index": sender.tag])
    }

    private func setupMethodChannel() {
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else {
                result(FlutterError(code: "UNAVAILABLE", message: "View not available", details: nil))
                return
            }

            switch call.method {
            case "setTitle":
                if let args = call.arguments as? [String: Any],
                   let title = args["title"] as? String {
                    self.navigationItem.title = title
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid title", details: nil))
                }

            case "setLargeTitle":
                if let args = call.arguments as? [String: Any],
                   let largeTitle = args["enabled"] as? Bool {
                    self.navigationBar.prefersLargeTitles = largeTitle
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid argument", details: nil))
                }

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
}
