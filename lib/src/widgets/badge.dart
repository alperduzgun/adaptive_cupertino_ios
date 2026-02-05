import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glass_box.dart';

part 'widgets/badge_parts.dart';

/// An adaptive badge that provides platform-appropriate styling.
///
/// Uses [CupertinoBadge] (simulated) on iOS and Material [Badge] on Android.
class AdaptiveBadge extends StatelessWidget with AdaptiveBadgeMixin {
  /// The SF Symbol name to use (iOS 17+).
  ///
  /// If provided, this takes precedence over [label] and renders a native
  /// SF Symbol with optional [effect].
  final String? sfSymbol;

  /// The animation effect to apply to the SF Symbol (iOS 17+).
  ///
  /// Examples: "pulse", "bounce", "variableColor", "scale".
  final String? effect;

  /// The widget that the badge is attached to.
  final Widget child;

  /// The label to display inside the badge.
  final Widget? label;

  /// The color of the badge background.
  final Color? backgroundColor;

  /// The color of the label text/icon.
  final Color? labelColor;

  /// Whether to use the iOS 26+ Glass aesthetic.
  final bool useGlass;

  /// Whether the animation effect should repeat (iOS 17+).
  final bool isRepeating;

  const AdaptiveBadge({
    super.key,
    required this.child,
    this.label,
    this.sfSymbol,
    this.effect,
    this.isRepeating = true,
    this.backgroundColor,
    this.labelColor,
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

mixin AdaptiveBadgeMixin {
  Widget buildCupertino(BuildContext context) {
    final badge = this as AdaptiveBadge;
    return _CupertinoBadgeWidget(
      backgroundColor: badge.backgroundColor,
      labelColor: badge.labelColor,
      useGlass: badge.useGlass,
      label: badge.label,
      sfSymbol: badge.sfSymbol,
      effect: badge.effect,
      isRepeating: badge.isRepeating,
      child: badge.child,
    );
  }

  Widget buildMaterial(BuildContext context) {
    final badge = this as AdaptiveBadge;
    return _MaterialBadgeWidget(
      backgroundColor: badge.backgroundColor,
      labelColor: badge.labelColor,
      label: badge.label,
      child: badge.child,
    );
  }
}
