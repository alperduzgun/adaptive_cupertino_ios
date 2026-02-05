import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Utility class for serializing Flutter widgets for native platform views.
class WidgetSerializer {
  /// Extracts text from a widget, searching recursively through wrappers.
  static String? extractText(Widget? widget) {
    if (widget == null) return null;

    if (widget is Text) {
      return widget.data;
    }

    // Try to access child property via dynamic access
    try {
      final dynamic dynamicWidget = widget;
      try {
        final dynamic child = dynamicWidget.child;
        if (child != null && child is Widget) {
          return extractText(child);
        }
      } catch (_) {}

      try {
        final dynamic children = dynamicWidget.children;
        if (children != null && children is List) {
          for (final child in children) {
            if (child is Widget) {
              final text = extractText(child);
              if (text != null) return text;
            }
          }
        }
      } catch (_) {}
    } catch (_) {}

    return null;
  }

  /// The internal mapping of CupertinoIcons code points to SF Symbol names.
  ///
  /// This mapping ensures automatic resolution of standard Flutter CupertinoIcons
  /// to their corresponding native SF Symbols, enabling native animations and rendering.
  static const Map<int, String> _cupertinoToSf = {
    // Common Icons
    0xf44c: 'magnifyingglass', // search (62540)
    0xf2c7: 'magnifyingglass', // search (legacy)
    0xf274: 'plus', // add
    0xf4ca: 'square.and.arrow.up', // share
    0xf44e: 'info.circle', // info
    0xf43c: 'gear', // settings
    0xf43d: 'gear.fill', // settings_solid
    0xf44f: 'info.circle', // info_circle
    0xf450: 'info.circle.fill', // info_circle_fill

    // Shapes
    0xf2aa: 'circle',
    0xf2ab: 'circle.fill',
    0xf442: 'heart',
    0xf443: 'heart.fill',

    0xf41c: 'person.crop.rectangle', // person_crop_rectangle
    0xf41d: 'person.crop.rectangle.fill', // person_crop_rectangle_fill

    // Tab Bar & Navigation
    63492: 'square.grid.2x2', // square_grid_2x2 (0xf804)
    63493: 'square.grid.2x2.fill', // square_grid_2x2_fill (0xf805)
    63623: 'rectangle.split.2x1', // uiwindow_split_2x1 (0xf887)
    63718: 'square.stack.3d.up', // layers_alt (0xf8e6)
    63719: 'square.stack.3d.up.fill', // layers_alt_fill (0xf8e7)
    62512: 'flask', // lab_flask (0xf430)
    62513: 'flask.fill', // lab_flask_solid (0xf431)

    // Navigation
    0xf2d6: 'chevron.right',
    0xf2d5: 'chevron.left',

    // Sparkles & Effects
    63464: 'sparkles', // sparkles (0xf7e8)

    // Notifications
    0xf3eb: 'bell',
    0xf3ec: 'bell.fill',
  };

  /// Returns the SF Symbol name for a given IconData, if mapped.
  ///
  /// This serves as the consistent global mapping source.
  static String? getSfSymbolName(IconData? icon) {
    if (icon == null) return null;

    // 1. Check Code Point Mapping (Fast & Robust)
    if (_cupertinoToSf.containsKey(icon.codePoint)) {
      return _cupertinoToSf[icon.codePoint];
    }

    // 2. Legacy/Fallback Checks (for icons from material or other families)
    if (icon.codePoint == Icons.search.codePoint) return 'magnifyingglass';
    if (icon.codePoint == Icons.add.codePoint) return 'plus';
    if (icon.codePoint == Icons.share.codePoint) return 'square.and.arrow.up';
    if (icon.codePoint == Icons.info.codePoint) return 'info.circle';
    if (icon.codePoint == Icons.settings.codePoint) return 'gear';

    return null;
  }

  /// Serializes a widget (like an Icon or Button) into a map for native code.
  static Map<String, dynamic>? serialize(Widget? widget) {
    if (widget == null) return null;

    if (kDebugMode) {
      debugPrint('🔍 [Serializer] Processing widget: ${widget.runtimeType}');
    }

    // Handle Icon
    if (widget is Icon) {
      final data = <String, dynamic>{
        'type': 'icon',
        'iconCode': widget.icon?.codePoint,
        'iconFamily': widget.icon?.fontFamily,
        'iconPackage': widget.icon?.fontPackage,
      };

      // Automatic SF Symbol Mapping
      final sfSymbol = getSfSymbolName(widget.icon);
      if (sfSymbol != null) {
        data['iconName'] = sfSymbol;
      }

      if (kDebugMode) {
        debugPrint(
            '   ✅ Icon found: codePoint=${widget.icon?.codePoint} symbol=${data['iconName']}');
      }
      return data;
    }

    // Handle CupertinoButton
    if (widget is CupertinoButton) {
      return serialize(widget.child);
    }

    // Handle Spacer
    if (widget is Spacer) {
      if (kDebugMode) {
        debugPrint('   ✅ Spacer found');
      }
      return {'type': 'spacer'};
    }

    // Handle single-child wrappers
    try {
      final dynamic dynamicWidget = widget;
      try {
        final dynamic child = dynamicWidget.child;
        if (child != null && child is Widget) {
          return serialize(child);
        }
      } catch (_) {}
    } catch (_) {}

    // Handle multi-child wrappers
    try {
      final dynamic dynamicWidget = widget;
      try {
        final dynamic children = dynamicWidget.children;
        if (children != null && children is List) {
          for (final child in children) {
            if (child is Widget) {
              final result = serialize(child);
              if (result != null) return result;
            }
          }
        }
      } catch (_) {}
    } catch (_) {}

    return null;
  }
}
