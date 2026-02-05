import Flutter
import UIKit
import os.log

@available(iOS 15.0, *)
public class AdaptiveCupertinoPlugin: NSObject, FlutterPlugin {
    private static var registrar: FlutterPluginRegistrar?

    internal static var shared: AdaptiveCupertinoPlugin?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        Self.registrar = registrar
        let channel = FlutterMethodChannel(
            name: "adaptive_cupertino_ios",
            binaryMessenger: registrar.messenger()
        )
        AdaptiveCupertinoSheetManager.setChannel(channel)
        let instance = AdaptiveCupertinoPlugin(messenger: registrar.messenger(), registrar: registrar)
        Self.shared = instance
        registrar.addMethodCallDelegate(instance, channel: channel)

        // Register PlatformView factories
        registerPlatformViews(with: registrar)
    }

    private let messenger: FlutterBinaryMessenger
    private let registrar: FlutterPluginRegistrar
    private var engineGroup: FlutterEngineGroup?

    init(messenger: FlutterBinaryMessenger, registrar: FlutterPluginRegistrar) {
        self.messenger = messenger
        self.registrar = registrar
        if #available(iOS 10.0, *) {
            self.engineGroup = FlutterEngineGroup(name: "adaptive_cupertino_sheets", project: nil)
        }
        super.init()
    }
    
    internal func spawnEngine(withRoute route: String) -> FlutterEngine? {
        return engineGroup?.makeEngine(withEntrypoint: "adaptiveSheetEntrypoint", libraryURI: nil, initialRoute: route)
    }

    private static func registerPlatformViews(with registrar: FlutterPluginRegistrar) {
        // TabBar PlatformView
        let tabBarFactory = AdaptiveCupertinoTabBarFactory(messenger: registrar.messenger(), registrar: registrar)
        registrar.register(
            tabBarFactory,
            withId: "adaptive_cupertino_ios/tab_bar"
        )

        // NavigationBar PlatformView (formerly AppBar)
        // Matches UIKit naming (UINavigationBar)
        let navBarFactory = AdaptiveCupertinoNavigationBarFactory(messenger: registrar.messenger(), registrar: registrar)
        registrar.register(
            navBarFactory,
            withId: "adaptive_cupertino_ios/navigation_bar"
        )

        // Toolbar PlatformView (iOS 26+ native UIToolbar)
        let toolbarFactory = AdaptiveCupertinoToolbarFactory(messenger: registrar.messenger(), registrar: registrar)
        registrar.register(
            toolbarFactory,
            withId: "adaptive_cupertino_ios/toolbar"
        )

        // Button PlatformView (formerly GlassButton)
        // Standardized naming
        let buttonFactory = AdaptiveCupertinoButtonFactory(messenger: registrar.messenger(), registrar: registrar)
        registrar.register(
            buttonFactory,
            withId: "adaptive_cupertino_ios/button"
        )

        // SegmentedControl PlatformView
        let segmentedFactory = AdaptiveCupertinoSegmentedControlFactory(messenger: registrar.messenger())
        registrar.register(
            segmentedFactory,
            withId: "adaptive_cupertino_ios/segmented_control"
        )
        
        // Switch PlatformView
        let switchFactory = AdaptiveCupertinoSwitchFactory(messenger: registrar.messenger())
        registrar.register(
            switchFactory,
            withId: "adaptive_cupertino_ios/switch"
        )
        
        // Slider PlatformView
        let sliderFactory = AdaptiveCupertinoSliderFactory(messenger: registrar.messenger())
        registrar.register(
            sliderFactory,
            withId: "adaptive_cupertino_ios/slider"
        )

        // TextField PlatformView
        let textFieldFactory = AdaptiveCupertinoTextFieldFactory(messenger: registrar.messenger())
        registrar.register(
            textFieldFactory,
            withId: "adaptive_cupertino_ios/text_field"
        )

        // Toggle (Checkbox/Radio) PlatformView
        let toggleFactory = AdaptiveCupertinoToggleFactory(messenger: registrar.messenger())
        registrar.register(
            toggleFactory,
            withId: "adaptive_cupertino_ios/toggle"
        )

        // Badge PlatformView
        let badgeFactory = AdaptiveCupertinoBadgeFactory(messenger: registrar.messenger())
        registrar.register(
            badgeFactory,
            withId: "adaptive_cupertino_ios/badge"
        )

        // Picker PlatformView
        let pickerFactory = AdaptiveCupertinoPickerFactory(messenger: registrar.messenger())
        registrar.register(
            pickerFactory,
            withId: "adaptive_cupertino_ios/picker"
        )

        // Menu PlatformView
        let menuFactory = AdaptiveCupertinoMenuFactory(messenger: registrar.messenger())
        registrar.register(
            menuFactory,
            withId: "adaptive_cupertino_ios/menu"
        )

        // ListTile PlatformView
        let listTileFactory = AdaptiveCupertinoListTileFactory(messenger: registrar.messenger(), registrar: registrar)
        registrar.register(
            listTileFactory,
            withId: "adaptive_cupertino_ios/list_tile"
        )

        // FormSection PlatformView
        let formSectionFactory = AdaptiveCupertinoFormSectionFactory(messenger: registrar.messenger())
        registrar.register(
            formSectionFactory,
            withId: "adaptive_cupertino_ios/form_section"
        )

        // Tooltip PlatformView
        let tooltipFactory = AdaptiveCupertinoTooltipFactory(messenger: registrar.messenger())
        registrar.register(
            tooltipFactory,
            withId: "adaptive_cupertino_ios/tooltip"
        )

        // ExpansionTile PlatformView
        let expansionTileFactory = AdaptiveCupertinoExpansionTileFactory(messenger: registrar.messenger())
        registrar.register(
            expansionTileFactory,
            withId: "adaptive_cupertino_ios/expansion_tile"
        )

        // FAB PlatformView
        let fabFactory = AdaptiveCupertinoFloatingActionButtonFactory(messenger: registrar.messenger())
        registrar.register(
            fabFactory,
            withId: "adaptive_cupertino_ios/fab"
        )
        
        // GlassBox PlatformView (Generic Glass Container)
        let glassBoxFactory = AdaptiveCupertinoGlassBoxFactory(messenger: registrar.messenger())
        registrar.register(
            glassBoxFactory,
            withId: "adaptive_cupertino_ios/glass_box"
        )
        
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "supportsNativeUI":
            result(supportsNativeUI())
        case "getIOSVersion":
            result(IOSVersionDetector.versionInfo())
        case "supportsGlassEffect":
            result(IOSVersionDetector.supportsGlassEffect())
        case "supportsModernToolbar":
            result(IOSVersionDetector.supportsModernToolbar())
        case "showSheet":
            if let params = call.arguments as? [String: Any] {
                AdaptiveCupertinoSheetManager.showSheet(messenger: messenger, params: params) { success in
                    result(success)
                }
            } else {
                result(false)
            }
        case "showDialog":
            if let params = call.arguments as? [String: Any] {
                showNativeDialog(params: params, result: result)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments must be a map", details: nil))
            }
        case "showSnackBar":
            if let params = call.arguments as? [String: Any] {
                showNativeSnackBar(params: params)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments must be a map", details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func supportsNativeUI() -> Bool {
        return IOSVersionDetector.supportsGlassEffect()
    }

    private func showNativeDialog(params: [String: Any], result: @escaping FlutterResult) {
        guard let title = params["title"] as? String?,
              let message = params["content"] as? String?,
              let actions = params["actions"] as? [[String: Any]] else {
            result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required params", details: nil))
            return
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        for (index, actionParams) in actions.enumerated() {
            let label = actionParams["label"] as? String ?? "Button"
            let isDestructive = actionParams["isDestructive"] as? Bool ?? false
            let isDefault = actionParams["isDefault"] as? Bool ?? false
            
            var style: UIAlertAction.Style = .default
            if isDestructive {
                style = .destructive
            } else if label.lowercased() == "cancel" {
                 style = .cancel
            }

            let action = UIAlertAction(title: label, style: style) { _ in
                result(index) // Return the index of the clicked button
            }
            alert.addAction(action)
            
            // Preferred action support (iOS 9+)
            if isDefault {
                alert.preferredAction = action
            }
        }

        DispatchQueue.main.async {
            guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {
                result(FlutterError(code: " NO_ROOT_VC", message: "No root view controller", details: nil))
                return
            }
            // Present from the top-most view controller
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            topVC.present(alert, animated: true, completion: nil)
        }
    }
    
    private func showNativeSnackBar(params: [String: Any]) {
        guard let message = params["message"] as? String else { return }
        let duration = params["duration"] as? Double ?? 3.0
        let iconName = params["icon"] as? String
        
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) else { return }
            
            // Container (Glass)
            let container = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
            container.layer.cornerRadius = 20
            container.layer.masksToBounds = true
            // Border logic (optional, keeping simple for now)
            container.layer.borderColor = UIColor.white.withAlphaComponent(0.2).cgColor
            container.layer.borderWidth = 0.5
            
            container.translatesAutoresizingMaskIntoConstraints = false
            
            // Content
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.spacing = 12
            stack.alignment = .center
            stack.translatesAutoresizingMaskIntoConstraints = false
            
            // Icon
            // Icon
            if let image = UIImage(systemName: iconName ?? "info.circle.fill") {
               let iv = UIImageView(image: image)
               iv.tintColor = .systemBlue
               iv.contentMode = .scaleAspectFit
               stack.addArrangedSubview(iv)
               NSLayoutConstraint.activate([
                   iv.widthAnchor.constraint(equalToConstant: 24),
                   iv.heightAnchor.constraint(equalToConstant: 24)
               ])
            }
            
            // Label
            let label = UILabel()
            label.text = message
            label.font = .systemFont(ofSize: 15, weight: .medium)
            label.textColor = .label
            label.numberOfLines = 2
            stack.addArrangedSubview(label)
            
            container.contentView.addSubview(stack)
            
            NSLayoutConstraint.activate([
                stack.leadingAnchor.constraint(equalTo: container.contentView.leadingAnchor, constant: 16),
                stack.trailingAnchor.constraint(equalTo: container.contentView.trailingAnchor, constant: -16),
                stack.topAnchor.constraint(equalTo: container.contentView.topAnchor, constant: 12),
                stack.bottomAnchor.constraint(equalTo: container.contentView.bottomAnchor, constant: -12)
            ])
            
            window.addSubview(container)
            
            // Layout (Start off-screen top)
            let topConstraint = container.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor, constant: -100)
            
            NSLayoutConstraint.activate([
                container.centerXAnchor.constraint(equalTo: window.centerXAnchor),
                container.widthAnchor.constraint(lessThanOrEqualTo: window.widthAnchor, constant: -32),
                container.widthAnchor.constraint(greaterThanOrEqualToConstant: 200),
                topConstraint
            ])
            
            window.layoutIfNeeded()
            
            // Animate In
            topConstraint.constant = 10
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut) {
                window.layoutIfNeeded()
            } completion: { _ in
                // Animate Out after duration
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    topConstraint.constant = -100
                    UIView.animate(withDuration: 0.4, delay: 0, options: .curveEaseIn) {
                        window.layoutIfNeeded()
                    } completion: { _ in
                        container.removeFromSuperview()
                    }
                }
            }
        }
    }
}
