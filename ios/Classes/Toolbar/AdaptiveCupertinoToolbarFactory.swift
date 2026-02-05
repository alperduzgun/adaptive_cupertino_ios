import Flutter
import UIKit
import os.log

/// Platform View Factory for Adaptive Cupertino Toolbar
@available(iOS 15.0, *)
class AdaptiveCupertinoToolbarFactory: NSObject, FlutterPlatformViewFactory {
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
        return AdaptiveCupertinoToolbarPlatformView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            messenger: messenger,
            registrar: registrar
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/// Platform View wrapper for UIToolbar
@available(iOS 15.0, *)
class AdaptiveCupertinoToolbarPlatformView: NSObject, FlutterPlatformView, UIToolbarDelegate {
    private static let logger = OSLog(subsystem: "com.adaptive_cupertino_ios", category: "Toolbar")
    
    private var _view: UIView
    private var toolbar: UIToolbar!
    private var navigationItem: UINavigationItem!
    private var messenger: FlutterBinaryMessenger
    private let registrar: FlutterPluginRegistrar
    private let fontLoader: FlutterFontLoader
    private let channel: FlutterMethodChannel
    private let isBottom: Bool
    private let topPadding: CGFloat
    private let bottomPadding: CGFloat

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger,
        registrar: FlutterPluginRegistrar
    ) {
        self._view = UIView(frame: frame)
        self.messenger = messenger
        self.registrar = registrar
        self.fontLoader = FlutterFontLoader(registrar: registrar)
        self.channel = FlutterMethodChannel(
            name: "adaptive_cupertino_ios/toolbar_\(viewId)",
            binaryMessenger: messenger
        )
        
        let params = args as? [String: Any]
        self.isBottom = params?["isBottom"] as? Bool ?? false
        self.topPadding = params?["topPadding"] as? CGFloat ?? 0
        self.bottomPadding = params?["bottomPadding"] as? CGFloat ?? 0

        super.init()
        setupNativeToolbar(arguments: args)
    }

    func view() -> UIView {
        return _view
    }

    // MARK: - UIToolbarDelegate
    
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return isBottom ? .bottom : .top
    }

    private func setupNativeToolbar(arguments args: Any?) {
        guard let _ = self._view as UIView? else {
            os_log(.error, log: Self.logger, "Failed to access _view, aborting setup")
            return
        }
        guard let toolbar = UIToolbar() as UIToolbar? else {
            os_log(.error, log: Self.logger, "Failed to create UIToolbar, aborting setup")
            return
        }

        self.toolbar = toolbar
        toolbar.delegate = self
        toolbar.backgroundColor = .clear
        toolbar.translatesAutoresizingMaskIntoConstraints = false

        self.navigationItem = UINavigationItem()
        _view.backgroundColor = .clear
        _view.isOpaque = false

        let enableLiquidGlass: Bool
        if let params = args as? [String: Any], let enabled = params["enableLiquidGlass"] as? Bool {
            enableLiquidGlass = enabled
        } else {
            enableLiquidGlass = true
        }

        if enableLiquidGlass {
            // REMOVED: Custom Liquid Glass Background (User request: "kaldır background u")
            /*
            let headerView = AdaptivePillHeaderView(frame: .zero, direction: isBottom ? .bottom : .top, isInteractive: true, useFadingGradient: true)
            headerView.translatesAutoresizingMaskIntoConstraints = false
            _view.addSubview(headerView)
            
            if isBottom {
                NSLayoutConstraint.activate([
                    headerView.leadingAnchor.constraint(equalTo: _view.leadingAnchor, constant: 16),
                    headerView.trailingAnchor.constraint(equalTo: _view.trailingAnchor, constant: -16),
                    headerView.topAnchor.constraint(equalTo: _view.topAnchor, constant: 4),
                    headerView.bottomAnchor.constraint(equalTo: _view.bottomAnchor, constant: -bottomPadding - 12)
                ])
                headerView.layer.cornerRadius = 24
            } else {
                NSLayoutConstraint.activate([
                    headerView.leadingAnchor.constraint(equalTo: _view.leadingAnchor, constant: 16),
                    headerView.trailingAnchor.constraint(equalTo: _view.trailingAnchor, constant: -16),
                    headerView.topAnchor.constraint(equalTo: _view.topAnchor, constant: topPadding + 8),
                    headerView.bottomAnchor.constraint(equalTo: _view.bottomAnchor, constant: -8)
                ])
                headerView.layer.cornerRadius = 24
            }
            */
        }

        configureToolbarAppearance()

        if let params = args as? [String: Any] {
            configureToolbarItems(from: params)
        }

        _view.addSubview(toolbar)

        if isBottom {
            NSLayoutConstraint.activate([
                toolbar.leadingAnchor.constraint(equalTo: _view.leadingAnchor, constant: 16),
                toolbar.trailingAnchor.constraint(equalTo: _view.trailingAnchor, constant: -16),
                toolbar.bottomAnchor.constraint(equalTo: _view.bottomAnchor, constant: -bottomPadding - 8),
                toolbar.heightAnchor.constraint(equalToConstant: 44)
            ])
        } else {
            NSLayoutConstraint.activate([
                toolbar.leadingAnchor.constraint(equalTo: _view.leadingAnchor, constant: 16),
                toolbar.trailingAnchor.constraint(equalTo: _view.trailingAnchor, constant: -16),
                toolbar.topAnchor.constraint(equalTo: _view.topAnchor, constant: topPadding + 8),
                toolbar.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
    }

    private func configureToolbarAppearance() {
        guard let toolbar = self.toolbar else { return }
        
        let appearance = UIToolbarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundImage = UIImage()
        appearance.shadowImage = UIImage()
        appearance.shadowColor = .clear
        
        // Configure prominent button appearance
        if #available(iOS 26.0, *) {
            let prominentButton = appearance.prominentButtonAppearance
            prominentButton.normal.titleTextAttributes = [
                .font: UIFont.systemFont(ofSize: 17, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
        }
        
        toolbar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            toolbar.scrollEdgeAppearance = appearance
        }
        toolbar.compactAppearance = appearance
        
        toolbar.isTranslucent = true
        toolbar.backgroundColor = .clear
        toolbar.clipsToBounds = false
    }

    private func configureToolbarItems(from params: [String: Any]) {
        var items: [UIBarButtonItem] = []
        
        // Leading Item
        if let leadingData = params["leading"] as? [String: Any] {
            if let item = createBarButtonItem(from: leadingData, position: .leading, index: -1) {
                items.append(item)
            }
        }
        
        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        
        // Title or Flexible Space
        if let title = params["title"] as? String {
            let titleColorValue = params["titleColor"] as? Int64
            let titleColor = titleColorValue != nil ? UIColor(argb: titleColorValue!) : nil
            items.append(createTitleBarButtonItem(title: title, color: titleColor))
        }
        
        items.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
        
        // Trailing Items
        if let trailingData = params["trailing"] as? [[String: Any]] {
            for (index, data) in trailingData.enumerated() {
                if let item = createBarButtonItem(from: data, position: .trailing, index: index) {
                    items.append(item)
                }
            }
        }
        
        toolbar.setItems(items, animated: false)
    }

    enum ButtonPosition {
        case leading
        case trailing
    }

    private func createBarButtonItem(
        from data: [String: Any],
        position: ButtonPosition,
        index: Int
    ) -> UIBarButtonItem? {
        if let type = data["type"] as? String, type == "spacer" {
            return UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        }
        
        if let systemIconName = data["systemIcon"] as? String {
             let image = UIImage(systemName: systemIconName)
             let button = UIBarButtonItem(
                 image: image,
                 style: .plain,
                 target: self,
                 action: position == .leading ? #selector(leadingTapped) : #selector(trailingTapped(_:))
             )
             button.tag = index
             if let colorVal = data["color"] as? Int64 {
                 button.tintColor = UIColor(argb: colorVal)
             }
             return button
        } else if let iconCode = data["iconCode"] as? Int {
             let iconString = String(UnicodeScalar(iconCode)!)
             let button = UIBarButtonItem(
                 title: iconString,
                 style: .plain,
                 target: self,
                 action: position == .leading ? #selector(leadingTapped) : #selector(trailingTapped(_:))
             )
             
             if let fontFamily = data["iconFamily"] as? String {
                 let iconPackage = data["iconPackage"] as? String
                 if let font = fontLoader.loadFont(name: fontFamily, size: 24, package: iconPackage) {
                     let attributes: [NSAttributedString.Key: Any] = [.font: font]
                     button.setTitleTextAttributes(attributes, for: .normal)
                     button.setTitleTextAttributes(attributes, for: .highlighted)
                 }
             }
             
             if let colorVal = data["color"] as? Int64 {
                 button.tintColor = UIColor(argb: colorVal)
             }
             
             button.tag = index
             return button
        } else if let _ = data["label"] as? String {
             return createTextButton(from: data, position: position, index: index)
        }
        return nil
    }


    private func createTextButton(
        from data: [String: Any],
        position: ButtonPosition,
        index: Int
    ) -> UIBarButtonItem? {
        guard let label = data["label"] as? String else { return nil }
        let isProminent = data["prominent"] as? Bool ?? false
        let button = UIBarButtonItem(
            title: label,
            style: isProminent ? .done : .plain,
            target: self,
            action: position == .leading ? #selector(leadingTapped) : #selector(trailingTapped(_:))
        )
        button.tag = index
        return button
    }

    private func createTitleBarButtonItem(title: String, color: UIColor? = nil) -> UIBarButtonItem {
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        if let color = color {
            label.textColor = color
        }
        label.sizeToFit()
        return UIBarButtonItem(customView: label)
    }

    @objc private func leadingTapped() {
        channel.invokeMethod("onLeadingTapped", arguments: nil)
    }

    @objc private func trailingTapped(_ sender: UIBarButtonItem) {
        channel.invokeMethod("onTrailingTapped", arguments: ["index": sender.tag])
    }
}

extension UIColor {
    convenience init(argb: Int64) {
        let a = CGFloat((argb >> 24) & 0xFF) / 255.0
        let r = CGFloat((argb >> 16) & 0xFF) / 255.0
        let g = CGFloat((argb >> 8) & 0xFF) / 255.0
        let b = CGFloat(argb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
