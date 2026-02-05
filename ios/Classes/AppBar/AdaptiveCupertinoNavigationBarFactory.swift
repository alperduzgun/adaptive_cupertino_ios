import Flutter
import UIKit
import os.log

/// Platform View Factory for Adaptive Cupertino Navigation Bar
///
/// Renamed from "AppBar" to match UIKit terminology (UINavigationBar).
@available(iOS 15.0, *)
class AdaptiveCupertinoNavigationBarFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private var registrar: FlutterPluginRegistrar

    init(messenger: FlutterBinaryMessenger, registrar: FlutterPluginRegistrar) {
        self.messenger = messenger
        self.registrar = registrar
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
            binaryMessenger: messenger,
            registrar: registrar
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
/// Custom Container View to intercept layout changes
class AdaptiveNavBarContainerView: UIView {
    var onLayout: (() -> Void)?
    weak var pillBoundView: UIView? // Reference to the glass capsule
    
    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // 1. If we have a pill view, and the touch is outside it, pass through immediately.
        if let pill = pillBoundView {
            let pointInPill = convert(point, to: pill)
            if !pill.point(inside: pointInPill, with: nil) {
                return nil
            }
        }
        
        // 2. Otherwise, check children.
        let view = super.hitTest(point, with: event)
        
        // 3. If we hit the container itself or the decorative glass, pass through.
        // We only want to "catch" the hit if it's a real control (button, search bar).
        if view == self || view is AdaptiveGlassView || view is GlassContainerView {
            return nil
        }
        
        return view
    }
}

/// Platform View wrapper for UINavigationBar
///
/// CHAOS ENGINEERING:
/// - iOS 26+ support with strict runtime checks
/// - Liquid Glass fallback for iOS 18-25
/// - Standard fallback for older versions
@available(iOS 15.0, *)
class AdaptiveCupertinoNavigationBarPlatformView: NSObject, FlutterPlatformView, UINavigationBarDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    private var _view: AdaptiveNavBarContainerView
    private var navigationBar: UINavigationBar!
    private var navigationItem: UINavigationItem!
    private var messenger: FlutterBinaryMessenger
    private let registrar: FlutterPluginRegistrar
    private let fontLoader: FlutterFontLoader
    private let channel: FlutterMethodChannel
    private var topPadding: CGFloat = 0
    private var searchController: UISearchController?
    private var glassBackingView: UIView?
    private var glassEffectID: String?
    
    // De-bouncing layout reports
    private var lastReportedHeight: CGFloat = 0
    
    // STRICT RUNTIME CHECK
    private let isIOS26: Bool
    
    // Constraints for fluid minimization
    private var glassLeadingConstraint: NSLayoutConstraint?
    private var glassTrailingConstraint: NSLayoutConstraint?
    private var glassTopConstraint: NSLayoutConstraint?
    private var glassBottomConstraint: NSLayoutConstraint?
    private var glassBottomPadding: CGFloat = 0

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger,
        registrar: FlutterPluginRegistrar
    ) {
        self.messenger = messenger
        self.registrar = registrar
        self.fontLoader = FlutterFontLoader(registrar: registrar)
        self._view = AdaptiveNavBarContainerView(frame: frame)
        self.channel = FlutterMethodChannel(
            name: "adaptive_cupertino_ios/app_bar_\(viewId)",
            binaryMessenger: messenger
        )
        self.isIOS26 = IOSVersionDetector.isIOS26OrNewer()

        // Parse top padding from Dart
        if let params = args as? [String: Any], let padding = params["topPadding"] as? NSNumber {
            let p = CGFloat(truncating: padding)
            self.topPadding = p.isNaN || p.isInfinite ? 0 : p
        }

        super.init()
        
        // Setup Layout Reporting
        self._view.onLayout = { [weak self] in
            self?.reportLayout()
        }

        setupNavigationBar(arguments: args)
        setupMethodChannel()
    }

    func view() -> UIView {
        return _view
    }
    
    /// Calculate and report the actual visual height to Flutter
    /// This enables the "Bidirectional Layout Protocol"
    private func reportLayout() {
        // Calculate the bottom-most edge of our visible content
        var maxY: CGFloat = 0
        
        // 1. Navigation Bar
        if !navigationBar.isHidden {
            maxY = max(maxY, navigationBar.frame.maxY)
        }
        
        // 2. Search Bar (if manual)
        if let sb = searchController?.searchBar, !sb.isHidden, sb.superview == _view {
             maxY = max(maxY, sb.frame.maxY)
        }
        
        // 3. Fallback to view height if subviews are weird, but usually subviews drive the visual obstruction
        // Actually, for "Liquid Glass", we want the visual height of the bar area.
        
        // If the calculated height is significantly different from last report, send it.
        // Use a small epsilon to avoid float jitter loops
        // CHAOS SAFETY: Prevent NaN reporting which can break Flutter's layout engine
        if !maxY.isNaN && !maxY.isInfinite && abs(maxY - lastReportedHeight) > 0.5 {
            lastReportedHeight = maxY
            
            print("📱 [AppBar] Reported layout height: \(maxY)")
            
            channel.invokeMethod("onLayoutChanged", arguments: ["height": maxY, "safeArea": topPadding])
        }
    }

    // MARK: - UINavigationBarDelegate
    
    /// Tell the system this bar is attached to the top of the screen
    /// This triggers the automatic status bar blur extension "Liquid Glass logic"
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }

    private func setupNavigationBar(arguments args: Any?) {
        if let params = args as? [String: Any], let effectID = params["glassEffectID"] as? String {
            self.glassEffectID = effectID
        }
        
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

        // Check for search options to determine layout strategy
        var hasSearch = false
        var searchOptions: [String: Any]?
        if let params = args as? [String: Any], let opts = params["searchOptions"] as? [String: Any] {
            hasSearch = true
            searchOptions = opts
        }

        navigationBar.items = [navigationItem]
        _view.addSubview(navigationBar)
        
        // Apply effect ID to glass backing if available
        if #available(iOS 15.0, *), let effectID = self.glassEffectID {
             // Find the glass view (it's inserted at index 0 in setupBackgroundBlur)
             if let glassView = _view.subviews.first(where: { $0 is AdaptiveGlassView }) as? AdaptiveGlassView {
                 // Forward the effectID to the underlying UIVisualEffect
                 // We need to reach into the internal UIVisualEffectView
                 for sub in glassView.subviews {
                     if let blur = sub as? UIVisualEffectView, let effect = blur.effect {
                         if effect.responds(to: NSSelectorFromString("setEffectID:")) {
                             effect.setValue(effectID, forKey: "effectID")
                         }
                     }
                 }
             }
        }

        // Ensure z-order is correct: NavigationBar on top of blur
        _view.bringSubviewToFront(navigationBar)

        if hasSearch {
            // COMPOSITE LAYOUT: Manually place NavBar and SearchBar
            print("📱 [AppBar] Mode: Composite (NavBar + Explicit SearchBar)")
            
            // 1. Setup Search Controller & Bar
            setupSearchController(options: searchOptions!)
            
            guard let searchBar = searchController?.searchBar else { return }
            searchBar.translatesAutoresizingMaskIntoConstraints = false
            _view.addSubview(searchBar)
            
            // 2. Constraints for NavBar (PINNED to top and searchBar top)
            NSLayoutConstraint.activate([
                navigationBar.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                navigationBar.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                navigationBar.topAnchor.constraint(equalTo: _view.topAnchor, constant: topPadding),
                navigationBar.bottomAnchor.constraint(equalTo: searchBar.topAnchor)
            ])
            
            // 3. Constraints for SearchBar (Pinned to bottom of _view)
            NSLayoutConstraint.activate([
                searchBar.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                searchBar.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                searchBar.heightAnchor.constraint(equalToConstant: 52.0),
                searchBar.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
            ])
            
        } else {
            // STANDARD LAYOUT: Navbar fills the space
            print("📱 [AppBar] Mode: Standard")
            
            NSLayoutConstraint.activate([
                navigationBar.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                navigationBar.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                navigationBar.topAnchor.constraint(equalTo: _view.topAnchor, constant: topPadding),
                navigationBar.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
            ])
        }

        // Parse remaining configuration (Title, Buttons)
        if let params = args as? [String: Any] {
            configureFromParams(params)
        }
    }

    private func setupBackgroundBlur() {
        // Use the shared AdaptiveGlassView for "True iOS 26" detached capsule architecture.
        // We apply horizontal and vertical insets to achieve the "floating" effect.
        if #available(iOS 26.0, *) {
            // TRUE iOS 26: Adopt the system's native background effect if possible.
            // But IF we want the "Detached" look, we still use the polyfill even on iOS 26.
            // Only stop if we are doing a "Classic" attached bar.
            
            // For now, let's keep the high-fidelity polyfill for the DETACHED look, 
            // but ensure it's safe.
        }

        // Otherwise (Detached mode OR Legacy 18-25):
        // Manual Glass Injection for the "Capsule" or "Polyfill" look
        let glassView = AdaptiveGlassView(frame: .zero, isInteractive: false, variant: 2, applyGeometry: true)
        glassView.translatesAutoresizingMaskIntoConstraints = false
        _view.insertSubview(glassView, at: 0)
        self.glassBackingView = glassView
        _view.pillBoundView = glassView

        // Force a specific background color for debugging visibility if needed
        // glassView.backgroundColor = UIColor.systemPink.withAlphaComponent(0.3) 

        if isIOS26 {
            // DETACHED CAPSULE: Floating away from edges (iOS 26 High-Fidelity)
            // Stricter margins (12pt) to ensure the floating effect is undeniable.
            let leading = glassView.leadingAnchor.constraint(equalTo: _view.leadingAnchor, constant: 12)
            let trailing = glassView.trailingAnchor.constraint(equalTo: _view.trailingAnchor, constant: -12)
            // CRITICAL FIX: Ensure the top constraint accounts for the status bar!
            // If topPadding is 0, it might be behind the Dynamic Island.
            // We pin to the top of the VIEW (which starts at 0), so topPadding is actually the safe area inset.
            let top = glassView.topAnchor.constraint(equalTo: _view.topAnchor, constant: topPadding > 20 ? topPadding : 54) // Ensure strictly below Island if no padding provided
            let bottom = glassView.bottomAnchor.constraint(equalTo: _view.bottomAnchor, constant: -4)
            
            self.glassLeadingConstraint = leading
            self.glassTrailingConstraint = trailing
            self.glassTopConstraint = top
            self.glassBottomConstraint = bottom
            
            NSLayoutConstraint.activate([leading, trailing, top, bottom])
            AdaptiveGlassHelper.configureModernGeometry(for: glassView, radius: 24)
        } else {
            // CLASSIC: Attached to edges (iOS 18 fallback style)
            NSLayoutConstraint.activate([
                glassView.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                glassView.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                glassView.topAnchor.constraint(equalTo: _view.topAnchor),
                glassView.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
            ])
            AdaptiveGlassHelper.configureModernGeometry(for: glassView, radius: 0)
        }
        
        // MODERN TRANSPARENCY: Use Appearance API for reliable glass backing
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        // Remove standard shadows and background images
        appearance.backgroundImage = UIImage()
        appearance.shadowImage = UIImage()
        
        navigationBar.standardAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        
        navigationBar.isTranslucent = true
        navigationBar.backgroundColor = .clear
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
        sc.searchBar.backgroundImage = UIImage() // Remove native box background
        sc.searchBar.backgroundColor = .clear
        
        if #available(iOS 13.0, *) {
            let textField = sc.searchBar.searchTextField
            textField.backgroundColor = .secondarySystemFill.withAlphaComponent(0.12)
            textField.layer.cornerRadius = 10
            textField.clipsToBounds = true
        }
        
        self.searchController = sc
        // self.navigationItem.searchController = sc // MANUAL MODE: We add view manually
        
        // Manual mode doesn't rely on hidesSearchBarWhenScrolling
        // We just ensure the searchBar is visible in setupNavigationBar
        
        print("📱 [AppBar-Search] UISearchController created (Manual Layout)")
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
        // CRITICAL FIX: If search is active, we MUST enable large titles on the bar
        // for the search bar to appear inline. We control the title size itself via largeTitleDisplayMode.
        let hasSearch = params["searchOptions"] != nil
        let wantsLargeTitle = params["largeTitle"] as? Bool ?? false
        
        if hasSearch || wantsLargeTitle {
            navigationBar.prefersLargeTitles = true
        } else {
            navigationBar.prefersLargeTitles = false
        }
        
        // Control actual title display
        if wantsLargeTitle {
            navigationItem.largeTitleDisplayMode = .always
        } else {
            navigationItem.largeTitleDisplayMode = .never
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
        
        // Force initial layout report
        _view.setNeedsLayout()
        _view.layoutIfNeeded()
        reportLayout()
    }

    private func createBarButtonItem(from data: [String: Any], isLeading: Bool, index: Int = 0) -> UIBarButtonItem? {
        guard let type = data["type"] as? String else { return nil }

        switch type {
        case "icon":
            // 1. Try SF Symbols first (if provided)
            if let iconName = data["iconName"] as? String,
               let image = UIImage(systemName: iconName) {
                var style: UIBarButtonItem.Style = .plain
                if #available(iOS 26.0, *), isIOS26 {
                    style = .prominent
                }
                
                let button = UIBarButtonItem(
                    image: image,
                    style: style,
                    target: self,
                    action: isLeading ? #selector(leadingTapped) : #selector(trailingTapped(_:))
                )
                
                if #available(iOS 26.0, *), isIOS26 {
                    button.hidesSharedBackground = true
                }
                
                button.tag = index
                return button
            }

            // 2. Fallback to Unicode via shared loader
            if let iconCode = data["iconCode"] as? Int {
                let iconString = String(UnicodeScalar(iconCode)!)
                var style: UIBarButtonItem.Style = .plain
                if #available(iOS 26.0, *), isIOS26 {
                    style = .prominent
                }
                
                let button = UIBarButtonItem(
                    title: iconString,
                    style: style,
                    target: self,
                    action: isLeading ? #selector(leadingTapped) : #selector(trailingTapped(_:))
                )
                
                if #available(iOS 26.0, *), isIOS26 {
                    button.hidesSharedBackground = true
                }
                
                button.tag = index

                // Resolve icon font using shared loader
                let family = data["iconFamily"] as? String ?? ""
                let iconPackage = data["iconPackage"] as? String
                
                if let font = fontLoader.loadFont(name: family, size: 24, package: iconPackage) {
                    let attributes: [NSAttributedString.Key: Any] = [.font: font]
                    button.setTitleTextAttributes(attributes, for: .normal)
                    button.setTitleTextAttributes(attributes, for: .highlighted)
                }

                return button
            }
            return nil

        case "search":
            let button = UIBarButtonItem(
                barButtonSystemItem: .search,
                target: self,
                action: #selector(searchButtonTapped)
            )
            
            if #available(iOS 26.0, *), isIOS26 {
                button.style = .prominent
                button.hidesSharedBackground = true
            }
            
            button.tag = index
            return button
            
        case "spacer":
            return UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

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
    
    @objc private func searchButtonTapped() {
        self.searchController?.isActive = true
        self.searchController?.searchBar.becomeFirstResponder()
        self.navigationItem.hidesSearchBarWhenScrolling = false
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
                
            case "setSearchActive":
                if let args = call.arguments as? [String: Any],
                   let active = args["active"] as? Bool {
                    self.searchController?.isActive = active
                    if active {
                        self.searchController?.searchBar.becomeFirstResponder()
                        self.navigationItem.hidesSearchBarWhenScrolling = false
                    }
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid argument", details: nil))
                }

            case "setMinimizationFactor":
                if let args = call.arguments as? [String: Any],
                   let factor = args["factor"] as? Double {
                    self.updateMinimization(factor: CGFloat(factor))
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid factor", details: nil))
                }

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func updateMinimization(factor: CGFloat) {
        // 1. Calculate the target state
        let threshold: CGFloat = 0.3
        let wantsLarge = factor < threshold
        
        // 2. Fluid Layout Calculations
        // As we scroll (factor increases from 0 to 1), we want to:
        // - Reduce margins from 16/8 to 0/0
        // - Reduce corner radius from 24 to 0
        let cappedFactor = max(0, min(1, factor))
        let horizontalMargin = 16 * (1 - cappedFactor)
        let verticalMargin = 8 * (1 - cappedFactor)
        let radius = 24 * (1 - cappedFactor)
        
        // 3. Apply state changes if needed
        let modeChanged = navigationBar.prefersLargeTitles != wantsLarge
        
        UIView.animate(withDuration: 0.2, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
            if modeChanged {
                self.navigationBar.prefersLargeTitles = wantsLarge
                self.navigationItem.largeTitleDisplayMode = wantsLarge ? .always : .never
            }
            
            // Fluid Geometry Scaling (Core of "Liquid" feel)
            if let glass = self._view.subviews.first(where: { $0 is AdaptiveGlassView }) as? AdaptiveGlassView {
                self.glassLeadingConstraint?.constant = horizontalMargin
                self.glassTrailingConstraint?.constant = -horizontalMargin
                self.glassTopConstraint?.constant = self.topPadding + verticalMargin
                self.glassBottomConstraint?.constant = -verticalMargin
                
                AdaptiveGlassHelper.configureModernGeometry(for: glass, radius: radius)
            }
            
            self.navigationBar.setNeedsLayout()
            self.navigationBar.layoutIfNeeded()
            self._view.layoutIfNeeded()
        }
        
        // 4. Fallback/Safety: Ensure reporting happens on manual factor updates too
        reportLayout()
    }
    
    // MARK: - UISearchResultsUpdating & UISearchBarDelegate
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        channel.invokeMethod("onSearchQueryChanged", arguments: ["query": text])
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text else { return }
        channel.invokeMethod("onSearchSubmitted", arguments: ["query": text])
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        channel.invokeMethod("onSearchCancelled", arguments: nil)
    }
}

