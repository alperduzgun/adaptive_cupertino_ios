part of '../radio.dart';

class _CupertinoRadioWidget<T> extends StatefulWidget {
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final Color? activeColor;
  final Color? borderColor;

  const _CupertinoRadioWidget({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.activeColor,
    this.borderColor,
  });

  @override
  State<_CupertinoRadioWidget<T>> createState() =>
      _CupertinoRadioWidgetState<T>();
}

class _CupertinoRadioWidgetState<T> extends State<_CupertinoRadioWidget<T>> {
  MethodChannel? _channel;

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('adaptive_cupertino_ios/toggle_$id');
    _channel?.setMethodCallHandler((call) async {
      if (call.method == 'onChanged') {
        final isChecked = call.arguments['value'] as bool;
        if (isChecked) {
          widget.onChanged?.call(widget.value);
        }
      }
    });
  }

  @override
  void didUpdateWidget(_CupertinoRadioWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupValue != widget.groupValue) {
      _channel?.invokeMethod(
          'setValue', {'value': widget.value == widget.groupValue});
    }
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform != TargetPlatform.iOS) {
      return _buildFlutterCupertinoRadio(context);
    }

    return SizedBox(
      width: 24,
      height: 24,
      child: UiKitView(
        viewType: 'adaptive_cupertino_ios/toggle',
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: {
          'value': widget.value == widget.groupValue,
          'isRadio': true,
          'useGlass': true, // Native iOS 26 glass toggle
        },
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }

  Widget _buildFlutterCupertinoRadio(BuildContext context) {
    return CupertinoRadio<T>(
      value: widget.value,
      groupValue: widget.groupValue,
      onChanged: widget.onChanged,
      activeColor: widget.activeColor,
    );
  }
}

class _MaterialRadioWidget<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final Color? activeColor;

  const _MaterialRadioWidget({
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Radio<T>(
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: activeColor,
    );
  }
}
