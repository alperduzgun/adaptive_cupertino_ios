import Flutter
import UIKit

@available(iOS 15.0, *)
public class AdaptiveCupertinoPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "adaptive_cupertino_ios",
            binaryMessenger: registrar.messenger()
        )
        let instance = AdaptiveCupertinoPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)

        // Register PlatformView factories
        registerPlatformViews(with: registrar)
    }

    private static func registerPlatformViews(with registrar: FlutterPluginRegistrar) {
        // TabBar PlatformView
        let tabBarFactory = AdaptiveCupertinoTabBarFactory(messenger: registrar.messenger())
        registrar.register(
            tabBarFactory,
            withId: "adaptive_cupertino_ios/tab_bar"
        )

        // AppBar PlatformView (iOS 18-25 UINavigationBar)
        let appBarFactory = AdaptiveCupertinoAppBarFactory(messenger: registrar.messenger())
        registrar.register(
            appBarFactory,
            withId: "adaptive_cupertino_ios/app_bar"
        )

        // Toolbar PlatformView (iOS 26+ native UIToolbar with pill-shaped buttons)
        let toolbarFactory = AdaptiveCupertinoToolbarFactory(messenger: registrar.messenger())
        registrar.register(
            toolbarFactory,
            withId: "adaptive_cupertino_ios/toolbar"
        )

        // Glass Button PlatformView
        let glassButtonFactory = AdaptiveCupertinoGlassButtonFactory(messenger: registrar.messenger())
        registrar.register(
            glassButtonFactory,
            withId: "adaptive_cupertino_ios/glass_button"
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
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func supportsNativeUI() -> Bool {
        return IOSVersionDetector.supportsLiquidGlass()
    }
}
