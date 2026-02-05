import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'button.dart'; // For AdaptiveButtonStyle

/// A native container that applies the "Liquid Glass" (iOS 26) material.
///
/// This provides a larger surface area than a button to observe
/// light refraction and lensing effects.
class AdaptiveGlassBox extends StatelessWidget {
  /// The style configuration for the glass material.
  final AdaptiveButtonStyle style;

  /// The child widget to place inside the glass container.
  final Widget? child;

  /// The corner radius of the glass container.
  final double borderRadius;

  /// Unique identifier for Liquid Morphing (iOS 26+).
  final String? glassEffectID;

  const AdaptiveGlassBox({
    super.key,
    this.style = AdaptiveButtonStyle.glass,
    this.borderRadius = 20.0,
    this.glassEffectID,
    this.child,
  });

  int _getVariant() {
    switch (style) {
      case AdaptiveButtonStyle.glassClear:
        return 1;
      case AdaptiveButtonStyle.glassIdentity:
        return 2;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // CHAOS SAFETY: Prevent NaN from breaking platform view frame
    final double safeRadius =
        (borderRadius.isNaN || borderRadius.isInfinite) ? 0.0 : borderRadius;

    return LayoutBuilder(builder: (context, constraints) {
      final double width = constraints.hasBoundedWidth
          ? constraints.maxWidth
          : (constraints.minWidth > 0 ? constraints.minWidth : 100.0);
      final double height = constraints.hasBoundedHeight
          ? constraints.maxHeight
          : (constraints.minHeight > 0 ? constraints.minHeight : 100.0);

      return Stack(
        children: [
          SizedBox(
            width: width,
            height: height,
            child: UiKitView(
              viewType: 'adaptive_cupertino_ios/glass_box',
              creationParams: {
                'variant': _getVariant(),
                'borderRadius': safeRadius,
                if (glassEffectID != null) 'glassEffectID': glassEffectID,
              },
              creationParamsCodec: const StandardMessageCodec(),
            ),
          ),
          if (child != null) child!,
        ],
      );
    });
  }
}
