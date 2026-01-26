import Flutter
import UIKit

/// Custom container view that triggers layout pass after being added to window
/// This fixes the initial label truncation issue by ensuring layout happens after
/// the view has its correct frame from Flutter.
@available(iOS 15.0, *)
class TabBarContainerView: UIView {
    var tabBar: UITabBar?
    private var hasCompletedInitialLayout = false
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        completeInitialLayoutIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        completeInitialLayoutIfNeeded()
    }
    
    /// DRY: Single method for initial layout completion and fade-in
    /// Called from both didMoveToWindow and layoutSubviews as a safety net
    private func completeInitialLayoutIfNeeded() {
        // Guard: Only run once, when in window with valid bounds
        guard !hasCompletedInitialLayout,
              window != nil,
              bounds.width > 0 else { return }
        
        hasCompletedInitialLayout = true
        
        // Force synchronous layout
        CATransaction.flush()
        tabBar?.sizeToFit()
        tabBar?.setNeedsLayout()
        tabBar?.layoutIfNeeded()
        setNeedsLayout()
        layoutIfNeeded()
        
        // Fade in after layout is complete
        UIView.animate(withDuration: 0.15) { [weak self] in
            self?.tabBar?.alpha = 1.0
        }
        
        print("✅ [TabBar-Container] Initial layout completed and faded in")
    }
}

/// Platform View Factory for Adaptive Cupertino TabBar
///
/// Creates native iOS TabBar that can be embedded into Flutter's widget tree.
@available(iOS 15.0, *)
class AdaptiveCupertinoTabBarFactory: NSObject, FlutterPlatformViewFactory {
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
        print("🔍 [TabBar-Factory] Creating platform view")
        print("🔍 [TabBar-Factory] View ID: \(viewId)")
        print("🔍 [TabBar-Factory] Frame: \(frame)")
        print("🔍 [TabBar-Factory] Arguments: \(String(describing: args))")

        return AdaptiveCupertinoTabBarPlatformView(
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

/// Platform View wrapper for UITabBar with iOS 26+ enhancements
///
/// CHAOS ENGINEERING PRINCIPLES:
/// - Three-tier compatibility (iOS 26+ / iOS 18-25 / iOS <18)
/// - Fail-safe defaults
/// - Observable logging
/// - Anti-fragile architecture
@available(iOS 15.0, *)
class AdaptiveCupertinoTabBarPlatformView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var tabBar: UITabBar!
    private var shadowView: UIView!
    private var messenger: FlutterBinaryMessenger
    private var selectedIndex: Int = 0
    private let channel: FlutterMethodChannel

    // iOS 26 state tracking
    private var minimizeBehavior: Int = 3 // 0-3, default: 3 (automatic)
    private var isIOS26: Bool = false
    
    // Layout constraints for structural minimization
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    private var bottomConstraint: NSLayoutConstraint!
    private var topConstraint: NSLayoutConstraint!

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        print("🔍 [TabBar-View] Init started")
        self.messenger = messenger
        
        // Use custom container that triggers layout after window attachment
        let containerView = TabBarContainerView(frame: frame)
        containerView.clipsToBounds = false
        containerView.backgroundColor = .clear
        containerView.isOpaque = false
        self._view = containerView

        self.channel = FlutterMethodChannel(
            name: "adaptive_cupertino_ios/tab_bar_\(viewId)",
            binaryMessenger: messenger
        )

        // Detect iOS 26 for feature switching
        self.isIOS26 = IOSVersionDetector.isIOS26OrNewer()
        print("🔍 [TabBar-View] iOS 26 detected: \(self.isIOS26)")

        super.init()

        print("🔍 [TabBar-View] Setting up TabBar...")
        setupTabBar(arguments: args)
        setupMethodChannel()
        print("🔍 [TabBar-View] Init complete")
    }

    func view() -> UIView {
        return _view
    }

    private func setupTabBar(arguments args: Any?) {
        print("🔍 [TabBar-Setup] Creating native UITabBar")

        // Create shadow container (placed behind tabBar)
        shadowView = UIView()
        shadowView.backgroundColor = .clear
        shadowView.translatesAutoresizingMaskIntoConstraints = false
        _view.addSubview(shadowView)

        // Create native UITabBar
        tabBar = UITabBar()
        tabBar.delegate = self
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        _view.addSubview(tabBar)

        // Clear native UITabBar shadow and background images to prevent standard box shadows
        tabBar.shadowImage = UIImage()
        tabBar.backgroundImage = UIImage()

        // Setup appearance based on iOS version
        // CHAOS: Three-tier fallback strategy with compile-time + runtime checks
        if #available(iOS 26.0, *), isIOS26 {
            // iOS 26+: Direct properties (bypass UITabBarAppearance)
            // Double check: Compile-time (#available) + Runtime (isIOS26)
            print("🔍 [TabBar-Setup] Using iOS 26+ direct properties")
            setupIOS26DirectProperties()
        } else if #available(iOS 18.0, *) {
            // iOS 18-25: UITabBarAppearance with Liquid Glass
            print("🔍 [TabBar-Setup] Using iOS 18-25 Liquid Glass")
            setupLiquidGlassAppearance()
        } else {
            // iOS <18: Standard appearance
            print("🔍 [TabBar-Setup] Using standard appearance")
            setupStandardAppearance()
        }

        // Parse tab items from arguments
        var items: [UITabBarItem] = []
        if let params = args as? [String: Any],
           let tabItems = params["items"] as? [[String: Any]] {
            print("🔍 [TabBar-Setup] Found \(tabItems.count) tab items")
            items = createTabItems(from: tabItems)
        } else {
            print("⚠️ [TabBar-Setup] No tab items found in arguments!")
        }

        print("🔍 [TabBar-Setup] Created \(items.count) UITabBarItems")
        
        // CRITICAL FIX: Start hidden, will fade in after layout completes
        tabBar.alpha = 0
        
        tabBar.items = items
        if !items.isEmpty {
            // TRICK: Toggle selection to force iOS layout recalculation
            // This is what happens when user taps a tab and labels suddenly fix themselves
            if items.count > 1 {
                tabBar.selectedItem = items[1]  // Select second tab first
            }
            tabBar.selectedItem = items[0]  // Then switch back to first
            print("🔍 [TabBar-Setup] Selected first item with layout trick")
        }

        // Add to container view
        _view.addSubview(tabBar)
        
        // Link tabBar to container for automatic layout triggering after window attachment
        if let containerView = _view as? TabBarContainerView {
            containerView.tabBar = tabBar
        }
        
        // Force layout
        tabBar.sizeToFit()
        tabBar.clipsToBounds = false
        tabBar.setNeedsLayout()
        tabBar.layoutIfNeeded()

        // Auto layout constraints for dynamic transformation
        leadingConstraint = tabBar.leadingAnchor.constraint(equalTo: _view.leadingAnchor)
        trailingConstraint = tabBar.trailingAnchor.constraint(equalTo: _view.trailingAnchor)
        bottomConstraint = tabBar.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
        topConstraint = tabBar.topAnchor.constraint(equalTo: _view.topAnchor)
        
        NSLayoutConstraint.activate([
            leadingConstraint,
            trailingConstraint,
            bottomConstraint,
            topConstraint
        ])

        // Pin shadowView to tabBar to perfectly track its frame
        NSLayoutConstraint.activate([
            shadowView.leadingAnchor.constraint(equalTo: tabBar.leadingAnchor),
            shadowView.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor),
            shadowView.topAnchor.constraint(equalTo: tabBar.topAnchor),
            shadowView.bottomAnchor.constraint(equalTo: tabBar.bottomAnchor)
        ])
        
        // CRITICAL: Ensure initial state is full-width
        tabBar.setNeedsLayout()
        tabBar.layoutIfNeeded()
        _view.layoutIfNeeded()
    }

    /// iOS 26+ Direct Properties Setup
    /// BYPASS UITabBarAppearance (interferes with custom colors in iOS 26)
    /// NATIVE: Uses direct property assignment for better color control
    @available(iOS 26.0, *)
    private func setupIOS26DirectProperties() {
        // CRITICAL: Enable translucency FIRST
        tabBar.isTranslucent = true

        // Clear background images to allow native blur
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()

        // CRITICAL: NO backgroundColor! Let iOS native blur handle it
        // Setting backgroundColor prevents translucent blur effect
        tabBar.backgroundColor = .clear

        // Set tint colors directly
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .secondaryLabel

        // Log iOS 26 mode
        print("📱 [TabBar] Using iOS 26+ direct properties with native blur")
    }

    /// iOS 18-25: UITabBarAppearance with Liquid Glass
    @available(iOS 18.0, *)
    private func setupLiquidGlassAppearance() {
        // Standard appearance (default state)
        let standardAppearance = UITabBarAppearance()
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)

        // Selected item style
        standardAppearance.stackedLayoutAppearance.selected.iconColor = .systemBlue
        standardAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold),
            .paragraphStyle: NSParagraphStyle.default
        ]
        
        // Selected (Inline & Compact)
        standardAppearance.inlineLayoutAppearance.selected.iconColor = .systemBlue
        standardAppearance.inlineLayoutAppearance.selected.titleTextAttributes = standardAppearance.stackedLayoutAppearance.selected.titleTextAttributes
        standardAppearance.compactInlineLayoutAppearance.selected.iconColor = .systemBlue
        standardAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = standardAppearance.stackedLayoutAppearance.selected.titleTextAttributes

        // Normal item style
        standardAppearance.stackedLayoutAppearance.normal.iconColor = .secondaryLabel
        standardAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium),
            .paragraphStyle: NSParagraphStyle.default
        ]
        
        // Normal (Inline & Compact)
        standardAppearance.inlineLayoutAppearance.normal.iconColor = .secondaryLabel
        standardAppearance.inlineLayoutAppearance.normal.titleTextAttributes = standardAppearance.stackedLayoutAppearance.normal.titleTextAttributes
        standardAppearance.compactInlineLayoutAppearance.normal.iconColor = .secondaryLabel
        standardAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes = standardAppearance.stackedLayoutAppearance.normal.titleTextAttributes

        // Scroll edge appearance (when content scrolls beneath)
        // Lighter blur for true Liquid Glass feel
        let scrollEdgeAppearance = UITabBarAppearance()
        scrollEdgeAppearance.configureWithDefaultBackground()
        scrollEdgeAppearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial) 
        // NO backgroundColor - let blur effect handle it naturally

        // Copy over the item appearances from the standard appearance
        scrollEdgeAppearance.stackedLayoutAppearance = standardAppearance.stackedLayoutAppearance
        scrollEdgeAppearance.inlineLayoutAppearance = standardAppearance.inlineLayoutAppearance
        scrollEdgeAppearance.compactInlineLayoutAppearance = standardAppearance.compactInlineLayoutAppearance

        // CRITICAL: Configure spacing and positioning BEFORE assignment
        // MAXIMIZE HORIZONTAL SPACE for labels
        standardAppearance.stackedItemPositioning = .fill
        standardAppearance.stackedItemSpacing = 0
        scrollEdgeAppearance.stackedItemPositioning = .fill
        scrollEdgeAppearance.stackedItemSpacing = 0
        
        // Apply appearances AFTER configuration
        tabBar.standardAppearance = standardAppearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = scrollEdgeAppearance
        }
    }

    private func setupStandardAppearance() {
        // Standard iOS appearance for older versions
        tabBar.barTintColor = .systemBackground
        tabBar.tintColor = .systemBlue
        tabBar.unselectedItemTintColor = .secondaryLabel
    }

    /// Create tab items with iOS 26 enhancements
    /// CHAOS RESISTANT: Validates all inputs with safe defaults
    /// iOS 26: Search tab support + optimized rendering modes
    private func createTabItems(from data: [[String: Any]]) -> [UITabBarItem] {
        return data.enumerated().compactMap { (index, itemData) in
            // SECURITY: Validate required fields
            guard let label = itemData["label"] as? String else {
                print("⚠️ [TabBar] Missing label, skipping")
                return nil
            }

            let badge = itemData["badge"] as? String
            let isSearchTab = itemData["isSearch"] as? Bool ?? false

            // Search tab support
            let item = createRegularTabItem(from: itemData, label: label)
            item.tag = index
            if isSearchTab {
                print("📱 [TabBar] Identified search tab at index \(index)")
            }

            // iOS 26: Optimized rendering modes
            if isIOS26 {
                // Unselected: alwaysOriginal (custom tint control)
                item.image = item.image?.withRenderingMode(.alwaysOriginal)
                // Selected: alwaysTemplate (respects tabBar.tintColor)
                item.selectedImage = item.selectedImage?.withRenderingMode(.alwaysTemplate)
            }

            // Badge support
            if let badge = badge {
                item.badgeValue = badge
            }

            return item
        }
    }

    private func createRegularTabItem(from data: [String: Any], label: String) -> UITabBarItem {
        let iconImage = createTabIcon(
            from: data,
            nameKey: "iconName",
            codeKey: "iconCode",
            familyKey: "iconFamily"
        )
        let selectedIconImage = createTabIcon(
            from: data,
            nameKey: "selectedIconName",
            codeKey: "selectedIconCode",
            familyKey: "selectedIconFamily"
        )

        return UITabBarItem(
            title: label,
            image: iconImage,
            selectedImage: selectedIconImage
        )
    }

    private func createTabIcon(
        from data: [String: Any],
        nameKey: String,
        codeKey: String,
        familyKey: String
    ) -> UIImage? {
        // 1. Try SF Symbols first (if iconName provided)
        if let iconName = data[nameKey] as? String,
           let image = UIImage(systemName: iconName) {
            return image
        }

        // 2. Fallback to Unicode with proper font mapping (Matches AppBar behavior)
        if let iconCode = data[codeKey] as? Int {
            let iconString = String(format: "%C", iconCode)
            let family = data[familyKey] as? String ?? ""
            let fontSize: CGFloat = 24.0
            var font: UIFont?

            if family.contains("CupertinoIcons") {
                font = UIFont(name: "CupertinoIcons", size: fontSize)
            } else if family.contains("MaterialIcons") {
                font = UIFont(name: "MaterialIcons-Regular", size: fontSize)
            }

            if let iconFont = font {
                // Render text to image for TabBarItem compatibility
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: iconFont,
                    .foregroundColor: UIColor.label
                ]
                let size = (iconString as NSString).size(withAttributes: attributes)
                UIGraphicsBeginImageContextWithOptions(size, false, 0)
                (iconString as NSString).draw(at: .zero, withAttributes: attributes)
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                // Return as alwaysTemplate to allow TabBar tinting to work
                return image?.withRenderingMode(.alwaysTemplate)
            }
        }

        return UIImage(systemName: "circle")
    }

    private func setupMethodChannel() {
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else {
                result(FlutterError(code: "UNAVAILABLE", message: "View not available", details: nil))
                return
            }

            switch call.method {
            case "selectTab":
                if let args = call.arguments as? [String: Any],
                   let index = args["index"] as? Int {
                    self.selectTab(at: index)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid index", details: nil))
                }

            case "getCurrentIndex":
                result(self.selectedIndex)

            case "setBadge":
                if let args = call.arguments as? [String: Any],
                   let index = args["index"] as? Int,
                   let badge = args["badge"] as? String {
                    self.setBadge(at: index, badge: badge)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for setBadge", details: nil))
                }

            case "clearBadge":
                if let args = call.arguments as? [String: Any],
                   let index = args["index"] as? Int {
                    self.clearBadge(at: index)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid index", details: nil))
                }

            case "setBadgeColor":
                if let args = call.arguments as? [String: Any],
                   let index = args["index"] as? Int,
                   let colorHex = args["color"] as? String {
                    self.setBadgeColor(at: index, color: colorHex)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments for setBadgeColor", details: nil))
                }

            case "setMinimizationFactor":
                if let args = call.arguments as? [String: Any],
                   let factor = args["factor"] as? Double {
                    self.updateMinimization(CGFloat(factor))
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid factor", details: nil))
                }

            case "setElevation":
                if let args = call.arguments as? [String: Any],
                   let elevation = args["elevation"] as? Double {
                    self.baseElevation = CGFloat(elevation)
                    // Re-apply current minimization to update shadow with new elevation
                    self.updateMinimization(self.currentMinimizationFactor)
                    result(nil)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid elevation", details: nil))
                }

            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private var isInitialCall = true
    private var minimizationRetryCount = 0
    private let maxMinimizationRetries = 10  // Max 1 second of retries (10 * 100ms)
    private var baseElevation: CGFloat = 4.0  // Default elevation level (0-10)
    private var currentMinimizationFactor: CGFloat = 0.0  // Track current factor for re-application

    private func updateMinimization(_ factor: CGFloat) {
        // CHAOS RESILIENCE: Skip until TabBar is in window with valid bounds
        // The first call from Flutter happens before TabBar layout is complete
        guard tabBar.window != nil && tabBar.bounds.width > 0 else {
            // FAIL-SAFE: Limit retries to prevent infinite loop
            guard minimizationRetryCount < maxMinimizationRetries else {
                print("⚠️ [TabBar-Minimization] Max retries (\(maxMinimizationRetries)) reached. TabBar may not be in view hierarchy.")
                minimizationRetryCount = 0  // Reset for future calls
                return
            }
            
            minimizationRetryCount += 1
            print("🔄 [TabBar-Minimization] TabBar not ready (attempt \(minimizationRetryCount)/\(maxMinimizationRetries)), retrying in 100ms...")
            
            // Schedule a retry after TabBar is in view hierarchy
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.updateMinimization(factor)
            }
            return
        }
        
        // Reset retry count on successful call
        if minimizationRetryCount > 0 {
            print("✅ [TabBar-Minimization] TabBar ready after \(minimizationRetryCount) retries")
            minimizationRetryCount = 0
        }
        
        // Store current factor for re-application when elevation changes
        currentMinimizationFactor = factor
        
        // HYSTERESIS: Small values are treated as exact zero to prevent "ghost" insets
        let clampedFactor = factor < 0.01 ? 0.0 : max(0, min(1, factor))
        
        // Dynamic Label Transparency: Fade out text as we minimize
        let labelAlpha = factor < 0.01 ? 1.0 : (1.0 - (max(0, clampedFactor - 0.2) * 5.0))
        let appearance = tabBar.standardAppearance
        
        [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance].forEach { layout in
            let normalAttrs = layout.normal.titleTextAttributes
            var newNormalAttrs = normalAttrs
            newNormalAttrs[.foregroundColor] = (normalAttrs[.foregroundColor] as? UIColor ?? .secondaryLabel).withAlphaComponent(max(0, labelAlpha))
            layout.normal.titleTextAttributes = newNormalAttrs
            
            let selectedAttrs = layout.selected.titleTextAttributes
            var newSelectedAttrs = selectedAttrs
            newSelectedAttrs[.foregroundColor] = (selectedAttrs[.foregroundColor] as? UIColor ?? .systemBlue).withAlphaComponent(max(0, labelAlpha))
            layout.selected.titleTextAttributes = newSelectedAttrs
        }
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }

        func applyChanges() {
            // Transition from full-width to a centered "Pill Island"
            let horizontalInset: CGFloat = 32.0 * clampedFactor 
            let bottomLift: CGFloat = 20.0 * clampedFactor      
            
            self.leadingConstraint.constant = horizontalInset
            self.trailingConstraint.constant = -horizontalInset
            self.bottomConstraint.constant = -bottomLift
            
            // Continuous Curvature: The bar is ALWAYS a pill
            let fixedRadius: CGFloat = 36.0 
            self.tabBar.layer.cornerRadius = fixedRadius
            self.tabBar.clipsToBounds = false 
            self.shadowView.layer.cornerRadius = fixedRadius
            
            // Vertical transform & scale
            let scale: CGFloat = 1.0 - (0.05 * clampedFactor)
            let transform = CGAffineTransform(scaleX: scale, y: scale)
            self.tabBar.transform = transform
            self.shadowView.transform = transform
            
            // Shadow Adjustments using baseElevation for configurable depth
            // CHAOS FIX: Use non-linear curves for a more natural transition
            // Radius grows quickly (softens early), Opacity grows slowly (faint start)
            let radiusFactor = pow(clampedFactor, 0.5)
            let opacityFactor = pow(clampedFactor, 1.5)
            let effectiveElevation = self.baseElevation * clampedFactor
            
            if clampedFactor > 0.01 {
                // Shadow opacity: Starts faint, gains intensity slower
                self.shadowView.layer.shadowOpacity = Float(opacityFactor * 0.12)
                // Shadow offset: 0.5 per elevation level
                self.shadowView.layer.shadowOffset = CGSize(width: 0, height: 0.5 * effectiveElevation)
                // Shadow radius: Softens immediately upon appearance
                self.shadowView.layer.shadowRadius = radiusFactor * self.baseElevation * 1.5
                
                let shadowDX: CGFloat = 16.0 * clampedFactor
                let shadowDY: CGFloat = 12.0 * clampedFactor
                let insetRect = self.shadowView.bounds.insetBy(dx: shadowDX, dy: shadowDY)
                
                let path = UIBezierPath(roundedRect: insetRect, cornerRadius: fixedRadius)
                self.shadowView.layer.shadowPath = path.cgPath
            } else {
                self.shadowView.layer.shadowOpacity = 0
                self.shadowView.layer.shadowPath = nil
            }
            
            // FORCE layout sync
            self.tabBar.setNeedsLayout()
            self.tabBar.layoutIfNeeded()
            self._view.layoutIfNeeded()
        }

        // SYNC: Ensure the view state is matched immediately on first call without animation
        if isInitialCall {
            isInitialCall = false
            UIView.performWithoutAnimation {
                applyChanges()
            }
        } else {
            // Spring animation for native iOS feel
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: [.curveEaseOut, .beginFromCurrentState]) {
                applyChanges()
            }
        }
    }

    private func selectTab(at index: Int) {
        guard index >= 0 && index < (tabBar.items?.count ?? 0) else { return }
        selectedIndex = index
        tabBar.selectedItem = tabBar.items?[index]
    }

    /// Set badge value for a tab item
    private func setBadge(at index: Int, badge: String) {
        guard index >= 0 && index < (tabBar.items?.count ?? 0) else { return }
        tabBar.items?[index].badgeValue = badge
    }

    /// Clear badge value for a tab item
    private func clearBadge(at index: Int) {
        guard index >= 0 && index < (tabBar.items?.count ?? 0) else { return }
        tabBar.items?[index].badgeValue = nil
    }

    /// Set badge color for a tab item (iOS 10+)
    private func setBadgeColor(at index: Int, color: String) {
        guard index >= 0 && index < (tabBar.items?.count ?? 0) else { return }
        tabBar.items?[index].badgeColor = UIColor(hex: color)
    }
}

// MARK: - UITabBarDelegate

@available(iOS 15.0, *)
extension AdaptiveCupertinoTabBarPlatformView: UITabBarDelegate {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        let index = item.tag
        selectedIndex = index

        // Notify Flutter
        channel.invokeMethod("onTabChanged", arguments: ["index": index])
    }
}

// MARK: - Parent ViewController Helper

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder?.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}

// MARK: - UIColor Extension (Hex Support)

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
