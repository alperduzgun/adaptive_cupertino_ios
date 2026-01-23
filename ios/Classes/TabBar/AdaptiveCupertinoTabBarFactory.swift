import Flutter
import UIKit

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
    private var messenger: FlutterBinaryMessenger
    private var selectedIndex: Int = 0
    private let channel: FlutterMethodChannel

    // iOS 26 state tracking
    private var minimizeBehavior: Int = 3 // 0-3, default: 3 (automatic)
    private var isIOS26: Bool = false

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        print("🔍 [TabBar-View] Init started")
        self.messenger = messenger
        self._view = UIView(frame: frame)

        // CRITICAL: Container must be transparent for native blur to work
        self._view.backgroundColor = .clear
        self._view.isOpaque = false

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

        // Create native UITabBar
        tabBar = UITabBar()
        tabBar.delegate = self
        tabBar.translatesAutoresizingMaskIntoConstraints = false

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
        tabBar.items = items
        if !items.isEmpty {
            tabBar.selectedItem = items[0]
            print("🔍 [TabBar-Setup] Selected first item")
        }

        // Add to container view
        _view.addSubview(tabBar)

        // Auto layout constraints
        NSLayoutConstraint.activate([
            tabBar.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            tabBar.topAnchor.constraint(equalTo: _view.topAnchor),
            tabBar.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
        ])
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
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]

        // Normal item style
        standardAppearance.stackedLayoutAppearance.normal.iconColor = .secondaryLabel
        standardAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]

        // Scroll edge appearance (when content scrolls beneath)
        // Lighter blur for true Liquid Glass feel
        let scrollEdgeAppearance = UITabBarAppearance()
        scrollEdgeAppearance.configureWithDefaultBackground()
        scrollEdgeAppearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterial) 
        // NO backgroundColor - let blur effect handle it naturally

        // Selected item style (scroll edge)
        scrollEdgeAppearance.stackedLayoutAppearance.selected.iconColor = .systemBlue
        scrollEdgeAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.systemBlue,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]

        // Normal item style (scroll edge)
        scrollEdgeAppearance.stackedLayoutAppearance.normal.iconColor = .secondaryLabel
        scrollEdgeAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]

        // Apply appearances
        tabBar.standardAppearance = standardAppearance
        tabBar.scrollEdgeAppearance = scrollEdgeAppearance

        // iOS 18+ specific: Enable scroll edge effect automatically
        // The scroll edge effect is automatic in iOS 18+ when combined with scroll views
        // No additional configuration needed - the system handles it
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
        return data.compactMap { itemData in
            // SECURITY: Validate required fields
            guard let label = itemData["label"] as? String else {
                print("⚠️ [TabBar] Missing label, skipping")
                return nil
            }

            let badge = itemData["badge"] as? String
            let isSearchTab = itemData["isSearch"] as? Bool ?? false

            // iOS 26: Search tab support
            var item: UITabBarItem
            if isIOS26 && isSearchTab {
                // Native search tab (iOS 26+)
                if #available(iOS 26.0, *) {
                    item = UITabBarItem(tabBarSystemItem: .search, tag: 0)
                    item.title = label // Override default "Search" if needed
                    print("📱 [TabBar] Created iOS 26 search tab")
                } else {
                    item = createRegularTabItem(from: itemData, label: label)
                }
            } else {
                item = createRegularTabItem(from: itemData, label: label)
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

            default:
                result(FlutterMethodNotImplemented)
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
        guard let index = tabBar.items?.firstIndex(of: item) else { return }
        selectedIndex = index

        // Notify Flutter
        channel.invokeMethod("onTabChanged", arguments: ["index": index])
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
