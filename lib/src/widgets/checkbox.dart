import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'widgets/checkbox_parts.dart';

/// An adaptive checkbox that provides platform-appropriate styling.
///
/// Uses [CupertinoCheckbox] on iOS and Material [Checkbox] on Android.
class AdaptiveCheckbox extends StatelessWidget with AdaptiveCheckboxMixin {
  /// Whether this checkbox is checked.
  final bool value;

  /// Called when the value of the checkbox should change.
  final ValueChanged<bool?>? onChanged;

  /// The color to use when this checkbox is checked.
  final Color? activeColor;

  /// The color to use for the check icon when this checkbox is checked.
  final Color? checkColor;

  /// The color to use for the checkbox's border when it is not checked.
  final Color? borderColor;

  const AdaptiveCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.checkColor,
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

mixin AdaptiveCheckboxMixin {
  Widget buildCupertino(BuildContext context) {
    final checkbox = this as AdaptiveCheckbox;
    return _CupertinoCheckboxWidget(
      value: checkbox.value,
      onChanged: checkbox.onChanged,
      activeColor: checkbox.activeColor,
      checkColor: checkbox.checkColor,
      borderColor: checkbox.borderColor,
    );
  }

  Widget buildMaterial(BuildContext context) {
    final checkbox = this as AdaptiveCheckbox;
    return _MaterialCheckboxWidget(
      value: checkbox.value,
      onChanged: checkbox.onChanged,
      activeColor: checkbox.activeColor,
      checkColor: checkbox.checkColor,
    );
  }
}
