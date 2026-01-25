import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// An adaptive segmented control that uses native iOS 26+ UISegmentedControl
/// with fallback to CupertinoSegmentedControl (iOS < 26) or custom widget.
class AdaptiveSegmentedControl<T extends Object> extends StatelessWidget {
  /// The list of values for each segment.
  final List<T> values;

  /// The list of labels for each segment.
  /// If [useSFSymbols] is true, these should be SF Symbol names.
  final List<String> labels;

  /// The currently selected value.
  final T selectedValue;

  /// Called when the user selects a new segment.
  final ValueChanged<T> onValueChanged;

  /// Whether to treat labels as SF Symbol names on iOS 26+.
  final bool useSFSymbols;

  /// Optional builder for custom fallback on iOS < 26 or Android.
  /// If null, uses [CupertinoSegmentedControl] on iOS and [SegmentedButton] on Android.
  final Widget Function(BuildContext context, T selectedValue,
      ValueChanged<T> onValueChanged)? fallbackBuilder;

  /// Tint color for the selected segment (iOS 26+ native).
  final Color? tintColor;

  /// Font color for the segment labels.
  final Color? textColor;

  /// Whether the control is enabled.
  final bool enabled;

  const AdaptiveSegmentedControl({
    super.key,
    required this.values,
    required this.labels,
    required this.selectedValue,
    required this.onValueChanged,
    this.useSFSymbols = false,
    this.fallbackBuilder,
    this.tintColor,
    this.textColor,
    this.enabled = true,
  }) : assert(values.length == labels.length,
            'Values and labels must have the same length');

  @override
  Widget build(BuildContext context) {
    // Check if we are on iOS 26+ (Placeholder version for Quartz/Glass design)
    // In a real scenario, this would check the system version.
    // For now, we simulate iOS 26+ support.
    final bool isIOS26 = defaultTargetPlatform ==
        TargetPlatform.iOS; // TODO: Implement real version check

    if (isIOS26) {
      return _buildNativeIOS26(context);
    }

    if (fallbackBuilder != null) {
      return fallbackBuilder!(context, selectedValue, onValueChanged);
    }

    return _buildDefaultFallback(context);
  }

  Widget _buildNativeIOS26(BuildContext context) {
    final int selectedIndex = values.indexOf(selectedValue);

    return SizedBox(
      height: 32, // Standard iOS segmented control height
      child: UiKitView(
        viewType: 'adaptive_cupertino_ios/segmented_control',
        creationParams: {
          'labels': !useSFSymbols ? labels : null,
          'sfSymbols': useSFSymbols ? labels : null,
          'selectedIndex': selectedIndex,
          'enabled': enabled,
          'tintColor': tintColor?.toARGB32(),
          'textColor': textColor?.toARGB32(),
          'isDark': CupertinoTheme.of(context).brightness == Brightness.dark,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (int id) {
          final channel =
              MethodChannel('adaptive_platform_ui/ios26_segmented_control_$id');
          channel.setMethodCallHandler((call) async {
            if (call.method == 'valueChanged') {
              final int index = call.arguments['index'];
              if (index >= 0 && index < values.length) {
                onValueChanged(values[index]);
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
      Widget control = CupertinoSegmentedControl<T>(
        groupValue: selectedValue,
        onValueChanged: onValueChanged,
        children: {
          for (var i = 0; i < values.length; i++)
            values[i]: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(labels[i]),
            ),
        },
      );

      if (!enabled) {
        return Opacity(
          opacity: 0.5,
          child: IgnorePointer(child: control),
        );
      }
      return control;
    }

    // Material 3 Fallback
    return SegmentedButton<T>(
      segments: [
        for (var i = 0; i < values.length; i++)
          ButtonSegment<T>(
            value: values[i],
            label: Text(labels[i]),
            enabled: enabled, // ButtonSegment has enabled parameter
          ),
      ],
      selected: {selectedValue},
      onSelectionChanged: enabled
          ? (Set<T> newSelection) {
              onValueChanged(newSelection.first);
            }
          : null, // Null callback disables the button selection logic
    );
  }
}
