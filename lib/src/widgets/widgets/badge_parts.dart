part of '../badge.dart';

class _CupertinoBadgeWidget extends StatelessWidget {
  final Widget child;
  final Widget? label;
  final String? sfSymbol;
  final String? effect;
  final Color? backgroundColor;
  final Color? labelColor;
  final bool useGlass;
  final bool isRepeating;

  const _CupertinoBadgeWidget({
    required this.child,
    this.label,
    this.sfSymbol,
    this.effect,
    this.isRepeating = true,
    this.backgroundColor,
    this.labelColor,
    this.useGlass = false,
  });

  String? _getTextFromLabel() {
    if (label is Text) {
      return (label as Text).data;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform != TargetPlatform.iOS) {
      return _buildFlutterCupertinoBadge(context);
    }

    final String? labelText = _getTextFromLabel();
    final bool hasNativeContent = labelText != null || sfSymbol != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (label != null || sfSymbol != null)
          Positioned(
            top: -4,
            right: -4,
            child: SizedBox(
              width: 20,
              height: 20,
              child: hasNativeContent
                  ? UiKitView(
                      viewType: 'adaptive_cupertino_ios/badge',
                      creationParams: {
                        if (labelText != null) 'label': labelText,
                        if (sfSymbol != null) 'sfSymbol': sfSymbol,
                        if (effect != null) 'effect': effect,
                        if (backgroundColor != null)
                          'backgroundColor': backgroundColor!.value,
                        if (labelColor != null) 'labelColor': labelColor!.value,
                        'useGlass': useGlass,
                        'isRepeating': isRepeating,
                      },
                      creationParamsCodec: const StandardMessageCodec(),
                    )
                  : _buildFlutterCupertinoBadgeContent(context),
            ),
          ),
      ],
    );
  }

  Widget _buildFlutterCupertinoBadge(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (label != null)
          Positioned(
            top: -4,
            right: -4,
            child: _buildFlutterCupertinoBadgeContent(context),
          ),
      ],
    );
  }

  Widget _buildFlutterCupertinoBadgeContent(BuildContext context) {
    return useGlass
        ? AdaptiveGlassBox(
            borderRadius: 10,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: labelColor ?? CupertinoColors.white,
                ),
                child: label!,
              ),
            ),
          )
        : Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: backgroundColor ?? CupertinoColors.systemRed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DefaultTextStyle(
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: labelColor ?? CupertinoColors.white,
              ),
              child: label!,
            ),
          );
  }
}

class _MaterialBadgeWidget extends StatelessWidget {
  final Widget child;
  final Widget? label;
  final Color? backgroundColor;
  final Color? labelColor;

  const _MaterialBadgeWidget({
    required this.child,
    this.label,
    this.backgroundColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    return Badge(
      label: label,
      backgroundColor: backgroundColor,
      textColor: labelColor,
      child: child,
    );
  }
}
