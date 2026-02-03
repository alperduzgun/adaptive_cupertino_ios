import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// An adaptive slider that uses native iOS 26+ UISlider
/// with fallback to CupertinoSlider (iOS < 26) or Material Slider.
class AdaptiveSlider extends StatelessWidget {
  /// The currently selected value for this slider.
  final double value;

  /// Called during a drag when the user is selecting a new value for the slider
  /// by dragging.
  final ValueChanged<double>? onChanged;

  /// Called when the user starts selecting a new value for the slider.
  final ValueChanged<double>? onChangeStart;

  /// Called when the user is done selecting a new value for the slider.
  final ValueChanged<double>? onChangeEnd;

  /// The minimum value the user can select.
  final double min;

  /// The maximum value the user can select.
  final double max;

  /// The number of discrete divisions.
  final int? divisions;

  /// The color to use for the portion of the slider track that is active.
  final Color? activeColor;

  /// The color to use for the thumb.
  final Color? thumbColor;

  /// Whether to use the native iOS 26+ implementation if available.
  final bool useNative;

  const AdaptiveSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.activeColor,
    this.thumbColor,
    this.useNative = true,
  });

  @override
  Widget build(BuildContext context) {
    // Check if we are on iOS 26+ (Placeholder version for Quartz/Glass design)
    // In a real scenario, this would check the system version.
    // For now, we simulate iOS 26+ support.
    final bool isIOS26 = useNative &&
        defaultTargetPlatform ==
            TargetPlatform.iOS; // TODO: Implement real version check

    if (isIOS26) {
      return _buildNativeIOS26(context);
    }

    return _buildDefaultFallback(context);
  }

  Widget _buildNativeIOS26(BuildContext context) {
    // CHAOS SAFETY: Prevent NaN/Infinite from breaking platform view
    var validValue = value;
    if (validValue.isNaN || validValue.isInfinite) validValue = 0.0;
    var validMin = min;
    if (validMin.isNaN || validMin.isInfinite) validMin = 0.0;
    var validMax = max;
    if (validMax.isNaN || validMax.isInfinite) validMax = 1.0;

    return LayoutBuilder(builder: (context, constraints) {
      // Use parent width if finite, otherwise fallback to 200.0
      final double width = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : (constraints.minWidth > 0 ? constraints.minWidth : 200.0);

      return SizedBox(
        width: width,
        height: 44, // Standard touch target height
        child: UiKitView(
          viewType: 'adaptive_cupertino_ios/slider',
          creationParams: {
            'value': validValue,
            'min': validMin,
            'max': validMax,
            'activeColor': activeColor?.value,
            'thumbColor': thumbColor?.value,
            'enabled': onChanged != null,
          },
          creationParamsCodec: const StandardMessageCodec(),
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
          onPlatformViewCreated: (int id) {
            final channel = MethodChannel('adaptive_platform_ui/slider_$id');
            channel.setMethodCallHandler((call) async {
              if (call.method == 'valueChanged') {
                final double newValue = call.arguments['value'];
                if (onChanged != null) {
                  onChanged!(newValue);
                }
              } else if (call.method == 'onChangeStart') {
                final double newValue = call.arguments['value'];
                if (onChangeStart != null) onChangeStart!(newValue);
              } else if (call.method == 'onChangeEnd') {
                final double newValue = call.arguments['value'];
                if (onChangeEnd != null) onChangeEnd!(newValue);
              }
            });
          },
        ),
      );
    });
  }

  Widget _buildDefaultFallback(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS) {
      return CupertinoSlider(
        value: value,
        onChanged: onChanged,
        onChangeStart: onChangeStart,
        onChangeEnd: onChangeEnd,
        min: min,
        max: max,
        divisions: divisions,
        activeColor: activeColor,
        thumbColor: thumbColor ?? CupertinoColors.white,
      );
    }

    // Material Fallback
    return Slider(
      value: value,
      onChanged: onChanged,
      onChangeStart: onChangeStart,
      onChangeEnd: onChangeEnd,
      min: min,
      max: max,
      divisions: divisions,
      activeColor: activeColor,
      thumbColor: thumbColor,
    );
  }
}
