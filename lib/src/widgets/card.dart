import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'glass_box.dart';

part 'widgets/card_parts.dart';

/// An adaptive card that provides platform-appropriate styling.
///
/// Uses [AdaptiveGlassBox] on iOS 18+ and Material [Card] on Android.
class AdaptiveCard extends StatelessWidget with AdaptiveCardMixin {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  /// Whether to use the iOS 26+ Glass aesthetic.
  final bool useGlass;

  const AdaptiveCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16.0,
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

mixin AdaptiveCardMixin {
  Widget buildCupertino(BuildContext context) {
    final card = this as AdaptiveCard;
    return _CupertinoCardWidget(
      padding: card.padding,
      borderRadius: card.borderRadius,
      useGlass: card.useGlass,
      child: card.child,
    );
  }

  Widget buildMaterial(BuildContext context) {
    final card = this as AdaptiveCard;
    return _MaterialCardWidget(
      padding: card.padding,
      borderRadius: card.borderRadius,
      child: card.child,
    );
  }
}
