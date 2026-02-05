part of '../tooltip.dart';

class _CupertinoTooltipWidget extends StatelessWidget {
  final String message;
  final Widget child;
  final bool useGlass;

  const _CupertinoTooltipWidget({
    required this.message,
    required this.child,
    this.useGlass = false,
  });

  @override
  Widget build(BuildContext context) {
    if (useGlass && Theme.of(context).platform == TargetPlatform.iOS) {
      return Tooltip(
        // message: message, // CHAOS FIX: Cannot provide both message and richMessage
        richMessage: WidgetSpan(
          child: SizedBox(
            width: 120,
            height: 40,
            child: UiKitView(
              viewType: 'adaptive_cupertino_ios/tooltip',
              creationParams: {
                'message': message,
                'useGlass': true,
              },
              creationParamsCodec: const StandardMessageCodec(),
            ),
          ),
        ),
        decoration: const BoxDecoration(
          color: Colors.transparent, // Native view provides background
        ),
        child: child,
      );
    }

    return Tooltip(
      message: message,
      child: child,
    );
  }
}

class _MaterialTooltipWidget extends StatelessWidget {
  final String message;
  final Widget child;

  const _MaterialTooltipWidget({
    required this.message,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      child: child,
    );
  }
}
