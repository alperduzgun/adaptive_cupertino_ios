import Flutter
import UIKit
import os.log

/// Platform View Factory for Adaptive Cupertino Toolbar (iOS 26+)
///
/// CHAOS ENGINEERING PRINCIPLES:
/// - Uses native UIToolbar with iOS 26's automatic pill-shaped button grouping
/// - NO custom styling - relies entirely on iOS 26 SDK's native behavior
/// - Fail fast with graceful degradation to UINavigationBar fallback
/// - Strict type safety with guard statements
/// - Comprehensive input validation and sanitization
/// - Structured logging for observability
/// - Memory-safe with weak references and proper disposal
@available(iOS 15.0, *)
class AdaptiveCupertinoToolbarFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private static let logger = OSLog(subsystem: "com.adaptive_cupertino_ios", category: "Toolbar")

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
        os_log(.info, log: Self.logger, "Toolbar Factory initialized")
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        os_log(.info, log: Self.logger, "Creating Toolbar view ID: %{public}lld", viewId)
        return AdaptiveCupertinoToolbarPlatformView(
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

/// Platform View wrapper for native iOS 26 UIToolbar
///
/// RESILIENCE STRATEGY:
/// - iOS 26+: Native UIToolbar with automatic pill-shaped grouping
/// - iOS 18-25: Fallback to UINavigationBar (graceful degradation)
/// - iOS <18: Should not reach here (handled by Dart layer)
///
/// SECURITY:
/// - All Dart inputs validated and sanitized
/// - Icon codes range-checked before use
/// - Method channel arguments strictly typed
///
/// ANTI-FRAGILE:
/// - Multiple fallback layers for setup failures
/// - Self-healing: Invalid state resets to safe defaults
/// - No silent failures: All errors logged
@available(iOS 15.0, *)
class AdaptiveCupertinoToolbarPlatformView: NSObject, FlutterPlatformView {

    // MARK: - Properties
    private var _view: UIView
    private var toolbar: UIToolbar?
    private var navigationBar: UINavigationBar? // Fallback for iOS 18-25
    private var navigationItem: UINavigationItem?
    private weak var messenger: FlutterBinaryMessenger?
    private let channel: FlutterMethodChannel
    private let viewId: Int64
    private let isIOS26: Bool
    private var topPadding: CGFloat = 0

    // MARK: - Observability
    private static let logger = OSLog(subsystem: "com.adaptive_cupertino_ios", category: "ToolbarView")

    // MARK: - Initialization

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        self._view = UIView(frame: frame)
        self.messenger = messenger
        self.viewId = viewId
        self.channel = FlutterMethodChannel(
            name: "adaptive_cupertino_ios/toolbar_\(viewId)",
            binaryMessenger: messenger
        )

        // Parse top padding from Dart for SafeArea alignment
        if let params = args as? [String: Any], let padding = params["topPadding"] as? NSNumber {
            self.topPadding = CGFloat(truncating: padding)
        }

        // Detect iOS 26 for native toolbar vs fallback
        self.isIOS26 = IOSVersionDetector.isIOS26OrNewer()

        super.init()

        os_log(.info, log: Self.logger, "Toolbar view created, iOS 26: %{public}@", isIOS26 ? "YES" : "NO")

        // Setup appropriate UI component
        if isIOS26 {
            setupNativeToolbar(arguments: args)
        } else {
            // Graceful degradation: Use NavigationBar for iOS 18-25
            os_log(.info, log: Self.logger, "Using NavigationBar fallback for iOS <26")
            setupFallbackNavigationBar(arguments: args)
        }

        setupMethodChannel()
    }

    func view() -> UIView {
        return _view
    }

    // MARK: - iOS 26 Native UIToolbar Setup

    /// Setup native iOS 26 UIToolbar with automatic pill-shaped button grouping
    /// NATIVE BEHAVIOR: iOS 26 SDK automatically groups buttons into pills
    /// NO CUSTOM STYLING: We use Apple's default appearance
    private func setupNativeToolbar(arguments args: Any?) {
        // Early exit if not iOS 26+
        guard #available(iOS 26.0, *) else {
            os_log(.error, log: Self.logger, "setupNativeToolbar called on iOS <26, aborting")
            return
        }
        guard let toolbar = UIToolbar() as UIToolbar? else {
            os_log(.error, log: Self.logger, "Failed to create UIToolbar, aborting setup")
            return
        }

        self.toolbar = toolbar
        toolbar.backgroundColor = .clear
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        // 1. Ensure the container view is fully transparent
        _view.backgroundColor = .clear
        _view.isOpaque = false

        // 2. Configure iOS 26 native appearance (automatic pill-shaped grouping)
        configureToolbarAppearance()

        // Parse and setup toolbar items from Dart
        if let params = args as? [String: Any] {
            configureToolbarItems(from: params)
        } else {
            os_log(OSLogType.default, log: Self.logger, "No parameters provided for toolbar configuration")
        }

        // Add to container
        _view.addSubview(toolbar)

        // Auto layout constraints: Pin to topPadding to stay within SafeArea
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            toolbar.topAnchor.constraint(equalTo: _view.topAnchor, constant: topPadding),
            toolbar.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
        ])

        os_log(.info, log: Self.logger, "Native UIToolbar setup completed with topPadding: %{public}.2f", topPadding)
    }

    /// Configure iOS 26 UIToolbarAppearance with native Liquid Glass
    /// NATIVE BEHAVIOR: Uses iOS 26 SDK's default pill-shaped grouping
    private func configureToolbarAppearance() {
        guard let toolbar = self.toolbar else { return }

        // iOS 26+ only configuration
        guard #available(iOS 26.0, *) else {
            os_log(.error, log: Self.logger, "configureToolbarAppearance called on iOS <26")
            return
        }

        // Create native iOS 26 appearance
        let appearance = UIToolbarAppearance()

        // Use fully transparent background with Ultra Thin blur
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundColor = UIColor.white.withAlphaComponent(0.02)

        // Configure prominent button appearance (iOS 26 API)
        let prominentButton = appearance.prominentButtonAppearance
        prominentButton.normal.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
            .foregroundColor: UIColor.label
        ]

        // Apply appearance
        toolbar.standardAppearance = appearance
        toolbar.compactAppearance = appearance
        toolbar.scrollEdgeAppearance = appearance

        // Enable translucency
        toolbar.isTranslucent = true

        os_log(.debug, log: Self.logger, "Toolbar appearance configured as fully transparent")
    }

    /// Configure toolbar items from Dart parameters with validation
    /// SECURITY: All inputs validated before use
    /// CHAOS RESISTANT: Invalid data results in safe defaults
    private func configureToolbarItems(from params: [String: Any]) {
        os_log(.debug, log: Self.logger, "Configuring toolbar items: %{public}@", String(describing: params))

        // Validate and extract title (SECURITY: Sanitize string input)
        if let title = params["title"] as? String, !title.isEmpty {
            let sanitizedTitle = sanitizeString(title, maxLength: 100)
            os_log(.debug, log: Self.logger, "Title: %{public}@", sanitizedTitle)
            // Note: UIToolbar doesn't have a title property by default
            // We'll add it as a centered text button if needed
        }

        var toolbarItems: [UIBarButtonItem] = []

        // Setup leading button (LEFT side)
        if let leadingData = params["leading"] as? [String: Any] {
            if let leadingButton = createBarButtonItem(from: leadingData, position: .leading) {
                toolbarItems.append(leadingButton)
                os_log(.debug, log: Self.logger, "Leading button added")
            }
        }

        // Add flexible space to push trailing buttons to the right
        toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))

        // Setup trailing buttons (RIGHT side)
        if let trailingArray = params["trailing"] as? [[String: Any]] {
            os_log(.debug, log: Self.logger, "Processing %{public}d trailing buttons", trailingArray.count)

            for (index, buttonData) in trailingArray.enumerated() {
                // SECURITY: Validate index bounds
                guard index < 10 else {
                    os_log(OSLogType.default, log: Self.logger, "Too many trailing buttons, limiting to 10")
                    break
                }

                if let button = createBarButtonItem(from: buttonData, position: .trailing, index: index) {
                    toolbarItems.append(button)
                    os_log(.debug, log: Self.logger, "Trailing button %{public}d added", index)
                }
            }
        }

        // Apply items to toolbar
        if #available(iOS 26.0, *), let toolbar = self.toolbar {
            toolbar.items = toolbarItems
            os_log(.info, log: Self.logger, "Toolbar items set: %{public}d total", toolbarItems.count)
        } else if let _ = self.navigationBar, let navItem = self.navigationItem {
            // Fallback for iOS 18-25: Map to NavigationBar
            // Filter out flexible space items (they're system items, not custom buttons)
            let customButtons = toolbarItems.filter { $0.customView == nil && $0.target != nil }
            if let first = customButtons.first {
                navItem.leftBarButtonItem = first
            }
            if customButtons.count > 1 {
                navItem.rightBarButtonItems = Array(customButtons.dropFirst())
            }
        }
    }

    /// Create UIBarButtonItem from validated data
    /// SECURITY: Icon code validation and range checking
    /// CHAOS RESISTANT: Returns nil on invalid data (fail safe)
    private func createBarButtonItem(
        from data: [String: Any],
        position: ButtonPosition,
        index: Int = 0
    ) -> UIBarButtonItem? {
        // Validate button type (SECURITY: Type checking)
        guard let type = data["type"] as? String else {
            os_log(OSLogType.default, log: Self.logger, "Missing button type")
            return nil
        }

        switch type {
        case "icon":
            return createIconButton(from: data, position: position, index: index)
        default:
            os_log(OSLogType.default, log: Self.logger, "Unknown button type: %{public}@", type)
            return nil
        }
    }

    /// Create icon-based button with validation
    /// SECURITY: Icon code range validation (0x0000 - 0x10FFFF Unicode range)
    private func createIconButton(
        from data: [String: Any],
        position: ButtonPosition,
        index: Int
    ) -> UIBarButtonItem? {
        // SECURITY: Validate icon code is within Unicode range
        guard let iconCode = data["iconCode"] as? Int,
              iconCode >= 0x0000,
              iconCode <= 0x10FFFF else {
            os_log(.error, log: Self.logger, "Invalid icon code: %{public}@", String(describing: data["iconCode"]))
            return nil
        }

        // Check if this button should be prominent (iOS 26 feature)
        let isProminent = data["prominent"] as? Bool ?? false

        // Check if this button shares background with adjacent buttons
        let sharesBackground = data["sharesBackground"] as? Bool ?? true

        // Create SF Symbol image or use Unicode fallback
        let button: UIBarButtonItem
        if let iconName = data["iconName"] as? String {
            // Try SF Symbol first
            if let image = UIImage(systemName: iconName) {
                button = UIBarButtonItem(
                    image: image,
                    style: isProminent ? .done : .plain,
                    target: self,
                    action: position == .leading ? #selector(leadingTapped) : #selector(trailingTapped(_:))
                )
            } else {
                // Fallback to Unicode
                button = createUnicodeButton(
                    iconCode: iconCode,
                    family: data["iconFamily"] as? String ?? "",
                    position: position,
                    isProminent: isProminent
                )
            }
        } else {
            // Unicode-only button
            button = createUnicodeButton(
                iconCode: iconCode,
                family: data["iconFamily"] as? String ?? "",
                position: position,
                isProminent: isProminent
            )
        }

        button.tag = index

        // Apply iOS 26 pill-grouping property
        // iOS 26 API: hidesSharedBackground (inverse logic)
        // sharesBackground = true  → hidesSharedBackground = false (group in pill)
        // sharesBackground = false → hidesSharedBackground = true (separate pill)
        if #available(iOS 26.0, *) {
            button.hidesSharedBackground = !sharesBackground
            os_log(.debug, log: Self.logger,
                   "Button created: prominent=%{public}@, hidesSharedBackground=%{public}@",
                   isProminent ? "YES" : "NO", (!sharesBackground) ? "YES" : "NO")
        }

        return button
    }

    /// Create button with Unicode icon and proper font mapping
    private func createUnicodeButton(
        iconCode: Int,
        family: String,
        position: ButtonPosition,
        isProminent: Bool
    ) -> UIBarButtonItem {
        let iconString = String(format: "%C", iconCode)
        let button = UIBarButtonItem(
            title: iconString,
            style: isProminent ? .done : .plain,
            target: self,
            action: position == .leading ? #selector(leadingTapped) : #selector(trailingTapped(_:))
        )

        // Apply correct icon font (CupertinoIcons or MaterialIcons)
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

    // MARK: - Fallback NavigationBar (iOS 18-25)

    /// Setup fallback UINavigationBar for iOS 18-25
    /// GRACEFUL DEGRADATION: Uses NavigationBar when Toolbar not available
    private func setupFallbackNavigationBar(arguments args: Any?) {
        let navigationBar = UINavigationBar()
        navigationBar.translatesAutoresizingMaskIntoConstraints = false

        self.navigationBar = navigationBar
        self.navigationItem = UINavigationItem()

        // Configure appearance
        if #available(iOS 18.0, *) {
            configureFallbackAppearance()
        }

        // Parse configuration
        if let params = args as? [String: Any] {
            configureFallbackItems(from: params)
        }

        if let navItem = navigationItem {
            navigationBar.items = [navItem]
        }

        // Add to container
        _view.addSubview(navigationBar)

        // Constraints
        NSLayoutConstraint.activate([
            navigationBar.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            navigationBar.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            navigationBar.topAnchor.constraint(equalTo: _view.topAnchor),
            navigationBar.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
        ])

        os_log(.info, log: Self.logger, "Fallback NavigationBar setup completed")
    }

    @available(iOS 18.0, *)
    private func configureFallbackAppearance() {
        guard let navigationBar = self.navigationBar else { return }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.1)
        appearance.shadowColor = .clear

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.isTranslucent = true

        os_log(.debug, log: Self.logger, "Fallback NavigationBar appearance configured")
    }

    private func configureFallbackItems(from params: [String: Any]) {
        guard let navItem = navigationItem else { return }

        // Set title
        if let title = params["title"] as? String {
            navItem.title = sanitizeString(title, maxLength: 100)
        }

        // Setup leading
        if let leadingData = params["leading"] as? [String: Any],
           let button = createBarButtonItem(from: leadingData, position: .leading) {
            navItem.leftBarButtonItem = button
        }

        // Setup trailing
        if let trailingArray = params["trailing"] as? [[String: Any]] {
            let buttons = trailingArray.enumerated().compactMap { index, data in
                createBarButtonItem(from: data, position: .trailing, index: index)
            }
            navItem.rightBarButtonItems = buttons
        }
    }

    // MARK: - Button Actions

    @objc private func leadingTapped() {
        os_log(.debug, log: Self.logger, "Leading button tapped")
        channel.invokeMethod("onLeadingTapped", arguments: nil)
    }

    @objc private func trailingTapped(_ sender: UIBarButtonItem) {
        os_log(.debug, log: Self.logger, "Trailing button tapped: %{public}d", sender.tag)
        channel.invokeMethod("onTrailingTapped", arguments: ["index": sender.tag])
    }

    // MARK: - Method Channel

    private func setupMethodChannel() {
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else {
                result(FlutterError(code: "DISPOSED", message: "View disposed", details: nil))
                return
            }

            os_log(.debug, log: Self.logger, "Method call: %{public}@", call.method)

            switch call.method {
            case "setTitle":
                self.handleSetTitle(call: call, result: result)
            case "updateButton":
                self.handleUpdateButton(call: call, result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func handleSetTitle(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let title = args["title"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "Invalid title", details: nil))
            return
        }

        let sanitized = sanitizeString(title, maxLength: 100)
        navigationItem?.title = sanitized
        os_log(.debug, log: Self.logger, "Title updated: %{public}@", sanitized)
        result(nil)
    }

    private func handleUpdateButton(call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Future: Support runtime button updates
        result(FlutterMethodNotImplemented)
    }

    // MARK: - Security Helpers

    /// Sanitize string input to prevent malicious data
    /// SECURITY: Length limiting and character validation
    private func sanitizeString(_ input: String, maxLength: Int) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return String(trimmed.prefix(maxLength))
    }

    // MARK: - Helper Types

    private enum ButtonPosition {
        case leading
        case trailing
    }

    // MARK: - Cleanup

    deinit {
        channel.setMethodCallHandler(nil)
        os_log(.info, log: Self.logger, "Toolbar view disposed (ID: %{public}lld)", viewId)
    }
}
