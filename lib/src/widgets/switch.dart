import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// An adaptive switch that uses native iOS 26+ UISwitch
/// with fallback to CupertinoSwitch (iOS < 26) or Material Switch.
class AdaptiveSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? thumbColor;
  final Color? trackColor;
  final bool useNative;

  const AdaptiveSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.thumbColor,
    this.trackColor,
    this.useNative = true,
  });

  @override
  State<AdaptiveSwitch> createState() => _AdaptiveSwitchState();
}

class _AdaptiveSwitchState extends State<AdaptiveSwitch> {
  MethodChannel? _channel;

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('adaptive_platform_ui/switch_$id');
    _channel?.setMethodCallHandler((call) async {
      if (call.method == 'valueChanged') {
        final bool newValue = call.arguments['value'];
        if (widget.onChanged != null) {
          widget.onChanged!(newValue);
        }
      }
    });
  }

  @override
  void didUpdateWidget(AdaptiveSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _channel?.invokeMethod('setValue', {'value': widget.value});
    }
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isIOS26 =
        widget.useNative && defaultTargetPlatform == TargetPlatform.iOS;

    if (isIOS26) {
      return _buildNativeIOS26(context);
    }

    return _buildDefaultFallback(context);
  }

  Widget _buildNativeIOS26(BuildContext context) {
    return SizedBox(
      width: 51,
      height: 31,
      child: UiKitView(
        viewType: 'adaptive_cupertino_ios/switch',
        creationParams: {
          'isOn': widget.value,
          'activeColor': widget.activeColor?.value,
          'thumbColor': widget.thumbColor?.value,
          'trackColor': widget.trackColor?.value,
          'enabled': widget.onChanged != null,
        },
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(
            () => EagerGestureRecognizer(),
          ),
        },
        onPlatformViewCreated: _onPlatformViewCreated,
      ),
    );
  }

  Widget _buildDefaultFallback(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS) {
      return CupertinoSwitch(
        value: widget.value,
        onChanged: widget.onChanged,
        activeColor: widget.activeColor,
        thumbColor: widget.thumbColor,
      );
    }

    return Switch.adaptive(
      value: widget.value,
      onChanged: widget.onChanged,
      activeColor: widget.activeColor,
      inactiveThumbColor: widget.thumbColor,
      inactiveTrackColor: widget.trackColor,
    );
  }
}
