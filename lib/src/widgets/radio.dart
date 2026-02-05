import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'widgets/radio_parts.dart';

/// An adaptive radio button that provides platform-appropriate styling.
///
/// Uses [CupertinoRadio] on iOS and Material [Radio] on Android.
class AdaptiveRadio<T> extends StatelessWidget with AdaptiveRadioMixin<T> {
  /// The value represented by this radio button.
  final T value;

  /// The currently selected value for this group of radio buttons.
  final T? groupValue;

  /// Called when the user selects this radio button.
  final ValueChanged<T?>? onChanged;

  /// The color to use when this radio button is selected.
  final Color? activeColor;

  /// The color to use for the radio button's border when it is not selected (iOS only).
  final Color? borderColor;

  const AdaptiveRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.activeColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS) {
      return buildCupertino(context);
    }

    return buildMaterial(context);
  }
}

mixin AdaptiveRadioMixin<T> {
  Widget buildCupertino(BuildContext context) {
    final radio = this as AdaptiveRadio<T>;
    return _CupertinoRadioWidget<T>(
      value: radio.value,
      groupValue: radio.groupValue,
      onChanged: radio.onChanged,
      activeColor: radio.activeColor,
      borderColor: radio.borderColor,
    );
  }

  Widget buildMaterial(BuildContext context) {
    final radio = this as AdaptiveRadio<T>;
    return _MaterialRadioWidget<T>(
      value: radio.value,
      groupValue: radio.groupValue,
      onChanged: radio.onChanged,
      activeColor: radio.activeColor,
    );
  }
}
