import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'button.dart';

part 'widgets/fab_parts.dart';

/// An adaptive floating action button that provides platform-appropriate styling.
///
/// On iOS, it often manifests as a glass action button in the toolbar or a floating glass pill.
/// On Android, it uses the standard [FloatingActionButton].
class AdaptiveFloatingActionButton extends StatelessWidget
    with AdaptiveFloatingActionButtonMixin {
  final Widget icon;
  final VoidCallback onPressed;
  final Widget? label;
  final String? tooltip;

  /// Whether to use the iOS 26+ Glass aesthetic.
  final bool useGlass;

  const AdaptiveFloatingActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.tooltip,
    this.useGlass = true,
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

mixin AdaptiveFloatingActionButtonMixin {
  Widget buildCupertino(BuildContext context) {
    final fab = this as AdaptiveFloatingActionButton;
    return _CupertinoFABWidget(
      icon: fab.icon,
      onPressed: fab.onPressed,
      label: fab.label,
      useGlass: fab.useGlass,
    );
  }

  Widget buildMaterial(BuildContext context) {
    final fab = this as AdaptiveFloatingActionButton;
    return _MaterialFABWidget(
      icon: fab.icon,
      onPressed: fab.onPressed,
      label: fab.label,
      tooltip: fab.tooltip,
    );
  }
}
