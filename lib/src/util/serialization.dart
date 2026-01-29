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

  /// Returns the SF Symbol name for a given IconData, if mapped.
  ///
  /// This serves as the consistent global mapping source.
  static String? getSfSymbolName(IconData? icon) {
    if (icon == null) return null;

    // Automatic SF Symbol Mapping (Common CupertinoIcons)
    if (icon == CupertinoIcons.search || icon == Icons.search) {
      return 'magnifyingglass';
    } else if (icon == CupertinoIcons.add || icon == Icons.add) {
      return 'plus';
    } else if (icon == CupertinoIcons.share || icon == Icons.share) {
      return 'square.and.arrow.up';
    } else if (icon == CupertinoIcons.info_circle || icon == Icons.info) {
      return 'info.circle';
    } else if (icon == CupertinoIcons.gear ||
        icon == CupertinoIcons.settings ||
        icon == Icons.settings) {
      return 'gear';
    } else if (icon == CupertinoIcons.gear_solid) {
      return 'gear.fill';
    } else if (icon == CupertinoIcons.layers) {
      return 'layers';
    } else if (icon == CupertinoIcons.layers_fill) {
      return 'layers.fill';
    } else if (icon == CupertinoIcons.circle) {
      return 'circle';
    } else if (icon == CupertinoIcons.circle_fill) {
      return 'circle.fill';
    } else if (icon == CupertinoIcons.heart) {
      return 'heart';
    } else if (icon == CupertinoIcons.heart_fill) {
      return 'heart.fill';
    } else if (icon == CupertinoIcons.star) {
      return 'star';
    } else if (icon == CupertinoIcons.star_fill) {
      return 'star.fill';
    } else if (icon == CupertinoIcons.house) {
      return 'house';
    } else if (icon == CupertinoIcons.house_fill) {
      return 'house.fill';
    } else if (icon == CupertinoIcons.square_grid_2x2) {
      return 'square.grid.2x2';
    } else if (icon == CupertinoIcons.square_grid_2x2_fill) {
      return 'square.grid.2x2.fill';
    } else if (icon == CupertinoIcons.rectangle_stack) {
      return 'rectangle.stack';
    } else if (icon == CupertinoIcons.rectangle_stack_fill) {
      return 'rectangle.stack.fill';
    } else if (icon == CupertinoIcons.bolt_fill) {
      return 'bolt.fill';
    } else if (icon == CupertinoIcons.flame_fill) {
      return 'flame.fill';
    } else if (icon == CupertinoIcons.doc_text) {
      return 'doc.text';
    } else if (icon == CupertinoIcons.doc_text_fill) {
      return 'doc.text.fill';
    } else if (icon == CupertinoIcons.person_2) {
      return 'person.2';
    } else if (icon == CupertinoIcons.person_2_fill) {
      return 'person.2.fill';
    } else if (icon == CupertinoIcons.sparkles) {
      return 'sparkles';
    } else if (icon == CupertinoIcons.person_circle) {
      return 'person.circle';
    } else if (icon == CupertinoIcons.person_circle_fill) {
      return 'person.circle.fill';
    } else if (icon == CupertinoIcons.bell) {
      return 'bell';
    } else if (icon == CupertinoIcons.bell_fill) {
      return 'bell.fill';
    }

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
