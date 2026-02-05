import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

part 'widgets/menu_parts.dart';

/// An adaptive context menu that provides platform-appropriate interactions.
///
/// Uses [CupertinoContextMenu] on iOS and standard context menu logic on Android.
class AdaptiveContextMenu extends StatelessWidget
    with AdaptiveContextMenuMixin {
  /// The widget that the context menu is attached to.
  final Widget child;

  /// The list of actions to display in the menu.
  final List<AdaptiveContextMenuItem> actions;

  const AdaptiveContextMenu({
    super.key,
    required this.child,
    required this.actions,
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

mixin AdaptiveContextMenuMixin {
  Widget buildCupertino(BuildContext context) {
    final menu = this as AdaptiveContextMenu;
    return _CupertinoContextMenuWidget(
      actions: menu.actions,
      child: menu.child,
    );
  }

  Widget buildMaterial(BuildContext context) {
    final menu = this as AdaptiveContextMenu;
    return _MaterialContextMenuWidget(
      actions: menu.actions,
      child: menu.child,
    );
  }
}

/// Represents an item in an [AdaptiveContextMenu].
class AdaptiveContextMenuItem {
  final Widget child;
  final VoidCallback onPressed;

  /// Optional SF Symbol name for the icon (iOS only).
  final String? icon;

  /// Whether this action is destructive (iOS only).
  final bool isDestructive;

  const AdaptiveContextMenuItem({
    required this.child,
    required this.onPressed,
    this.icon,
    this.isDestructive = false,
  });
}
