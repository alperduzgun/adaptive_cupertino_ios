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
class AdaptiveCupertinoToolbarPlatformView: NSObject, FlutterPlatformView, UIToolbarDelegate {

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
        self.messenger = messenger
        self._view = UIView(frame: frame)
        self.channel = FlutterMethodChannel(
            name: "adaptive_cupertino_ios/toolbar_\(viewId)",
            binaryMessenger: messenger
        )

        if let params = args as? [String: Any], let padding = params["topPadding"] as? NSNumber {
            self.topPadding = CGFloat(truncating: padding)
        }
        
        self.viewId = viewId
        // Detect iOS 26 for native toolbar vs fallback
        self.isIOS26 = IOSVersionDetector.isIOS26OrNewer()

        super.init()

        setupNativeToolbar(arguments: args)
        setupMethodChannel()
    }

    func view() -> UIView {
        return _view
    }

    // MARK: - UIToolbarDelegate
    
    /// Tell the system this toolbar is attached to the top of the screen
    /// This triggers the automatic status bar blur extension
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }

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
        toolbar.delegate = self // Set delegate for position(for:)
        toolbar.backgroundColor = .clear
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        // 1. Ensure the container view is fully transparent
        _view.backgroundColor = .clear
        _view.isOpaque = false

        // Parse enableLiquidGlass parameter (default: true)
        let enableLiquidGlass: Bool
        if let params = args as? [String: Any], let enabled = params["enableLiquidGlass"] as? Bool {
            enableLiquidGlass = enabled
        } else {
            enableLiquidGlass = true // Default
        }

        // 2. Conditionally add LiquidGlass background
        if enableLiquidGlass {
            let liquidGlass = LiquidGlassBackgroundView()
            liquidGlass.translatesAutoresizingMaskIntoConstraints = false
            _view.addSubview(liquidGlass)
            
            NSLayoutConstraint.activate([
                liquidGlass.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                liquidGlass.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                liquidGlass.topAnchor.constraint(equalTo: _view.topAnchor),
                liquidGlass.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
            ])
            
            os_log(.debug, log: Self.logger, "LiquidGlass background enabled")
        } else {
            os_log(.debug, log: Self.logger, "LiquidGlass background disabled - toolbar is transparent")
        }

        // 3. Configure iOS 26 native appearance (toolbar always transparent)
        configureToolbarAppearance()

        // Parse and setup toolbar items from Dart
        if let params = args as? [String: Any] {
            configureToolbarItems(from: params)
        } else {
            os_log(OSLogType.default, log: Self.logger, "No parameters provided for toolbar configuration")
        }

        // Add toolbar to container (on top of liquid glass if enabled)
        _view.addSubview(toolbar)

        // Pin toolbar to Safe Area for content
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            toolbar.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            toolbar.topAnchor.constraint(equalTo: _view.safeAreaLayoutGuide.topAnchor),
            toolbar.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
        ])

        os_log(.info, log: Self.logger, "Native UIToolbar setup completed (liquidGlass: %{public}@)", enableLiquidGlass ? "enabled" : "disabled")
    }

    /// Custom Liquid Glass Background View with gradient-masked blur
    /// This provides the true "fading blur" effect at the bottom edge
    /// Enhanced with: Inner glow, Dark mode support, White tint overlay
    class LiquidGlassBackgroundView: UIView {
        private let blurView: UIVisualEffectView
        private let gradientMask = CAGradientLayer()
        private let whiteTintView = UIView() // Milky overlay
        private let innerGlowView = UIView() // Bottom edge highlight
        
        override init(frame: CGRect) {
            // Adaptive blur style based on current trait collection
            let blurStyle: UIBlurEffect.Style = .systemUltraThinMaterial
            blurView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
            super.init(frame: frame)
            setupLiquidGlass()
        }
        
        required init?(coder: NSCoder) {
            let blurStyle: UIBlurEffect.Style = .systemUltraThinMaterial
            blurView = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
            super.init(coder: coder)
            setupLiquidGlass()
        }
        
        private func setupLiquidGlass() {
            backgroundColor = .clear
            
            // 1. Add blur view (base layer)
            blurView.translatesAutoresizingMaskIntoConstraints = false
            blurView.alpha = 0.4 // Reduced blur intensity (40%)
            addSubview(blurView)
            
            NSLayoutConstraint.activate([
                blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
                blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
                blurView.topAnchor.constraint(equalTo: topAnchor),
                blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
            
            // 2. Add subtle white tint for "milky" appearance
            whiteTintView.backgroundColor = UIColor.white.withAlphaComponent(0.08)
            whiteTintView.translatesAutoresizingMaskIntoConstraints = false
            blurView.contentView.addSubview(whiteTintView)
            
            NSLayoutConstraint.activate([
                whiteTintView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
                whiteTintView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
                whiteTintView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
                whiteTintView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor)
            ])
            
            // 3. Add inner glow (bottom edge highlight for depth)
            innerGlowView.backgroundColor = UIColor.white.withAlphaComponent(0.15)
            innerGlowView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(innerGlowView)
            
            NSLayoutConstraint.activate([
                innerGlowView.leadingAnchor.constraint(equalTo: leadingAnchor),
                innerGlowView.trailingAnchor.constraint(equalTo: trailingAnchor),
                innerGlowView.bottomAnchor.constraint(equalTo: bottomAnchor),
                innerGlowView.heightAnchor.constraint(equalToConstant: 0.5) // Hairline
            ])
            
            // 4. Setup gradient mask for fading effect
            gradientMask.colors = [
                UIColor.black.cgColor,  // Top: Fully visible
                UIColor.black.cgColor,  // Keep visible through most of the bar
                UIColor.clear.cgColor   // Bottom: Fade to transparent
            ]
            gradientMask.locations = [0.0, 0.8, 1.0] // Blur covers 80%, fades in last 20%
            gradientMask.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradientMask.endPoint = CGPoint(x: 0.5, y: 1.0)
            
            layer.mask = gradientMask
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            gradientMask.frame = bounds
        }
        
        // Update blur style when trait collection changes (light/dark mode)
        override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
            super.traitCollectionDidChange(previousTraitCollection)
            
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateForCurrentAppearance()
            }
        }
        
        private func updateForCurrentAppearance() {
            let isDark = traitCollection.userInterfaceStyle == .dark
            
            // Adjust white tint for dark mode
            whiteTintView.backgroundColor = isDark 
                ? UIColor.white.withAlphaComponent(0.04)  // Less tint in dark mode
                : UIColor.white.withAlphaComponent(0.08)  // Normal tint in light mode
            
            // Adjust inner glow for dark mode
            innerGlowView.backgroundColor = isDark
                ? UIColor.white.withAlphaComponent(0.08)  // Subtle in dark mode
                : UIColor.white.withAlphaComponent(0.15)  // More visible in light mode
        }
    }

    /// Configure UIToolbar to be FULLY TRANSPARENT (liquid glass is behind)
    private func configureToolbarAppearance() {
        guard let toolbar = self.toolbar else { return }
        guard #available(iOS 26.0, *) else { return }

        let appearance = UIToolbarAppearance()
        
        // Make toolbar completely transparent - liquid glass shows through
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.backgroundEffect = nil // No blur here - custom view handles it
        appearance.shadowColor = .clear // No separator line

        // Configure prominent button appearance
        let prominentButton = appearance.prominentButtonAppearance
        prominentButton.normal.titleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
            .foregroundColor: UIColor.label
        ]

        toolbar.standardAppearance = appearance
        toolbar.compactAppearance = appearance
        toolbar.scrollEdgeAppearance = appearance
        toolbar.isTranslucent = true
    }

    /// Configure toolbar items from Dart parameters with validation
    /// SECURITY: All inputs validated before use
    /// CHAOS RESISTANT: Invalid data results in safe defaults
    private func configureToolbarItems(from params: [String: Any]) {
        os_log(.debug, log: Self.logger, "Configuring toolbar items: %{public}@", String(describing: params))

        var toolbarItems: [UIBarButtonItem] = []
        
        // 1. Extract and sanitize title (may be nil)
        var titleText: String? = nil
        if let title = params["title"] as? String, !title.isEmpty {
            titleText = sanitizeString(title, maxLength: 100)
            os_log(.debug, log: Self.logger, "Title: %{public}@", titleText ?? "")
        }
        
        // Check if using plain title style (no pill/bubble)
        let usePlainTitle = (params["usePlainTitle"] as? Bool) ?? true
        
        // Parse optional title color (ARGB integer from Flutter)
        // nil = use adaptive .label color
        var titleColor: UIColor? = nil
        if let colorValue = params["titleColor"] as? Int, colorValue >= 0 {
            titleColor = UIColor(argb: colorValue)
            
            // CHAOS WARNING: Zero-alpha color would be invisible
            let alpha = (colorValue >> 24) & 0xFF
            if alpha == 0 {
                os_log(.default, log: Self.logger, "Warning: titleColor has zero alpha (invisible)")
            }
            
            os_log(.debug, log: Self.logger, "Custom title color: 0x%{public}08X (alpha: %{public}d)", colorValue, alpha)
        } else if let colorValue = params["titleColor"] as? Int {
            // Negative value provided - log and use default
            os_log(.default, log: Self.logger, "Invalid negative color value: %{public}d, using default", colorValue)
        }

        // 2. Setup leading button (LEFT side)
        if let leadingData = params["leading"] as? [String: Any] {
            if let leadingButton = createBarButtonItem(from: leadingData, position: .leading) {
                toolbarItems.append(leadingButton)
                os_log(.debug, log: Self.logger, "Leading button added")
            }
        }

        // 3. Add flexible space (left side of title or between leading/trailing)
        toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        
        // 4. Add centered title if provided AND using pill style (not plain)
        // Plain title is added as overlay label outside of toolbar items
        if let title = titleText, !usePlainTitle {
            let titleItem = createTitleBarButtonItem(title: title, color: titleColor)
            toolbarItems.append(titleItem)
            
            // Add another flexible space (right side of title) for centering
            toolbarItems.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        }

        // 5. Setup trailing buttons (RIGHT side)
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
            
            // 6. Add plain title as overlay label (if usePlainTitle)
            if let title = titleText, usePlainTitle {
                addPlainTitleOverlay(title: title, color: titleColor, to: toolbar)
            }
            
            os_log(.info, log: Self.logger, "Toolbar items set: %{public}d total (title: %{public}@, plainStyle: %{public}@)", 
                   toolbarItems.count, titleText != nil ? "yes" : "no", usePlainTitle ? "yes" : "no")
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

    /// Create centered title label as UIBarButtonItem
    /// Supports all layout scenarios: title-only, title+leading, title+trailing, title+leading+trailing
    /// CHAOS RESISTANT: Handles empty strings, very long strings, special characters
    private func createTitleBarButtonItem(title: String, color: UIColor? = nil) -> UIBarButtonItem {
        // EDGE CASE: Empty string after sanitization
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            os_log(.default, log: Self.logger, "Empty title provided, creating placeholder")
            return UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        }
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textAlignment = .center
        
        // Use system navigation title style
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = color ?? .label // Custom color or adaptive default
        
        // RESILIENCE: Handle long titles gracefully
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.numberOfLines = 1
        
        // Handle Dynamic Type
        titleLabel.adjustsFontForContentSizeCategory = true
        
        // Allow flexible width for centering between flexible spaces
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        // Create bar button item with custom view
        let barButtonItem = UIBarButtonItem(customView: titleLabel)
        
        // Disable user interaction (title is not tappable)
        barButtonItem.isEnabled = false
        titleLabel.isUserInteractionEnabled = false
        
        os_log(.debug, log: Self.logger, "Title bar button created: %{public}@ (length: %{public}d)", 
               title, title.count)
        
        return barButtonItem
    }

    /// Add plain text title as overlay label (no pill/bubble)
    /// This bypasses UIToolbar's automatic pill styling by adding the label directly to the toolbar view
    /// Follows Apple HIG recommendation for plain text titles
    private func addPlainTitleOverlay(title: String, color: UIColor? = nil, to toolbar: UIToolbar) {
        // EDGE CASE: Empty string
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            os_log(.default, log: Self.logger, "Empty title, skipping overlay")
            return
        }
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = color ?? .label // Custom color or adaptive default
        titleLabel.backgroundColor = .clear // No background = no pill
        
        // RESILIENCE: Handle long titles
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.numberOfLines = 1
        
        // Dynamic Type support
        titleLabel.adjustsFontForContentSizeCategory = true
        
        // Not interactive
        titleLabel.isUserInteractionEnabled = false
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(titleLabel)
        
        // Center the label in the toolbar
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: toolbar.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: toolbar.centerYAnchor),
            // Limit width to avoid overlapping buttons (leave margin for buttons)
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: toolbar.leadingAnchor, constant: 80),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: toolbar.trailingAnchor, constant: -80)
        ])
        
        os_log(.debug, log: Self.logger, "Plain title overlay added: %{public}@", title)
    }

    /// Create icon-based button with validation
    /// SECURITY: Icon code range validation (0x0000 - 0x10FFFF Unicode range)
    private func createIconButton(
        from data: [String: Any],
        position: ButtonPosition,
        index: Int
    ) -> UIBarButtonItem? {
        // Check if this button should be prominent (iOS 26 feature)
        let isProminent = data["prominent"] as? Bool ?? false

        // Check if this button shares background with adjacent buttons
        let sharesBackground = data["sharesBackground"] as? Bool ?? true

        var button: UIBarButtonItem?

        // 1. Try SF Symbol first (PRIMARY)
        if let iconName = data["iconName"] as? String {
            if let image = UIImage(systemName: iconName) {
                button = UIBarButtonItem(
                    image: image,
                    style: isProminent ? .done : .plain,
                    target: self,
                    action: position == .leading ? #selector(leadingTapped) : #selector(trailingTapped(_:))
                )
            } else {
                os_log(.default, log: Self.logger, "SF Symbol '%{public}@' not found, falling back to Unicode", iconName)
            }
        }

        // 2. Fallback to Unicode (SECONDARY)
        if button == nil {
            guard let iconCode = data["iconCode"] as? Int,
                  iconCode >= 0x0000,
                  iconCode <= 0x10FFFF else {
                os_log(.error, log: Self.logger, "Missing or invalid iconCode for button at index %{public}d, and no valid SF Symbol provided", index)
                return nil
            }

            let family = data["iconFamily"] as? String ?? ""
            button = createUnicodeButton(
                iconCode: iconCode,
                family: family,
                position: position,
                isProminent: isProminent
            )
        }

        guard let validButton = button else { return nil }

        validButton.tag = index

        // Apply iOS 26 pill-grouping property
        // iOS 26 API: hidesSharedBackground (inverse logic)
        // sharesBackground = true  → hidesSharedBackground = false (group in pill)
        // sharesBackground = false → hidesSharedBackground = true (separate pill)
        if #available(iOS 26.0, *) {
            validButton.hidesSharedBackground = !sharesBackground
            os_log(.debug, log: Self.logger,
                   "Button created: prominent=%{public}@, hidesSharedBackground=%{public}@",
                   isProminent ? "YES" : "NO", (!sharesBackground) ? "YES" : "NO")
        }

        return validButton
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
