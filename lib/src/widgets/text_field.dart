import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'widgets/text_field_parts.dart';

/// An adaptive text field that provides platform-appropriate styling.
///
/// Supports iOS 26+ Glass style via [useGlass].
class AdaptiveTextField extends StatelessWidget with AdaptiveTextFieldMixin {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? placeholder;
  final bool obscureText;
  final TextInputType? keyboardType;

  /// Whether to use the iOS 26+ Glass aesthetic.
  final bool useGlass;

  const AdaptiveTextField({
    super.key,
    this.controller,
    this.onChanged,
    this.placeholder,
    this.obscureText = false,
    this.keyboardType,
    this.useGlass = false,
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

mixin AdaptiveTextFieldMixin {
  Widget buildCupertino(BuildContext context) {
    final field = this as AdaptiveTextField;
    return _CupertinoTextFieldWidget(
      controller: field.controller,
      onChanged: field.onChanged,
      placeholder: field.placeholder,
      obscureText: field.obscureText,
      keyboardType: field.keyboardType,
      useGlass: field.useGlass,
    );
  }

  Widget buildMaterial(BuildContext context) {
    final field = this as AdaptiveTextField;
    return _MaterialTextFieldWidget(
      controller: field.controller,
      onChanged: field.onChanged,
      labelText: field.placeholder,
      obscureText: field.obscureText,
      keyboardType: field.keyboardType,
    );
  }
}
