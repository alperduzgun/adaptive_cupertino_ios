import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'widgets/tooltip_parts.dart';

/// An adaptive tooltip that provides platform-appropriate styling.
///
/// Supports iOS 26+ Glass style via [useGlass].
class AdaptiveTooltip extends StatelessWidget with AdaptiveTooltipMixin {
  /// The message to display in the tooltip.
  final String message;

  /// The widget that the tooltip is attached to.
  final Widget child;

  /// Whether to use the iOS 26+ Glass aesthetic.
  final bool useGlass;

  const AdaptiveTooltip({
    super.key,
    required this.message,
    required this.child,
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

mixin AdaptiveTooltipMixin {
  Widget buildCupertino(BuildContext context) {
    final tooltip = this as AdaptiveTooltip;
    return _CupertinoTooltipWidget(
      message: tooltip.message,
      useGlass: tooltip.useGlass,
      child: tooltip.child,
    );
  }

  Widget buildMaterial(BuildContext context) {
    final tooltip = this as AdaptiveTooltip;
    return _MaterialTooltipWidget(
      message: tooltip.message,
      child: tooltip.child,
    );
  }
}
