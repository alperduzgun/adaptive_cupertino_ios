import 'package:flutter/widgets.dart';

/// Notification bubbling up from AdaptiveCupertinoAppBar or Toolbar
/// to inform the AdaptiveScaffold about real-time obstruction heights.
class AdaptiveLayoutNotification extends Notification {
  /// The height of the obstruction (AppBar or Toolbar).
  ///
  /// This value should include safe area if the native view includes it.
  final double height;

  /// Whether this obstruction is at the top (AppBar) or bottom (Toolbar).
  final bool isTop;

  /// The safe area inset consumed by this view (e.g., status bar height).
  final double safeArea;

  const AdaptiveLayoutNotification({
    required this.height,
    required this.isTop,
    this.safeArea = 0.0,
  });
}
