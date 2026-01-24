import Flutter
import UIKit

/// Platform View Factory for Adaptive Cupertino Navigation Bar
///
/// Renamed from "AppBar" to match UIKit terminology (UINavigationBar).
@available(iOS 15.0, *)
class AdaptiveCupertinoNavigationBarFactory: NSObject, FlutterPlatformViewFactory {
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
        return AdaptiveCupertinoNavigationBarPlatformView(
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
///
/// CHAOS ENGINEERING:
/// - iOS 26+ support with strict runtime checks
/// - Liquid Glass fallback for iOS 18-25
/// - Standard fallback for older versions
/// Platform View wrapper for UINavigationBar
///
/// CHAOS ENGINEERING:
/// - iOS 26+ support with strict runtime checks
/// - Liquid Glass fallback for iOS 18-25
/// - Standard fallback for older versions
@available(iOS 15.0, *)
class AdaptiveCupertinoNavigationBarPlatformView: NSObject, FlutterPlatformView, UINavigationBarDelegate {
    private var _view: UIView
    private var navigationBar: UINavigationBar!
    private var navigationItem: UINavigationItem!
    private var messenger: FlutterBinaryMessenger
    private let channel: FlutterMethodChannel
    private var topPadding: CGFloat = 0
    
    // STRICT RUNTIME CHECK
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
            name: "adaptive_cupertino_ios/app_bar_\(viewId)",
            binaryMessenger: messenger
        )
        self.isIOS26 = IOSVersionDetector.isIOS26OrNewer()

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

    // MARK: - UINavigationBarDelegate
    
    /// Tell the system this bar is attached to the top of the screen
    /// This triggers the automatic status bar blur extension "Liquid Glass logic"
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }

    private func setupNavigationBar(arguments args: Any?) {
        navigationBar = UINavigationBar()
        navigationBar.delegate = self // Set delegate for position(for:)
        navigationBar.backgroundColor = .clear
        navigationBar.translatesAutoresizingMaskIntoConstraints = false

        // 1. Ensure the container view is fully transparent
        _view.backgroundColor = .clear
        _view.isOpaque = false

        // 2. Add full-bleed background blur (Liquid Glass Effect)
        setupBackgroundBlur()

        // 3. Create navigation item
        navigationItem = UINavigationItem()

        // Setup appearance based on iOS version
        setupTransparentAppearance()

        // Parse configuration from arguments
        if let params = args as? [String: Any] {
            configureFromParams(params)
        }

        navigationBar.items = [navigationItem]

        // Add to container view
        _view.addSubview(navigationBar)

        // Auto layout constraints: Pin to SAFE AREA
        NSLayoutConstraint.activate([
            navigationBar.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            navigationBar.topAnchor.constraint(equalTo: _view.safeAreaLayoutGuide.topAnchor), // Pin to Safe Area for content safety
            navigationBar.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
        ])
    }

    private func setupBackgroundBlur() {
        // Force .light style to avoid gray system adaptation
        let blurEffect = UIBlurEffect(style: .light)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.backgroundColor = .clear

        // Add a "Milky" white tint layer to enhance Liquid Glass effect
        let tintView = UIView()
        tintView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        tintView.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.addSubview(tintView)

        // Pin tint view
        NSLayoutConstraint.activate([
            tintView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
            tintView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
            tintView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor)
        ])

        _view.addSubview(blurView)

        // Pin to ABSOLUTE edges
        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            blurView.topAnchor.constraint(equalTo: _view.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
        ])
        
        // Add a "Glass Edge" separator - a very thin, subtle white line at the bottom
        // This gives it a "cut glass" look instead of just ending.
        let edgeLine = UIView()
        edgeLine.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        edgeLine.translatesAutoresizingMaskIntoConstraints = false
        _view.addSubview(edgeLine)
        
        NSLayoutConstraint.activate([
            edgeLine.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            edgeLine.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            edgeLine.bottomAnchor.constraint(equalTo: _view.bottomAnchor),
            edgeLine.heightAnchor.constraint(equalToConstant: 0.5) // Hairline
        ])
    }
    
    /// Setup "iOS 26 Liquid Glass" Appearance
    /// We make the bar transparent because the blur is handled by the backing view
    private func setupTransparentAppearance() {
        let appearance = UINavigationBarAppearance()
        
        // "Liquid Glass" Configuration:
        // Make the BAR itself transparent so the backing blur view shows through
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear // Transparent
        appearance.backgroundEffect = nil // No internal blur (handled by setupBackgroundBlur)
        
        // Remove shadow for cleaner look
        appearance.shadowColor = .clear
        
        // Modern typography
        appearance.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
            .foregroundColor: UIColor.label
        ]
        
        appearance.largeTitleTextAttributes = [
             .font: UIFont.systemFont(ofSize: 34, weight: .bold),
             .foregroundColor: UIColor.label
        ]

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        
        // iOS 26+ prefers large titles by default if flag is set
        if #available(iOS 26.0, *), isIOS26 {
             navigationBar.prefersLargeTitles = true
        }

        navigationBar.isTranslucent = true
    }

    private func setupStandardAppearance() {
        navigationBar.barTintColor = .systemBackground
        navigationBar.tintColor = .systemBlue
        navigationBar.isTranslucent = true
    }

    private func configureFromParams(_ params: [String: Any]) {
        // Set title
        if let title = params["title"] as? String {
            navigationItem.title = title
        }

        // Set large title preference
        if let largeTitle = params["largeTitle"] as? Bool {
            navigationBar.prefersLargeTitles = largeTitle
        }

        // Setup leading button
        if let leadingData = params["leading"] as? [String: Any] {
            if let button = createBarButtonItem(from: leadingData, isLeading: true) {
                navigationItem.leftBarButtonItem = button
            }
        }

        // Setup trailing buttons
        if let trailingArray = params["trailing"] as? [[String: Any]] {
            var buttons: [UIBarButtonItem] = []
            for (index, buttonData) in trailingArray.enumerated() {
                if let button = createBarButtonItem(from: buttonData, isLeading: false, index: index) {
                    buttons.append(button)
                }
            }
            navigationItem.rightBarButtonItems = buttons
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
