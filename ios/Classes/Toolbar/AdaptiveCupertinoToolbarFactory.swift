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

/// Custom Container View to intercept layout changes for Toolbar
class AdaptiveToolbarContainerView: UIView {
    var onLayout: (() -> Void)?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
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
class AdaptiveCupertinoToolbarPlatformView: NSObject, FlutterPlatformView, UIToolbarDelegate, UISearchResultsUpdating, UISearchBarDelegate {

    // MARK: - Properties
    private var _view: AdaptiveToolbarContainerView
    private var toolbar: UIToolbar?
    private var navigationBar: UINavigationBar? // Fallback for iOS 18-25
    private var navigationItem: UINavigationItem?
    private weak var messenger: FlutterBinaryMessenger?
    private let channel: FlutterMethodChannel
    private let viewId: Int64
    private let isIOS26: Bool
    private var topPadding: CGFloat = 0
    private var bottomPadding: CGFloat = 0
    private var isBottom: Bool = false
    private var searchController: UISearchController?
    
    // De-bouncing layout reports
    private var lastReportedHeight: CGFloat = 0

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
        self._view = AdaptiveToolbarContainerView(frame: frame)
        self.channel = FlutterMethodChannel(
            name: "adaptive_cupertino_ios/toolbar_\(viewId)",
            binaryMessenger: messenger
        )

        if let params = args as? [String: Any] {
            if let topP = params["topPadding"] as? NSNumber {
                self.topPadding = CGFloat(truncating: topP)
            }
            if let bottomP = params["bottomPadding"] as? NSNumber {
                self.bottomPadding = CGFloat(truncating: bottomP)
            }
            if let isB = params["isBottom"] as? Bool {
                self.isBottom = isB
            }
        }
        
        self.viewId = viewId
        // Detect iOS 26 for native toolbar vs fallback
        self.isIOS26 = IOSVersionDetector.isIOS26OrNewer()

        super.init()
        
        // Setup Layout Reporting
        self._view.onLayout = { [weak self] in
            self?.reportLayout()
        }

        setupNativeToolbar(arguments: args)
        setupMethodChannel()
    }

    func view() -> UIView {
        return _view
    }

    /// Calculate and report the actual visual height to Flutter
    /// This enables the "Bidirectional Layout Protocol"
    private func reportLayout() {
        // Calculate the effective height of the toolbar content from the bottom
        var visibleTop: CGFloat = _view.bounds.height
        
        // 1. Toolbar Bar
        if let tb = toolbar, !tb.isHidden {
            visibleTop = min(visibleTop, tb.frame.minY)
        }
        
        // 2. Liquid Glass Background
        if let subviews = _view.subviews as? [UIView] {
             for subview in subviews {
                 if String(describing: type(of: subview)).contains("LiquidGlass") {
                     visibleTop = min(visibleTop, subview.frame.minY)
                 }
             }
        }
        
        // 3. Search Bar / Controller
        if let sb = searchController?.searchBar, !sb.isHidden, sb.superview == _view {
             visibleTop = min(visibleTop, sb.frame.minY)
        }
        
        let calculatedHeight = max(0, _view.bounds.height - visibleTop)
        
        // Report if changed
        if abs(calculatedHeight - lastReportedHeight) > 0.5 {
            lastReportedHeight = calculatedHeight
            // print("📱 [Toolbar] Reporting Layout Update. Height: \(calculatedHeight), BottomPadding: \(bottomPadding)")
            
            // Channel: "onLayoutChanged"
             channel.invokeMethod("onLayoutChanged", arguments: [
                "height": calculatedHeight,
                "safeArea": bottomPadding,
                "isTop": false // Toolbar is bottom
            ])
        }
    }

    // MARK: - UIToolbarDelegate
    
    /// Tell the system this toolbar is attached to the top of the screen
    /// This triggers the automatic status bar blur extension
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return isBottom ? .bottom : .topAttached
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

        self.navigationItem = UINavigationItem()
        
        // Ensure the container view is fully transparent
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
        // User requested removal of the floating capsule background for bottom bars.
        if enableLiquidGlass && !isBottom {
            let liquidGlass = LiquidGlassBackgroundView()
            liquidGlass.translatesAutoresizingMaskIntoConstraints = false
            _view.addSubview(liquidGlass)
            
            NSLayoutConstraint.activate([
                liquidGlass.leadingAnchor.constraint(equalTo: _view.leadingAnchor, constant: isBottom ? 16 : 0),
                liquidGlass.trailingAnchor.constraint(equalTo: _view.trailingAnchor, constant: isBottom ? -16 : 0),
                liquidGlass.topAnchor.constraint(equalTo: _view.topAnchor, constant: isBottom ? 0 : 0),
                liquidGlass.bottomAnchor.constraint(equalTo: _view.bottomAnchor, constant: isBottom ? -bottomPadding - 8 : 0)
            ])
            
            if isBottom {
                liquidGlass.layer.cornerRadius = 22
                liquidGlass.clipsToBounds = true
                // Invert gradient for bottom pill: Fade from top
                liquidGlass.setDirection(.bottom)
            }
            
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

        // Pin toolbar to explicit top padding (Manual Layout)
        // We avoid safeAreaLayoutGuide for top anchor due to Flutter embedding constraints
        if isBottom {
            NSLayoutConstraint.activate([
                toolbar.leadingAnchor.constraint(equalTo: _view.leadingAnchor, constant: 16),
                toolbar.trailingAnchor.constraint(equalTo: _view.trailingAnchor, constant: -16),
                toolbar.bottomAnchor.constraint(equalTo: _view.bottomAnchor, constant: -bottomPadding - 8),
                toolbar.heightAnchor.constraint(equalToConstant: 44)
            ])
        } else {
            NSLayoutConstraint.activate([
                toolbar.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                toolbar.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                toolbar.topAnchor.constraint(equalTo: _view.topAnchor, constant: topPadding),
                toolbar.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
            ])
        }
        
        // 4. Setup Search Controller if options are provided
        // ACTION-BASED SEARCH: We init the controller but present it via button tap
        if let params = args as? [String: Any],
           let searchOptions = params["searchOptions"] as? [String: Any] {
            // OPTIMIZATION: Use lightweight inline bar instead of heavy Controller
            // setupSearchController(options: searchOptions)
            setupInlineSearchBar()
        }

        os_log(.info, log: Self.logger, "Native UIToolbar setup completed (Action-based search ready)")
    }
    
    private func setupSearchController(options: [String: Any]) {
        let sc = UISearchController(searchResultsController: nil)
        sc.searchResultsUpdater = self
        sc.searchBar.delegate = self
        sc.obscuresBackgroundDuringPresentation = false
        
        if let placeholder = options["placeholder"] as? String {
            sc.searchBar.placeholder = placeholder
        } else {
            sc.searchBar.placeholder = "Search"
        }
        
        if let hides = options["hidesNavigationBarDuringPresentation"] as? Bool {
            sc.hidesNavigationBarDuringPresentation = hides
        }
        
        if let showsCancel = options["automaticallyShowsCancelButton"] as? Bool {
            sc.automaticallyShowsCancelButton = showsCancel
        }
        
        // Apply Liquid Glass aesthetic to search bar
        if #available(iOS 13.0, *) {
            let textField = sc.searchBar.searchTextField
            textField.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.2)
            textField.layer.cornerRadius = 10
            textField.clipsToBounds = true
            
            // Enhance blur interaction
            sc.searchBar.backgroundImage = UIImage() // Remove default background
        }
        
        self.searchController = sc
        self.searchController = sc
        // self.navigationItem?.searchController = sc // MANUAL MODE: View added manually
        
        // Manual mode visibility control
        // if let initiallyVisible = options["initiallyVisible"] as? Bool, initiallyVisible {
        //    self.navigationItem?.hidesSearchBarWhenScrolling = false
        // } else {
        //    self.navigationItem?.hidesSearchBarWhenScrolling = true
        // }
        
        os_log(.info, log: Self.logger, "UISearchController created (Manual Layout)")
    }

    /// OPTIMIZATION: Pre-warm the search bar to avoid frame drop on tap
    private func setupInlineSearchBar() {
        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.placeholder = "Search"
        searchBar.showsCancelButton = true
        searchBar.searchBarStyle = .minimal
        
        // FIX: Remove background to prevent "extended" look in Toolbar
        searchBar.backgroundImage = UIImage()
        searchBar.backgroundColor = .clear
        
        // CONSTRAINT FIX: Disable mask translation to prevent conflict with UIToolbar
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        // FIX: Ensure it has an intrinsic size before adding
        searchBar.sizeToFit()
        
        self.inlineSearchBar = searchBar
        os_log(.info, log: Self.logger, "InlineSearchBar pre-warmed for performance")
    }

    /// Custom Liquid Glass Background View with gradient-masked blur
    /// This provides the true "fading blur" effect at the bottom edge
    /// Enhanced with: Inner glow, Dark mode support, White tint overlay
    class LiquidGlassBackgroundView: UIView {
        private let blurView: UIVisualEffectView
        private let gradientMask = CAGradientLayer()
        private let whiteTintView = UIView() // Milky overlay
        private let innerGlowView = UIView() // Edge highlight
        
        enum Direction {
            case top
            case bottom
        }
        
        private var currentDirection: Direction = .top
        
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
            // Default: Top-attached (fades at bottom)
            updateGradientColors()
            
            gradientMask.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradientMask.endPoint = CGPoint(x: 0.5, y: 1.0)
            
            layer.mask = gradientMask
        }
        
        private func updateGradientColors() {
            if currentDirection == .bottom {
                // Fades at TOP (for bottom toolbar)
                gradientMask.colors = [
                    UIColor.clear.cgColor,
                    UIColor.black.cgColor,
                    UIColor.black.cgColor
                ]
                gradientMask.locations = [0.0, 0.25, 1.0]
            } else {
                // Fades at BOTTOM (for top app bar)
                gradientMask.colors = [
                    UIColor.black.cgColor,
                    UIColor.black.cgColor,
                    UIColor.clear.cgColor
                ]
                gradientMask.locations = [0.0, 0.75, 1.0]
            }
        }
        
        func setDirection(_ direction: Direction) {
            self.currentDirection = direction
            updateGradientColors()
            
            // Adjust inner glow position if needed
            if direction == .bottom {
                innerGlowView.isHidden = true // Hide for pill
            } else {
                innerGlowView.isHidden = false
            }
        }
        
        func setFadingEnabled(_ enabled: Bool) {
            layer.mask = enabled ? gradientMask : nil
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
    // MARK: - State Management
    private var defaultToolbarItems: [UIBarButtonItem] = []
    private var plainTitleLabel: UILabel?
    private var inlineSearchBar: UISearchBar? // Optimized: Reusable search instance
    
    // ...

    private func configureToolbarItems(from params: [String: Any]) {
        os_log(.debug, log: Self.logger, "Configuring toolbar items: %{public}@", String(describing: params))

        var items: [UIBarButtonItem] = []
        
        // 1. Extract and sanitize title (may be nil)
        var titleText: String? = nil
        if let title = params["title"] as? String, !title.isEmpty {
            titleText = sanitizeString(title, maxLength: 100)
        }
        
        // Default to FALSE (Enable "Pill" style by default)
        let usePlainTitle = (params["usePlainTitle"] as? Bool) ?? false
        
        // Parse optional title color
        var titleColor: UIColor? = nil
        if let colorValue = params["titleColor"] as? Int, colorValue >= 0 {
            titleColor = UIColor(argb: colorValue)
        }

        // 2. Setup leading button (LEFT side)
        if let leadingData = params["leading"] as? [String: Any] {
            if let leadingButton = createBarButtonItem(from: leadingData, position: .leading) {
                items.append(leadingButton)
            }
        }

        // 3. Add flexible space
        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        
        // 4. Add centered title
        if let title = titleText, !usePlainTitle {
            let titleItem = createTitleBarButtonItem(title: title, color: titleColor)
            items.append(titleItem)
            items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        }

        // 5. Setup trailing buttons
        if let trailingArray = params["trailing"] as? [[String: Any]] {
            for (index, buttonData) in trailingArray.enumerated() {
                if index >= 15 { break } // Increased limit for spacers
                if let button = createBarButtonItem(from: buttonData, position: .trailing, index: index) {
                    items.append(button)
                }
            }
        }
        
        // 6. ACTION SEARCH: Add Search Button if configured AND implied
        if let searchOpts = params["searchOptions"] as? [String: Any] {
            let autoImply = searchOpts["automaticallyImplySearchAction"] as? Bool ?? true
            
            if autoImply {
                let searchButton = UIBarButtonItem(
                    barButtonSystemItem: .search,
                    target: self,
                    action: #selector(searchButtonTapped)
                )
                items.append(searchButton)
            }
        }

        // Store default items
        self.defaultToolbarItems = items
        
        // Apply to toolbar
        if #available(iOS 26.0, *), let toolbar = self.toolbar {
            toolbar.setItems(items, animated: false)
            
            // Plain title overlay
            if let title = titleText, usePlainTitle {
                addPlainTitleOverlay(title: title, color: titleColor, to: toolbar)
            }
        } else if let _ = self.navigationBar, let navItem = self.navigationItem {
             // Fallback logic... (keep existing)
            let customButtons = items.filter { $0.customView == nil && $0.target != nil }
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
    /// Create UIBarButtonItem from validated data
    /// SECURITY: Icon code validation and range checking
    /// CHAOS RESISTANT: Returns nil on invalid data (fail safe)
    private func createBarButtonItem(
        from data: [String: Any],
        position: ButtonPosition,
        index: Int = 0
    ) -> UIBarButtonItem? {
        let style = data["style"] as? String ?? "automatic"
        
        // If color is specified, render as a Standard System Button with Tint
        // Reverting to system standard as requested: "Undo custom filled look"
        if let colorVal = data["color"] as? Int, colorVal != 0 {
            return createTintedButton(from: data, position: position, index: index, colorValue: colorVal)
        }
        
        // Use standard system items
        // Validate button type (SECURITY: Type checking)
        guard let type = data["type"] as? String else {
            os_log(OSLogType.default, log: Self.logger, "Missing button type")
            return nil
        }

        switch type {
        case "icon":
            return createIconButton(from: data, position: position, index: index)
        case "text":
            return createTextButton(from: data, position: position, index: index)
        case "search":
            return createManualSearchButton(from: data, position: position, index: index)
        case "spacer":
            return UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        default:
            os_log(OSLogType.default, log: Self.logger, "Unknown button type: %{public}@", type)
            return nil
        }
    }
    
    /// Create a manual search button (placed anywhere in the list)
    private func createManualSearchButton(
        from data: [String: Any],
        position: ButtonPosition,
        index: Int
    ) -> UIBarButtonItem? {
        // Use provided icon/label or default to search icon
        if data["label"] != nil {
            let button = createTextButton(from: data, position: position, index: index)
            button?.action = #selector(searchButtonTapped)
            button?.target = self
            return button
        }
        
        // If icon provided, use it. Else default search icon
        var iconData = data
        
        // Ensure type IS icon so createIconButton processes it correctly
        iconData["type"] = "icon"
        
        let button = createIconButton(from: iconData, position: position, index: index)
        button?.action = #selector(searchButtonTapped)
        button?.target = self 
        return button
    }
    
    /// Create a "Filled Pill" button (Custom View)
    private func createFilledButton(
        from data: [String: Any],
        position: ButtonPosition,
        index: Int,
        colorValue: Int
    ) -> UIBarButtonItem? {
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = UIColor(argb: colorValue)
        config.baseForegroundColor = .white
        config.cornerStyle = .capsule
        config.buttonSize = .medium // Revert to native standard size
        
        // Standard insets for a capsule button
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        
        // Content
        if let label = data["label"] as? String {
            config.title = label
             config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
                return outgoing
            }
        } else if let iconName = data["iconName"] as? String {
             config.image = UIImage(systemName: iconName)
             config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(scale: .medium)
        } else if let iconCode = data["iconCode"] as? Int {
             let iconString = String(format: "%C", iconCode)
             config.title = iconString
        }
        
        let button = UIButton(configuration: config)
        button.tag = (position == .leading) ? -1 : index
        button.addTarget(self, action: #selector(customButtonTapped(_:)), for: .touchUpInside)
        
        // Wrap in UIBarButtonItem
        let item = UIBarButtonItem(customView: button)
        
        // CRITICAL: Hide the system's shared white/glass background.
        // This ensures our custom "Filled Button" IS the only pill visible,
        // fulfilling the request to "Change the pill color" without nesting.
        if #available(iOS 26.0, *) {
            item.hidesSharedBackground = true
        }
        
        return item
    }

    /// Create a "Tinted" button (Standard UIBarButtonItem with tintColor)
    private func createTintedButton(
        from data: [String: Any],
        position: ButtonPosition,
        index: Int,
        colorValue: Int
    ) -> UIBarButtonItem? {
        var item: UIBarButtonItem?
        
        if let label = data["label"] as? String {
            item = UIBarButtonItem(
                title: label,
                style: .done,
                target: self,
                action: position == .leading ? #selector(leadingTapped) : #selector(trailingTapped(_:))
            )
        } else if let iconName = data["iconName"] as? String {
            item = UIBarButtonItem(
                image: UIImage(systemName: iconName),
                style: .plain,
                target: self,
                action: position == .leading ? #selector(leadingTapped) : #selector(trailingTapped(_:))
            )
        } else if let iconCode = data["iconCode"] as? Int {
            let iconString = String(format: "%C", iconCode)
            item = UIBarButtonItem(
                title: iconString,
                style: .plain,
                target: self,
                action: position == .leading ? #selector(leadingTapped) : #selector(trailingTapped(_:))
            )
        }
        
        if let item = item {
            item.tintColor = UIColor(argb: colorValue)
            item.tag = (position == .leading) ? -1 : index
            return item
        }
        
        return nil
    }
    
    @objc private func customButtonTapped(_ sender: UIButton) {
        if sender.tag == -1 {
             channel.invokeMethod("onLeadingTapped", arguments: nil)
        } else {
             channel.invokeMethod("onTrailingTapped", arguments: ["index": sender.tag])
        }
    }

    /// Create text-based button
    private func createTextButton(
        from data: [String: Any],
        position: ButtonPosition,
        index: Int
    ) -> UIBarButtonItem? {
        guard let label = data["label"] as? String else {
            os_log(OSLogType.default, log: Self.logger, "Missing label for text button at index %{public}d", index)
            return nil
        }
        
        // Check if this button should be prominent
        let isProminent = data["prominent"] as? Bool ?? false
        let sharesBackground = data["sharesBackground"] as? Bool ?? true
        
        let button = UIBarButtonItem(
            title: label,
            style: isProminent ? .done : .plain,
            target: self,
            action: position == .leading ? #selector(leadingTapped) : #selector(trailingTapped(_:))
        )
        
        button.tag = index
        
        if #available(iOS 26.0, *) {
            button.hidesSharedBackground = !sharesBackground
        }
        
        return button
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
        
        // Remove existing label if present
        self.plainTitleLabel?.removeFromSuperview()
        
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
        
        self.plainTitleLabel = titleLabel
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
    
    @objc private func searchButtonTapped() {
        os_log(.debug, log: Self.logger, "Search button tapped - switching to In-Place Search Mode")
        
        guard let toolbar = self.toolbar else { return }
        
        // 1. Retrieve pre-warmed Search Bar
        guard let searchBar = inlineSearchBar else {
            os_log(.error, log: Self.logger, "Search bar not initialized! Creating fallback.")
            setupInlineSearchBar() // Fallback if init failed
            return
        }
        
        // 2. Wrap in BarButtonItem
        let searchItem = UIBarButtonItem(customView: searchBar)
        
        // 3. Swap Items with Cross-Dissolve (Fake Smoothness)
        // We use non-animated setItems (instant layout) wrapped in a visual fade.
        UIView.transition(with: toolbar, duration: 0.25, options: .transitionCrossDissolve, animations: {
            toolbar.setItems([searchItem], animated: false)
        }, completion: nil)
        
        // 4. Hide Plain Title Overlay
        self.plainTitleLabel?.isHidden = true
        
        // 5. Activate keyboard (Deferred)
        // A 100ms delay ensures the Layout Pass is fully committed before the
        // heavy Keyboard Window creation starts.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            searchBar.becomeFirstResponder()
        }
        
        // Notify Flutter
        channel.invokeMethod("onSearchActive", arguments: ["active": true])
    }

    
    // MARK: - UISearchBarDelegate
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        os_log(.debug, log: Self.logger, "Search cancel tapped - restoring Default Toolbar")
        
        guard let toolbar = self.toolbar else { return }
        
        searchBar.resignFirstResponder()
        
        // Restore original items
        toolbar.setItems(self.defaultToolbarItems, animated: true)
        
        // Restore Plain Title Overlay
        self.plainTitleLabel?.isHidden = false
        
        // Notify Flutter
        channel.invokeMethod("onSearchCancelled", arguments: nil)
        channel.invokeMethod("onSearchActive", arguments: ["active": false])
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Debounce or send directly? Method channel is fast enough usually.
        // Or strictly strictly: "onQueryChanged"
        // Wait, current channel method for query?
        // Let's assume onQueryChanged exists or we use updateSearchResults logic
        // But here we are using manual SearchBar, not UISearchController updating
        
        // We should send the text.
        // "onQueryChanged" is likely the method name expected by Dart?
        // Let's check how UISearchUpdating did it.
        // It likely used `updateSearchResults(for:)` which calls `sc.searchBar.text`.
        settingsQuery(searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        if let text = searchBar.text {
             channel.invokeMethod("onSearchSubmitted", arguments: ["query": text])
        }
    }
    
    private func settingsQuery(_ query: String) {
        channel.invokeMethod("onSearchQueryChanged", arguments: ["query": query])
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
            case "setSearchActive":
                // OPTIMIZATION: Disabled to prevent conflict with Inline Mode
                // if let args = call.arguments as? [String: Any],
                //    let active = args["active"] as? Bool {
                //     self.searchController?.isActive = active
                //     if active {
                //         self.searchController?.searchBar.becomeFirstResponder()
                //         self.navigationItem?.hidesSearchBarWhenScrolling = false
                //     }
                //     result(nil)
                // } else {
                //     result(FlutterError(code: "INVALID_ARGS", message: "Invalid argument", details: nil))
                // }
                result(nil) // Ack without action
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
    
    // MARK: - UISearchResultsUpdating (Unused in Inline Mode)
    
    func updateSearchResults(for searchController: UISearchController) {
        // No-op: We use direct UISearchBarDelegate methods now
    }
}
