import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// An adaptive switch that uses native iOS 26+ UISwitch
/// with fallback to CupertinoSwitch (iOS < 26) or Material Switch.
class AdaptiveSwitch extends StatelessWidget {
  /// Whether this switch is on or off.
  final bool value;

  /// Called when the user toggles the switch on or off.
  final ValueChanged<bool>? onChanged;

  /// The color to use when this switch is on.
  final Color? activeColor;

  /// The color to use for the thumb.
  final Color? thumbColor;

  /// The color to use for the track.
  final Color? trackColor;

  /// Whether to use the native iOS 26+ implementation if available.
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
  Widget build(BuildContext context) {
    // Check if we are on iOS 26+ (Placeholder version for Quartz/Glass design)
    // In a real scenario, this would check the system version.
    // For now, we simulate iOS 26+ support if useNative is true.
    final bool isIOS26 = useNative &&
        defaultTargetPlatform ==
            TargetPlatform.iOS; // TODO: Implement real version check

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
          'isOn': value,
          'activeColor': activeColor?.value,
          'thumbColor': thumbColor?.value,
          'trackColor': trackColor?.value,
          'enabled': onChanged != null,
        },
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(
            () => EagerGestureRecognizer(),
          ),
        },
        onPlatformViewCreated: (int id) {
          final channel = MethodChannel('adaptive_platform_ui/switch_$id');
          channel.setMethodCallHandler((call) async {
            if (call.method == 'valueChanged') {
              final bool newValue = call.arguments['value'];
              if (onChanged != null) {
                onChanged!(newValue);
              }
            }
          });
        },
      ),
    );
  }

  Widget _buildDefaultFallback(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS) {
      return CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
        thumbColor: thumbColor,
      );
    }

    // Material Fallback
    return Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
      inactiveThumbColor: thumbColor,
      inactiveTrackColor: trackColor,
    );
  }
}
