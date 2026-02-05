part of '../floating_action_button.dart';

class _CupertinoFABWidget extends StatefulWidget {
  final Widget icon;
  final VoidCallback onPressed;
  final Widget? label;
  final bool useGlass;

  const _CupertinoFABWidget({
    required this.icon,
    required this.onPressed,
    this.label,
    this.useGlass = true,
  });

  @override
  State<_CupertinoFABWidget> createState() => _CupertinoFABWidgetState();
}

class _CupertinoFABWidgetState extends State<_CupertinoFABWidget> {
  MethodChannel? _channel;

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('adaptive_cupertino_ios/fab_$id');
    _channel?.setMethodCallHandler((call) async {
      if (call.method == 'onPressed') {
        widget.onPressed();
      }
    });
  }

  String? _getIconName(Widget icon) {
    // CHAOS SAFETY: Only use native FAB if icon is a simple Icon with a valid name
    // In a real app, we'd have a mapping. For now, we fallback if not an Icon.
    if (icon is Icon && icon.icon != null) {
      // Dummy mapping for demo purposes
      return 'plus';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final iconName = _getIconName(widget.icon);
    final isNativeEligible = Theme.of(context).platform == TargetPlatform.iOS &&
        iconName != null &&
        widget.label == null;

    if (!isNativeEligible) {
      return _buildFlutterFAB();
    }

    return SizedBox(
      width: 56,
      height: 56,
      child: UiKitView(
        viewType: 'adaptive_cupertino_ios/fab',
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: {
          'icon': iconName,
          'useGlass': widget.useGlass,
        },
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }

  Widget _buildFlutterFAB() {
    if (widget.useGlass) {
      if (widget.label != null) {
        return AdaptiveButton.glass(
          onPressed: widget.onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.icon,
              const SizedBox(width: 8),
              widget.label!,
            ],
          ),
        );
      }
      return AdaptiveButton.glass(
        onPressed: widget.onPressed,
        padding: EdgeInsets.zero,
        child: widget.icon,
      );
    }

    return CupertinoButton(
      onPressed: widget.onPressed,
      child: widget.label != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [widget.icon, const SizedBox(width: 8), widget.label!],
            )
          : widget.icon,
    );
  }
}

class _MaterialFABWidget extends StatelessWidget {
  final Widget icon;
  final VoidCallback onPressed;
  final Widget? label;
  final String? tooltip;

  const _MaterialFABWidget({
    required this.icon,
    required this.onPressed,
    this.label,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    if (label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: icon,
        label: label!,
        tooltip: tooltip,
      );
    }
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      child: icon,
    );
  }
}
