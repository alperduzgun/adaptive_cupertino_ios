import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Adaptive alert dialog that provides platform-appropriate styling.
///
/// Uses CupertinoAlertDialog on iOS and Material AlertDialog on Android.
class AdaptiveAlertDialog extends StatelessWidget {
  /// Dialog title.
  final Widget? title;

  /// Dialog content/message.
  final Widget? content;

  /// Dialog actions (buttons).
  final List<Widget> actions;

  /// Whether the dialog is scrollable.
  ///
  /// Defaults to false.
  final bool scrollable;

  const AdaptiveAlertDialog({
    Key? key,
    this.title,
    this.content,
    this.actions = const [],
    this.scrollable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS) {
      return CupertinoAlertDialog(
        title: title,
        content: content,
        actions: actions,
        scrollController: scrollable ? ScrollController() : null,
      );
    }

    return AlertDialog(
      title: title,
      content: content,
      actions: actions,
      scrollable: scrollable,
    );
  }
}

/// Adaptive dialog action button.
///
/// Uses CupertinoDialogAction on iOS and TextButton on Android.
class AdaptiveDialogAction extends StatelessWidget {
  /// Action label.
  final Widget child;

  /// Callback when action is pressed.
  final VoidCallback? onPressed;

  /// Whether this is a destructive action (e.g., Delete).
  ///
  /// On iOS, displays in red.
  final bool isDestructive;

  /// Whether this is the default/primary action.
  ///
  /// On iOS, displays in bold.
  final bool isDefaultAction;

  const AdaptiveDialogAction({
    Key? key,
    required this.child,
    required this.onPressed,
    this.isDestructive = false,
    this.isDefaultAction = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS) {
      return CupertinoDialogAction(
        onPressed: onPressed,
        isDestructiveAction: isDestructive,
        isDefaultAction: isDefaultAction,
        child: child,
      );
    }

    return TextButton(
      onPressed: onPressed,
      style: isDestructive
          ? TextButton.styleFrom(
              foregroundColor: Colors.red,
            )
          : null,
      child: child,
    );
  }
}

/// Shows an adaptive alert dialog.
///
/// Returns the result of the dialog (typically the action that was pressed).
Future<T?> showAdaptiveDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? barrierLabel,
}) {
  final platform = Theme.of(context).platform;

  if (platform == TargetPlatform.iOS) {
    return showCupertinoDialog<T>(
      context: context,
      builder: builder,
      barrierDismissible: barrierDismissible,
      barrierLabel: barrierLabel,
    );
  }

  return showDialog<T>(
    context: context,
    builder: builder,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
  );
}

/// Shows a simple adaptive alert dialog with title, message, and actions.
///
/// Convenience method for common use cases.
Future<T?> showAdaptiveAlertDialog<T>({
  required BuildContext context,
  Widget? title,
  Widget? content,
  required List<AdaptiveDialogAction> actions,
  bool barrierDismissible = true,
}) {
  return showAdaptiveDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AdaptiveAlertDialog(
      title: title,
      content: content,
      actions: actions,
    ),
  );
}

/// Shows an adaptive confirmation dialog with OK and Cancel buttons.
///
/// Returns true if OK was pressed, false if Cancel was pressed, null if dismissed.
Future<bool?> showAdaptiveConfirmDialog({
  required BuildContext context,
  Widget? title,
  Widget? content,
  String okText = 'OK',
  String cancelText = 'Cancel',
  bool isDestructive = false,
}) {
  return showAdaptiveAlertDialog<bool>(
    context: context,
    title: title,
    content: content,
    actions: [
      AdaptiveDialogAction(
        onPressed: () => Navigator.of(context).pop(false),
        child: Text(cancelText),
      ),
      AdaptiveDialogAction(
        onPressed: () => Navigator.of(context).pop(true),
        isDefaultAction: true,
        isDestructive: isDestructive,
        child: Text(okText),
      ),
    ],
  );
}
