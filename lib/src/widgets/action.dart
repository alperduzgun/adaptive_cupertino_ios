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

  /// Whether this action should share background with adjacent actions (iOS 26 grouping).
  ///
  /// Defaults to true (grouped). Set to false to force a separate pill.
  final bool sharesBackground;

  /// The SF Symbol name to use (preferred over IconData for iOS).
  final String? sfSymbolName;

  const AdaptiveCupertinoAction({
    this.icon,
    this.label,
    this.onPressed,
    this.isDestructive = false,
    this.sfSymbolName,
    this.sharesBackground = true,
  });

  /// Convert to map for platform channel.
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {};

    if (sfSymbolName != null) {
      data['type'] = 'icon';
      data['iconName'] = sfSymbolName;
    } else if (icon != null) {
      data['type'] = 'icon';
      data['iconCode'] = icon!.codePoint;
      data['iconFamily'] = icon!.fontFamily;
    } else if (label != null) {
      data['type'] = 'text';
      data['label'] = label;
    }

    if (isDestructive) {
      data['isDestructive'] = true;
    }

    // Pass sharing preference (native uses inverse 'hidesSharedBackground', but we pass positive logic here)
    // The native factory maps this: sharesBackground -> !hidesSharedBackground
    data['sharesBackground'] = sharesBackground;

    return data;
  }
}
