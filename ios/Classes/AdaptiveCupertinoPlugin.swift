import Flutter
import UIKit
import os.log

@available(iOS 15.0, *)
public class AdaptiveCupertinoPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "adaptive_cupertino_ios",
            binaryMessenger: registrar.messenger()
        )
        let instance = AdaptiveCupertinoPlugin(messenger: registrar.messenger())
        registrar.addMethodCallDelegate(instance, channel: channel)

        // Register PlatformView factories
        registerPlatformViews(with: registrar)
    }

    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    private static func registerPlatformViews(with registrar: FlutterPluginRegistrar) {
        // TabBar PlatformView
        let tabBarFactory = AdaptiveCupertinoTabBarFactory(messenger: registrar.messenger())
        registrar.register(
            tabBarFactory,
            withId: "adaptive_cupertino_ios/tab_bar"
        )

        // NavigationBar PlatformView (formerly AppBar)
        // Matches UIKit naming (UINavigationBar)
        let navBarFactory = AdaptiveCupertinoNavigationBarFactory(messenger: registrar.messenger())
        registrar.register(
            navBarFactory,
            withId: "adaptive_cupertino_ios/navigation_bar"
        )

        // Toolbar PlatformView (iOS 26+ native UIToolbar)
        let toolbarFactory = AdaptiveCupertinoToolbarFactory(messenger: registrar.messenger())
        registrar.register(
            toolbarFactory,
            withId: "adaptive_cupertino_ios/toolbar"
        )

        // Button PlatformView (formerly GlassButton)
        // Standardized naming
        let buttonFactory = AdaptiveCupertinoButtonFactory(messenger: registrar.messenger())
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
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "supportsNativeUI":
            result(supportsNativeUI())
        case "getIOSVersion":
            result(IOSVersionDetector.versionInfo())
        case "supportsLiquidGlass":
            result(IOSVersionDetector.supportsLiquidGlass())
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
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func supportsNativeUI() -> Bool {
        return IOSVersionDetector.supportsLiquidGlass()
    }
}
