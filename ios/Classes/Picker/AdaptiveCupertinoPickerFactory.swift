import Flutter
import UIKit
import os.log

/// Platform View Factory for Adaptive Cupertino Picker
@available(iOS 15.0, *)
class AdaptiveCupertinoPickerFactory: NSObject, FlutterPlatformViewFactory {
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
        return AdaptiveCupertinoPickerPlatformView(
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

/// Platform View wrapper for UIDatePicker with Glass support
@available(iOS 15.0, *)
class AdaptiveCupertinoPickerPlatformView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var picker: UIDatePicker!
    private let messenger: FlutterBinaryMessenger
    private let channel: FlutterMethodChannel
    private static let logger = OSLog(subsystem: "com.adaptive_cupertino_ios", category: "PickerFactory")

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        self.messenger = messenger
        self._view = UIView(frame: frame)
        self.channel = FlutterMethodChannel(
            name: "adaptive_cupertino_ios/picker_\(viewId)",
            binaryMessenger: messenger
        )
        super.init()

        setupPicker(arguments: args)
        setupMethodChannel()
    }

    func view() -> UIView {
        return _view
    }

    private func setupPicker(arguments args: Any?) {
        guard let params = args as? [String: Any] else {
            os_log(.error, log: Self.logger, "Invalid arguments for Picker")
            return
        }

        let modeString = params["mode"] as? String ?? "date"
        let initialTimestamp = params["initialDate"] as? Double ?? Date().timeIntervalSince1970
        let minTimestamp = params["minDate"] as? Double
        let maxTimestamp = params["maxDate"] as? Double
        let useGlass = params["useGlass"] as? Bool ?? true

        picker = UIDatePicker()
        picker.date = Date(timeIntervalSince1970: initialTimestamp)
        
        if let min = minTimestamp { picker.minimumDate = Date(timeIntervalSince1970: min) }
        if let max = maxTimestamp { picker.maximumDate = Date(timeIntervalSince1970: max) }

        switch modeString {
        case "time":
            picker.datePickerMode = .time
        case "dateAndTime":
            picker.datePickerMode = .dateAndTime
        default:
            picker.datePickerMode = .date
        }

        if #available(iOS 14.0, *) {
            picker.preferredDatePickerStyle = .wheels // High-fidelity classic wheels
        }

        picker.translatesAutoresizingMaskIntoConstraints = false
        
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
            
            AdaptiveGlassHelper.configureModernGeometry(for: _view, radius: 20.0)
        }

        _view.addSubview(picker)

        NSLayoutConstraint.activate([
            picker.centerXAnchor.constraint(equalTo: _view.centerXAnchor),
            picker.centerYAnchor.constraint(equalTo: _view.centerYAnchor),
            picker.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
            picker.trailingAnchor.constraint(equalTo: _view.trailingAnchor)
        ])
        
        picker.addTarget(self, action: #selector(pickerChanged), for: .valueChanged)
        
        os_log(.info, log: Self.logger, "Native Picker initialized (Mode: %{public}@)", modeString)
    }

    private func setupMethodChannel() {
        channel.setMethodCallHandler { [weak self] (call, result) in
            guard let self = self else { return }
            switch call.method {
            case "setDate":
                if let args = call.arguments as? [String: Any],
                   let timestamp = args["date"] as? Double {
                    self.picker.setDate(Date(timeIntervalSince1970: timestamp), animated: true)
                    result(nil)
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    @objc private func pickerChanged() {
        channel.invokeMethod("onChanged", arguments: ["date": picker.date.timeIntervalSince1970])
    }
}
