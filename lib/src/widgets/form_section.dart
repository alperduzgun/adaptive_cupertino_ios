import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'widgets/form_section_parts.dart';

/// An adaptive form section that provides platform-appropriate grouping.
///
/// Uses [CupertinoFormSection] on iOS and a Material [Card] on Android.
class AdaptiveFormSection extends StatelessWidget
    with AdaptiveFormSectionMixin {
  /// Header text displayed above the section.
  final String? header;

  /// Footer text displayed below the section.
  final String? footer;

  /// The widgets to display inside the section.
  final List<Widget> children;

  /// Whether to use the iOS 26+ Glass aesthetic.
  final bool useGlass;

  const AdaptiveFormSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
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

mixin AdaptiveFormSectionMixin {
  Widget buildCupertino(BuildContext context) {
    final section = this as AdaptiveFormSection;
    return _CupertinoFormSectionWidget(
      header: section.header,
      footer: section.footer,
      children: section.children,
      useGlass: section.useGlass,
    );
  }

  Widget buildMaterial(BuildContext context) {
    final section = this as AdaptiveFormSection;
    return _MaterialFormSectionWidget(
      header: section.header,
      children: section.children,
    );
  }
}
