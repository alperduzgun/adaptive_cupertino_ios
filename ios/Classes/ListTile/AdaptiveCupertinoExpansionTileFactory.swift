import Flutter
import UIKit
import os.log

/// Platform View Factory for Adaptive Cupertino ExpansionTile
@available(iOS 15.0, *)
class AdaptiveCupertinoExpansionTileFactory: NSObject, FlutterPlatformViewFactory {
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
        return AdaptiveCupertinoExpansionTilePlatformView(
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

/// Platform View wrapper for native disclosure/expansion rows
@available(iOS 15.0, *)
class AdaptiveCupertinoExpansionTilePlatformView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private let titleLabel: UILabel
    private let arrowIcon: UIImageView
    private let messenger: FlutterBinaryMessenger
    private let channel: FlutterMethodChannel
    private static let logger = OSLog(subsystem: "com.adaptive_cupertino_ios", category: "ExpansionTileFactory")
    
    private var isExpanded: Bool = false

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
        self.titleLabel = UILabel()
        self.arrowIcon = UIImageView()
        self.channel = FlutterMethodChannel(
            name: "adaptive_cupertino_ios/expansion_tile_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()

        setupTile(arguments: args)
    }

    func view() -> UIView {
        return _view
    }

    private func setupTile(arguments args: Any?) {
        guard let params = args as? [String: Any] else { return }
        
        let title = params["title"] as? String ?? ""
        let useGlass = params["useGlass"] as? Bool ?? true
        self.isExpanded = params["isExpanded"] as? Bool ?? false
        
        if useGlass {
            let glass = AdaptiveGlassView(frame: .zero, isInteractive: true, variant: 0, applyGeometry: true)
            glass.translatesAutoresizingMaskIntoConstraints = false
            _view.addSubview(glass)
            
            NSLayoutConstraint.activate([
                glass.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                glass.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                glass.topAnchor.constraint(equalTo: _view.topAnchor),
                glass.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
            ])
            AdaptiveGlassHelper.configureModernGeometry(for: _view, radius: 12.0)
        }
        
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        _view.addSubview(titleLabel)
        
        arrowIcon.image = UIImage(systemName: "chevron.right")
        arrowIcon.tintColor = .secondaryLabel
        arrowIcon.translatesAutoresizingMaskIntoConstraints = false
        _view.addSubview(arrowIcon)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: _view.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: _view.centerYAnchor),
            
            arrowIcon.trailingAnchor.constraint(equalTo: _view.trailingAnchor, constant: -16),
            arrowIcon.centerYAnchor.constraint(equalTo: _view.centerYAnchor)
        ])
        
        updateArrow(animated: false)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleExpansion))
        _view.addGestureRecognizer(tap)
        _view.isUserInteractionEnabled = true
    }

    @objc private func toggleExpansion() {
        isExpanded = !isExpanded
        updateArrow(animated: true)
        channel.invokeMethod("onChanged", arguments: ["isExpanded": isExpanded])
    }

    private func updateArrow(animated: Bool) {
        let rotation: CGFloat = isExpanded ? .pi / 2 : 0
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.arrowIcon.transform = CGAffineTransform(rotationAngle: rotation)
            }
        } else {
            self.arrowIcon.transform = CGAffineTransform(rotationAngle: rotation)
        }
    }
}
