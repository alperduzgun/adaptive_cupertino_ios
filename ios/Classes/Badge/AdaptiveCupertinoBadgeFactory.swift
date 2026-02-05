import Flutter
import UIKit
import os.log
import Symbols

/// Platform View Factory for Adaptive Cupertino Badge
@available(iOS 15.0, *)
class AdaptiveCupertinoBadgeFactory: NSObject, FlutterPlatformViewFactory {
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
        return AdaptiveCupertinoBadgePlatformView(
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

/// Platform View wrapper for Badge with Glass support
@available(iOS 15.0, *)
class AdaptiveCupertinoBadgePlatformView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private let messenger: FlutterBinaryMessenger
    private static let logger = OSLog(subsystem: "com.adaptive_cupertino_ios", category: "BadgeFactory")

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        self.messenger = messenger
        self._view = UIView(frame: frame)
        self._view.backgroundColor = .clear
        self._view.isOpaque = false
        super.init()

        setupBadge(arguments: args)
    }

    func view() -> UIView {
        return _view
    }

    private func setupBadge(arguments args: Any?) {
        guard let params = args as? [String: Any] else { return }

        let label = params["label"] as? String ?? ""
        let sfSymbol = params["sfSymbol"] as? String
        let effect = params["effect"] as? String
        let useGlass = params["useGlass"] as? Bool ?? false
        
        // Color Parsing
        var tintColor: UIColor = .white
        if let labelColorVal = params["labelColor"] as? Int64 {
             tintColor = UIColor(red: CGFloat((labelColorVal >> 16) & 0xFF) / 255.0,
                                 green: CGFloat((labelColorVal >> 8) & 0xFF) / 255.0,
                                 blue: CGFloat(labelColorVal & 0xFF) / 255.0,
                                 alpha: CGFloat((labelColorVal >> 24) & 0xFF) / 255.0)
        }
        
        var bgColor: UIColor = .systemRed
        if let bgColorVal = params["backgroundColor"] as? Int64 {
             bgColor = UIColor(red: CGFloat((bgColorVal >> 16) & 0xFF) / 255.0,
                                 green: CGFloat((bgColorVal >> 8) & 0xFF) / 255.0,
                                 blue: CGFloat(bgColorVal & 0xFF) / 255.0,
                                 alpha: CGFloat((bgColorVal >> 24) & 0xFF) / 255.0)
        }

        // Determine content view (Label or ImageView)
        var contentView: UIView

        if let symbolName = sfSymbol, let symbolImage = UIImage(systemName: symbolName) {
            let imageView = UIImageView(image: symbolImage)
            imageView.contentMode = .scaleAspectFit
            imageView.tintColor = tintColor
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            // iOS 17+ Symbol Effects
            if #available(iOS 17.0, *), let effectName = effect {
                let isRepeating = params["isRepeating"] as? Bool ?? false
                let options: SymbolEffectOptions = isRepeating ? .repeating : .default
                
                switch effectName {
                case "pulse":
                    imageView.addSymbolEffect(.pulse, options: options)
                case "bounce":
                    imageView.addSymbolEffect(.bounce, options: options)
                case "variableColor":
                    imageView.addSymbolEffect(.variableColor, options: options)
                case "scale":
                    imageView.addSymbolEffect(.scale, options: options)
                default:
                    break
                }
            }
            contentView = imageView
        } else {
            let badgeLabel = UILabel()
            badgeLabel.text = label
            badgeLabel.textColor = tintColor
            badgeLabel.font = UIFont.systemFont(ofSize: 12, weight: .bold)
            badgeLabel.textAlignment = .center
            badgeLabel.translatesAutoresizingMaskIntoConstraints = false
            contentView = badgeLabel
        }

        if useGlass {
            let glass = AdaptiveGlassView(frame: .zero, isInteractive: false, variant: 0, applyGeometry: true)
            glass.translatesAutoresizingMaskIntoConstraints = false
            _view.addSubview(glass)
            NSLayoutConstraint.activate([
                glass.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                glass.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                glass.topAnchor.constraint(equalTo: _view.topAnchor),
                glass.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
            ])
            AdaptiveGlassHelper.configureModernGeometry(for: _view, radius: 10.0)
            
            // If glass, and we have a custom BG color, maybe we should tint the glass?
            // For now, let's keep glass clean.
        } else {
            _view.backgroundColor = bgColor
            _view.layer.cornerRadius = 10.0
        }

        _view.addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.centerXAnchor.constraint(equalTo: _view.centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: _view.centerYAnchor),
            // Adjust constraints based on content type
            contentView.leadingAnchor.constraint(greaterThanOrEqualTo: _view.leadingAnchor, constant: 4),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: _view.trailingAnchor, constant: -4)
        ])
        
        // Ensure icon calls don't get squashed if they are the only content
        if sfSymbol != nil {
             NSLayoutConstraint.activate([
                contentView.heightAnchor.constraint(equalToConstant: 14),
                contentView.widthAnchor.constraint(equalToConstant: 14)
            ])
        }
    }
}
