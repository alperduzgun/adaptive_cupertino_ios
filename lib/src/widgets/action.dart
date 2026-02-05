import 'package:flutter/widgets.dart';

import '../util/serialization.dart';

/// Style configuration for [AdaptiveCupertinoAction].
enum AdaptiveActionButtonStyle {
  /// Automatically choose based on platform context.
  automatic,

  /// A filled, capsule-shaped button with background color (Stand-alone pill).
  filled,

  /// A standard button with tinted text/icon (Groups with other items).
  tinted,

  /// A plain, unstyled system button.
  plain,
}

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

  /// The shared background preference.
  final bool sharesBackground;

  /// The SF Symbol name to use (preferred over IconData for iOS).
  final String? sfSymbolName;

  /// The button color (for "Glass" or "Filled" style buttons).
  ///
  /// If provided, the button will use a filled/tinted style with this color.
  final Color? color;

  /// Whether this action triggers the native search mode.
  ///
  /// If true, this button will act as the search toggle.
  final bool isSearchAction;

  /// The style of the button (Filled, Tinted, etc.).
  final AdaptiveActionButtonStyle style;

  /// Whether this is a flexible spacer instead of a button.
  final bool isSpacer;

  const AdaptiveCupertinoAction({
    this.icon,
    this.label,
    this.onPressed,
    this.isDestructive = false,
    this.sfSymbolName,
    this.sharesBackground = true,
    this.color,
    this.isSearchAction = false,
    this.isSpacer = false,
    this.style = AdaptiveActionButtonStyle.automatic,
  });

  /// Convert to map for platform channel.
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {};

    // Pass style
    data['style'] = style.name;

    // Auto-resolve SF Symbol from Icon if manual override is missing
    // Utilizes global mapping from WidgetSerializer
    final effectiveSfSymbol =
        sfSymbolName ?? WidgetSerializer.getSfSymbolName(icon);

    if (isSpacer) {
      data['type'] = 'spacer';
    } else if (isSearchAction) {
      data['type'] = 'search';
      // Allow custom icon/label for search button
      if (effectiveSfSymbol != null) {
        data['iconName'] = effectiveSfSymbol;
      } else if (icon != null) {
        data['iconCode'] = icon!.codePoint;
        data['iconFamily'] = icon!.fontFamily;
        data['iconPackage'] = icon!.fontPackage;
      } else if (label != null) {
        data['label'] = label; // Text based search button
      }
    } else if (effectiveSfSymbol != null) {
      data['type'] = 'icon';
      data['iconName'] = effectiveSfSymbol;
    } else if (icon != null) {
      data['type'] = 'icon';
      data['iconCode'] = icon!.codePoint;
      data['iconFamily'] = icon!.fontFamily;
      data['iconPackage'] = icon!.fontPackage;
    } else if (label != null) {
      data['type'] = 'text';
      data['label'] = label;
    }

    if (isDestructive) {
      data['isDestructive'] = true;
    }

    if (color != null) {
      data['color'] = color!.value;
    }

    // Pass sharing preference (native uses inverse 'hidesSharedBackground', but we pass positive logic here)
    // The native factory maps this: sharesBackground -> !hidesSharedBackground
    data['sharesBackground'] = sharesBackground;

    return data;
  }
}
