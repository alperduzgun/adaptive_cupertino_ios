import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

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

  /// Serializes a widget (like an Icon or Button) into a map for native code.
  static Map<String, dynamic>? serialize(Widget? widget) {
    if (widget == null) return null;

    if (kDebugMode) {
      debugPrint('🔍 [Serializer] Processing widget: ${widget.runtimeType}');
    }

    // Handle Icon
    if (widget is Icon) {
      final data = {
        'type': 'icon',
        'iconCode': widget.icon?.codePoint,
        'iconFamily': widget.icon?.fontFamily,
      };
      if (kDebugMode) {
        debugPrint('   ✅ Icon found: codePoint=${widget.icon?.codePoint}');
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
