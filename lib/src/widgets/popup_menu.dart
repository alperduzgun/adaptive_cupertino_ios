import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// An adaptive popup menu that provides platform-appropriate interactions.
///
/// On iOS, shows a [CupertinoActionSheet] via a modal popup.
/// On Android, uses [PopupMenuButton].
class AdaptivePopupMenuButton<T> extends StatelessWidget {
  /// The list of items to display in the menu.
  final List<AdaptivePopupMenuItem<T>> items;

  /// Callback when an item is selected.
  final ValueChanged<T>? onSelected;

  /// The child widget that triggers the menu.
  ///
  /// If null, defaults to a "More" icon (ellipsis).
  final Widget? child;

  /// Optional icon to use instead of the default "More" icon.
  ///
  /// Ignored if [child] is provided.
  final Widget? icon;

  /// Tooltip text (Android only).
  final String? tooltip;

  const AdaptivePopupMenuButton({
    super.key,
    required this.items,
    this.onSelected,
    this.child,
    this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS) {
      return _buildIOS(context);
    }

    return _buildAndroid(context);
  }

  Widget _buildIOS(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        showCupertinoModalPopup(
          context: context,
          builder: (context) => CupertinoActionSheet(
            actions: items.map((item) {
              return CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  onSelected?.call(item.value);
                },
                isDestructiveAction: item.isDestructive,
                child: item.child,
              );
            }).toList(),
            cancelButton: CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context),
              isDefaultAction: true,
              child: const Text('Cancel'),
            ),
          ),
        );
      },
      child: child ?? icon ?? const Icon(CupertinoIcons.ellipsis_circle),
    );
  }

  Widget _buildAndroid(BuildContext context) {
    return PopupMenuButton<T>(
      onSelected: onSelected,
      tooltip: tooltip,
      icon: icon,
      child: child,
      itemBuilder: (context) => items
          .map(
            (item) => PopupMenuItem<T>(
              value: item.value,
              child: item.child,
            ),
          )
          .toList(),
    );
  }
}

/// Represents an item in an [AdaptivePopupMenuButton].
class AdaptivePopupMenuItem<T> {
  /// The value to return when selected.
  final T value;

  /// The widget content of the item.
  final Widget child;

  /// Whether this action is destructive (iOS only).
  final bool isDestructive;

  const AdaptivePopupMenuItem({
    required this.value,
    required this.child,
    this.isDestructive = false,
  });
}
