import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  if (platform == TargetPlatform.iOS) {
    // Phase 5: Native Dialog Implementation
    // Use MethodChannel to show actual UIAlertController
    try {
      final List<Map<String, dynamic>> serializedActions = [];

      // We need to inspect the actions to serialize them.
      // This is tricky because actions are generic Widgets in the builder.
      // HOWEVER, showAdaptiveAlertDialog uses AdaptiveDialogAction explicitly.
      // We'll enforce a check here or fallback to Flutter implementation if widgets aren't AdaptiveDialogAction.

      // Since showAdaptiveDialog takes a generic builder, we can't easily extract actions
      // WITHOUT executing the builder.
      // So, let's create a specialized path for `showAdaptiveAlertDialog` which PASSES the actions list.
      // BUT, to keep API compatible, we will stick to Flutter implementation for complex builders,
      // and ONLY use native for showAdaptiveAlertDialog calls where we control the data.
      return showCupertinoDialog<T>(
        context: context,
        builder: builder,
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel,
      );
    } catch (_) {
      // Fallback
    }
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
}) async {
  final platform = Theme.of(context).platform;

  if (platform == TargetPlatform.iOS) {
    // Phase 5: Native Alert Controller (iOS)
    // We wrap the native call in a transparent PageRoute so that 'Navigator.pop'
    // in the action callbacks works correctly (popping this invisible route
    // instead of the screen behind it).

    // Check if we can serialize content
    String? titleText;
    if (title is Text) titleText = title.data;
    String? contentText;
    if (content is Text) contentText = content.data;

    bool canSerialize = true;
    final List<Map<String, dynamic>> serializedActions = [];

    for (final action in actions) {
      if (action.child is! Text) {
        canSerialize = false;
        break;
      }
      final text = (action.child as Text).data ?? 'Button';
      serializedActions.add({
        'label': text,
        'isDestructive': action.isDestructive,
        'isDefault': action.isDefaultAction,
      });
    }

    if (canSerialize && (titleText != null || contentText != null)) {
      return Navigator.of(context)
          .push<_NativeDialogRouteResult<T>>(
        _NativeDialogRoute<T>(
          title: titleText,
          content: contentText,
          actions: serializedActions,
          originalActions: actions,
          barrierDismissible: barrierDismissible,
        ),
      )
          .then((result) {
        // The route returns the result passed to pop, or null.
        // If action relied on side-effects, it might have called pop(result).
        return result?.result;
      });
    }
  }

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

class _NativeDialogRouteResult<T> {
  final T? result;
  _NativeDialogRouteResult(this.result);
}

class _NativeDialogRoute<T> extends PageRoute<_NativeDialogRouteResult<T>> {
  final String? title;
  final String? content;
  final List<Map<String, dynamic>> actions;
  final List<AdaptiveDialogAction> originalActions;
  final bool barrierDismissible;

  _NativeDialogRoute({
    this.title,
    this.content,
    required this.actions,
    required this.originalActions,
    this.barrierDismissible = true,
  });

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    // We show nothing in Flutter, just trigger the native dialog
    return const SizedBox.shrink();
  }

  @override
  TickerFuture didPush() {
    super.didPush();
    _showNativeDialog();
    return TickerFuture.complete();
  }

  Future<void> _showNativeDialog() async {
    try {
      const channel = MethodChannel('adaptive_cupertino_ios');
      final int? index = await channel.invokeMethod<int>('showDialog', {
        'title': title,
        'content': content,
        'actions': actions,
      });

      if (index != null && index >= 0 && index < originalActions.length) {
        // Run the callback. The user is expected to call Navigator.pop(context, value).
        // Since we are the top route, pop() will close this route and pass the value to the awaiter.
        final action = originalActions[index];
        if (action.onPressed != null) {
          action.onPressed!();
        } else {
          // Default behavior if no callback: just pop null
          navigator?.pop(null);
        }
      } else {
        // Dismissed without action
        navigator?.pop(null);
      }
    } catch (e) {
      debugPrint('Native dialog error: $e');
      navigator?.pop(null);
    }
  }
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
}) async {
  final platform = Theme.of(context).platform;

  if (platform == TargetPlatform.iOS) {
    // Phase 5: Native Implementation for Confirm Dialog
    // We can safely bypass Navigator here because we define the logic.
    String? titleText;
    if (title is Text) titleText = title.data;
    String? contentText;
    if (content is Text) contentText = content.data;

    try {
      const channel = MethodChannel('adaptive_cupertino_ios');
      final int? index = await channel.invokeMethod<int>('showDialog', {
        'title': titleText,
        'content': contentText,
        'actions': [
          {'label': cancelText, 'isDestructive': false, 'isDefault': false},
          {'label': okText, 'isDestructive': isDestructive, 'isDefault': true},
        ],
      });

      if (index == 0) return false; // Cancel
      if (index == 1) return true; // OK
      return null; // Dismissed
    } catch (e) {
      debugPrint('Native dialog failed: $e');
      // Fallback to standard
    }
  }

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
