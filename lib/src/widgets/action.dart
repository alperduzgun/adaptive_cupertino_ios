import 'package:flutter/widgets.dart';

/// A platform-agnostic action model for native UI components (AppBar, Toolbar).
///
/// This model passes raw data (IconData, String) to the native side,
/// bypassing widget serialization issues and ensuring reliability.
class AdaptiveCupertinoAction {
  /// The icon to display.
  final IconData? icon;

  /// The text label to display (if icon is null or for accessibility).
  final String? label;

  /// Callback when the action is triggered.
  final VoidCallback? onPressed;

  /// Whether this action is destructive (e.g. delete).
  final bool isDestructive;

  const AdaptiveCupertinoAction({
    this.icon,
    this.label,
    this.onPressed,
    this.isDestructive = false,
  });

  /// Convert to map for platform channel.
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {};

    if (icon != null) {
      data['type'] = 'icon';
      data['iconCode'] = icon!.codePoint;
      data['iconFamily'] = icon!.fontFamily;
      // Note: fontPackage handling depends on native font loader logic.
      // Usually "CupertinoIcons" family string is sufficient.
    } else if (label != null) {
      data['type'] = 'text';
      data['label'] = label;
    }

    if (isDestructive) {
      data['isDestructive'] = true;
    }

    return data;
  }
}
