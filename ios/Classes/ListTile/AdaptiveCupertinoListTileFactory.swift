import Flutter
import UIKit
import os.log

/// Platform View Factory for Adaptive Cupertino List Tile
@available(iOS 15.0, *)
class AdaptiveCupertinoListTileFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger
    private let registrar: FlutterPluginRegistrar
    private let fontLoader: FlutterFontLoader

    init(messenger: FlutterBinaryMessenger, registrar: FlutterPluginRegistrar) {
        self.messenger = messenger
        self.registrar = registrar
        self.fontLoader = FlutterFontLoader(registrar: registrar)
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return AdaptiveCupertinoListTilePlatformView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args as? [String: Any] ?? [:],
            messenger: messenger,
            registrar: registrar,
            fontLoader: fontLoader
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

/// Platform View for Adaptive Cupertino List Tile
@available(iOS 15.0, *)
class AdaptiveCupertinoListTilePlatformView: NSObject, FlutterPlatformView {
    private let frame: CGRect
    private let viewIdentifier: Int64
    private let channel: FlutterMethodChannel
    private let registrar: FlutterPluginRegistrar
    private let fontLoader: FlutterFontLoader
    
    private var _view: UIView!
    private var containerStack: UIStackView!
    private var mainStack: UIStackView!
    private var titleLabel: UILabel!
    private var subtitleLabel: UILabel!
    
    // Store actions for context menu
    private var contextMenuActions: [[String: Any]]?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments params: [String: Any],
        messenger: FlutterBinaryMessenger,
        registrar: FlutterPluginRegistrar,
        fontLoader: FlutterFontLoader
    ) {
        self.frame = frame
        self.viewIdentifier = viewId
        self.channel = FlutterMethodChannel(
            name: "adaptive_cupertino_ios/list_tile_\(viewId)",
            binaryMessenger: messenger
        )
        self.registrar = registrar
        self.fontLoader = fontLoader
        super.init()
        
        setupViews()
        setupTile(params: params)
    }

    func view() -> UIView {
        return _view
    }

    private func setupViews() {
        _view = UIView(frame: frame)
        _view.backgroundColor = .clear
        
        containerStack = UIStackView()
        containerStack.axis = .horizontal
        containerStack.spacing = 12 // Reduced from 16 for tighter icon-text proximity
        containerStack.alignment = .center
        containerStack.translatesAutoresizingMaskIntoConstraints = false
        
        // REFINED: Balanced iOS List Tile Padding
        containerStack.isLayoutMarginsRelativeArrangement = true
        containerStack.layoutMargins = UIEdgeInsets(top: 11, left: 16, bottom: 11, right: 16)
        
        _view.addSubview(containerStack)
        
        NSLayoutConstraint.activate([
            containerStack.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            containerStack.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
            containerStack.topAnchor.constraint(equalTo: _view.topAnchor),
            containerStack.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
        ])
        
        mainStack = UIStackView()
        mainStack.axis = .vertical
        mainStack.spacing = 0 
        mainStack.alignment = .leading
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Push trailing elements to the right by having mainStack fill space
        // We use a very low priority to ensure it's the first one to stretch
        mainStack.setContentHuggingPriority(UILayoutPriority(rawValue: 1), for: .horizontal)
        mainStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        containerStack.distribution = .fill
        
        titleLabel = UILabel()
        titleLabel.font = .systemFont(ofSize: 17, weight: .regular)
        titleLabel.textColor = .label
        
        subtitleLabel = UILabel()
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 1
        
        mainStack.addArrangedSubview(titleLabel)
        mainStack.addArrangedSubview(subtitleLabel)
        
        containerStack.addArrangedSubview(mainStack)
    }

    private func setupTile(params: [String: Any]) {
        // Clear existing accessories to prevent duplication on updates
        containerStack.arrangedSubviews.forEach { view in
            if view !== mainStack {
                view.removeFromSuperview()
            }
        }

        if let title = params["title"] as? String {
            titleLabel.text = title
        }
        
        if let subtitle = params["subtitle"] as? String {
            subtitleLabel.text = subtitle
            subtitleLabel.isHidden = false
            mainStack.spacing = 2 // Restore spacing if subtitle exists
        } else {
            subtitleLabel.isHidden = true
            mainStack.spacing = 0
        }

        // Leading Component
        if let leadingData = params["leading"] as? [String: Any] {
            if let view = createAccessoryView(data: leadingData) {
                containerStack.insertArrangedSubview(view, at: 0)
            }
        }

        // Trailing Component
        if let trailingData = params["trailing"] as? [String: Any] {
            if let view = createAccessoryView(data: trailingData) {
                containerStack.addArrangedSubview(view)
            }
        }
        
        // Context Menu Actions
        if let actions = params["contextMenuActions"] as? [[String: Any]] {
            self.contextMenuActions = actions
            let interaction = UIContextMenuInteraction(delegate: self)
            containerStack.addInteraction(interaction)
        }
        
        // Background / Padding refinement could go here for "iOS 26" aesthetic
    }

    private func createAccessoryView(data: [String: Any]) -> UIView? {
        guard let type = data["type"] as? String else { return nil }
        
        if type == "switch" {
            let uiSwitch = UISwitch()
            uiSwitch.isOn = data["value"] as? Bool ?? false
            uiSwitch.addTarget(self, action: #selector(onSwitchChanged(_:)), for: .valueChanged)
            
            // Required for stack view to prioritize stretching the mainStack
            uiSwitch.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            
            return uiSwitch
            
        } else if type == "badge" {
            let badgeContainer = UIView()
            badgeContainer.clipsToBounds = true

            // NEW: Support for SF Symbols and Effects in ListTile Badges
            let sfSymbol = data["sfSymbol"] as? String
            let effect = data["effect"] as? String
            let useGlass = data["useGlass"] as? Bool ?? false
            
            var tintColor: UIColor = .white
            if let labelColorVal = data["labelColor"] as? Int64 {
                tintColor = UIColor(red: CGFloat((labelColorVal >> 16) & 0xFF) / 255.0,
                                     green: CGFloat((labelColorVal >> 8) & 0xFF) / 255.0,
                                     blue: CGFloat(labelColorVal & 0xFF) / 255.0,
                                     alpha: CGFloat((labelColorVal >> 24) & 0xFF) / 255.0)
            }
            
            var bgColor: UIColor = .systemRed
            if let bgColorVal = data["backgroundColor"] as? Int64 {
                bgColor = UIColor(red: CGFloat((bgColorVal >> 16) & 0xFF) / 255.0,
                                   green: CGFloat((bgColorVal >> 8) & 0xFF) / 255.0,
                                   blue: CGFloat(bgColorVal & 0xFF) / 255.0,
                                   alpha: CGFloat((bgColorVal >> 24) & 0xFF) / 255.0)
            }

            var contentView: UIView
            if let symbolName = sfSymbol, let symbolImage = UIImage(systemName: symbolName) {
                let imageView = UIImageView(image: symbolImage)
                imageView.contentMode = .scaleAspectFit
                imageView.tintColor = tintColor
                imageView.translatesAutoresizingMaskIntoConstraints = false
                
                // iOS 17+ Symbol Effects
                if #available(iOS 17.0, *), let effectName = effect {
                    let isRepeating = data["isRepeating"] as? Bool ?? true
                    let options: SymbolEffectOptions = isRepeating ? .repeating : .default
                    
                    switch effectName {
                    case "pulse": imageView.addSymbolEffect(.pulse, options: options)
                    case "bounce": imageView.addSymbolEffect(.bounce, options: options)
                    case "variableColor": imageView.addSymbolEffect(.variableColor, options: options)
                    case "scale": imageView.addSymbolEffect(.scale, options: options)
                    default: break
                    }
                }
                contentView = imageView
                
                NSLayoutConstraint.activate([
                    contentView.widthAnchor.constraint(equalToConstant: 16),
                    contentView.heightAnchor.constraint(equalToConstant: 16)
                ])
            } else {
                let label = UILabel()
                label.text = data["text"] as? String ?? ""
                label.font = .systemFont(ofSize: 12, weight: .bold)
                label.textColor = tintColor
                label.translatesAutoresizingMaskIntoConstraints = false
                contentView = label
            }

            if useGlass {
                let glass = AdaptiveGlassView(frame: .zero, isInteractive: false, variant: 0, applyGeometry: true)
                glass.translatesAutoresizingMaskIntoConstraints = false
                badgeContainer.addSubview(glass)
                NSLayoutConstraint.activate([
                    glass.leadingAnchor.constraint(equalTo: badgeContainer.leadingAnchor),
                    glass.trailingAnchor.constraint(equalTo: badgeContainer.trailingAnchor),
                    glass.topAnchor.constraint(equalTo: badgeContainer.topAnchor),
                    glass.bottomAnchor.constraint(equalTo: badgeContainer.bottomAnchor)
                ])
                AdaptiveGlassHelper.configureModernGeometry(for: badgeContainer, radius: 10.0)
            } else {
                badgeContainer.backgroundColor = bgColor
                badgeContainer.layer.cornerRadius = 10.0
            }
            
            badgeContainer.addSubview(contentView)
            
            NSLayoutConstraint.activate([
                contentView.centerXAnchor.constraint(equalTo: badgeContainer.centerXAnchor),
                contentView.centerYAnchor.constraint(equalTo: badgeContainer.centerYAnchor),
                badgeContainer.widthAnchor.constraint(greaterThanOrEqualToConstant: 24),
                badgeContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 24),
                contentView.leadingAnchor.constraint(equalTo: badgeContainer.leadingAnchor, constant: 8),
                contentView.trailingAnchor.constraint(equalTo: badgeContainer.trailingAnchor, constant: -8),
                contentView.topAnchor.constraint(equalTo: badgeContainer.topAnchor, constant: 4),
                contentView.bottomAnchor.constraint(equalTo: badgeContainer.bottomAnchor, constant: -4)
            ])
            
            // Required for stack view to prioritize stretching the mainStack
            // Set to .required (1000) to absolutely prevent horizontal stretching
            badgeContainer.setContentHuggingPriority(.required, for: .horizontal)
            badgeContainer.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            return badgeContainer

        } else if type == "icon" {
             // Priority 1: SF Symbol (Preferred for Native Feel)
             if let sfSymbol = data["iconName"] as? String {
                 let config = UIImage.SymbolConfiguration(scale: .medium)
                 let image = UIImage(systemName: sfSymbol, withConfiguration: config)
                 let imageView = UIImageView(image: image)
                 imageView.tintColor = .secondaryLabel
                 imageView.contentMode = .scaleAspectFit
                 
                 imageView.translatesAutoresizingMaskIntoConstraints = false
                 NSLayoutConstraint.activate([
                     imageView.widthAnchor.constraint(equalToConstant: 24),
                     imageView.heightAnchor.constraint(equalToConstant: 24)
                 ])
                 
                 // Required for stack view to prioritize stretching the mainStack
                 imageView.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                 
                 return imageView
             }
            
             // Priority 2: Generic Flutter Icon (Fallback)
             if let iconCode = data["iconCode"] as? Int {
                 let iconLabel = UILabel()
                 iconLabel.text = String(UnicodeScalar(iconCode)!)
                 iconLabel.textAlignment = .center
                 
                 if let fontFamily = data["iconFamily"] as? String {
                     let iconPackage = data["iconPackage"] as? String
                     // Try to load the font dynamically via shared loader
                     if let font = fontLoader.loadFont(name: fontFamily, size: 24, package: iconPackage) {
                        iconLabel.font = font
                     } else {
                        // Fallback if font fails
                        iconLabel.font = .systemFont(ofSize: 24)
                     }
                 }
                 
                 iconLabel.translatesAutoresizingMaskIntoConstraints = false
                 NSLayoutConstraint.activate([
                     iconLabel.widthAnchor.constraint(equalToConstant: 24),
                     iconLabel.heightAnchor.constraint(equalToConstant: 24)
                 ])
                 
                 iconLabel.textColor = .secondaryLabel
                 
                 // Required for stack view to prioritize stretching the mainStack
                 iconLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
                 
                 return iconLabel
             }
             
        } else if type == "text", let text = data["data"] as? String {
            let label = UILabel()
            label.text = text
            label.font = .systemFont(ofSize: 15)
            label.textColor = .secondaryLabel
            
            // Required for stack view to prioritize stretching the mainStack
            label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
            
            return label
        }
        
        return nil
    }

    @objc private func onTapped() {
        channel.invokeMethod("onTap", arguments: nil)
    }

    @objc private func onSwitchChanged(_ sender: UISwitch) {
        channel.invokeMethod("onTrailingChanged", arguments: ["value": sender.isOn])
    }
}

@available(iOS 15.0, *)
extension AdaptiveCupertinoListTilePlatformView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let actions = self.contextMenuActions, !actions.isEmpty else { return nil }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            var menuElements: [UIMenuElement] = []
            
            for (index, actionMap) in actions.enumerated() {
                let title = actionMap["label"] as? String ?? "Action"
                let isDestructive = actionMap["isDestructive"] as? Bool ?? false
                let iconName = actionMap["icon"] as? String
                
                var attributes: UIMenuElement.Attributes = []
                if isDestructive {
                    attributes.insert(.destructive)
                }
                
                let image = iconName != nil ? UIImage(systemName: iconName!) : nil
                
                let action = UIAction(title: title, image: image, attributes: attributes) { _ in
                    self.channel.invokeMethod("onContextMenuAction", arguments: ["index": index])
                }
                menuElements.append(action)
            }
            
            return UIMenu(title: "", children: menuElements)
        }
    }
}
