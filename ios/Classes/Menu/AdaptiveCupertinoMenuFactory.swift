import Flutter
import UIKit
import os.log

/// Platform View Factory for Adaptive Cupertino Context Menu
@available(iOS 15.0, *)
class AdaptiveCupertinoMenuFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return AdaptiveCupertinoMenuPlatformView(
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

/// Platform View wrapper for UIContextMenuInteraction
@available(iOS 15.0, *)
class AdaptiveCupertinoMenuPlatformView: NSObject, FlutterPlatformView, UIContextMenuInteractionDelegate {
    private var _view: UIView
    private let messenger: FlutterBinaryMessenger
    private let channel: FlutterMethodChannel
    private static let logger = OSLog(subsystem: "com.adaptive_cupertino_ios", category: "MenuFactory")
    
    private var actions: [[String: Any]] = []

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        self.messenger = messenger
        self._view = UIView(frame: frame)
        self.channel = FlutterMethodChannel(
            name: "adaptive_cupertino_ios/menu_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()

        setupMenu(arguments: args)
    }

    func view() -> UIView {
        return _view
    }

    private func setupMenu(arguments args: Any?) {
        guard let params = args as? [String: Any] else { return }
        self.actions = params["actions"] as? [[String: Any]] ?? []

        let interaction = UIContextMenuInteraction(delegate: self)
        _view.addInteraction(interaction)
        _view.isUserInteractionEnabled = true
        
        os_log(.info, log: Self.logger, "Native Context Menu interaction added.")
    }

    // MARK: - UIContextMenuInteractionDelegate

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            guard let self = self else { return nil }
            
            var menuActions: [UIAction] = []
            for (index, actionData) in self.actions.enumerated() {
                let title = actionData["title"] as? String ?? "Action \(index)"
                let icon = actionData["icon"] as? String
                
                let action = UIAction(title: title, image: icon != nil ? UIImage(systemName: icon!) : nil) { [weak self] _ in
                    self?.channel.invokeMethod("onAction", arguments: ["index": index])
                }
                
                if actionData["isDestructive"] as? Bool ?? false {
                    action.attributes = .destructive
                }
                
                menuActions.append(action)
            }
            
            return UIMenu(title: "", children: menuActions)
        }
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willDisplayMenuFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        os_log(.debug, log: Self.logger, "Context Menu will display.")
    }

    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willEndFor configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        os_log(.debug, log: Self.logger, "Context Menu will end.")
    }
}
