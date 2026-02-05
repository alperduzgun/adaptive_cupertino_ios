part of '../checkbox.dart';

class _CupertinoCheckboxWidget extends StatefulWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final Color? activeColor;
  final Color? checkColor;
  final Color? borderColor;

  const _CupertinoCheckboxWidget({
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.checkColor,
    this.borderColor,
  });

  @override
  State<_CupertinoCheckboxWidget> createState() =>
      _CupertinoCheckboxWidgetState();
}

class _CupertinoCheckboxWidgetState extends State<_CupertinoCheckboxWidget> {
  MethodChannel? _channel;

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('adaptive_cupertino_ios/toggle_$id');
    _channel?.setMethodCallHandler((call) async {
      if (call.method == 'onChanged') {
        final newValue = call.arguments['value'] as bool;
        widget.onChanged?.call(newValue);
      }
    });
  }

  @override
  void didUpdateWidget(_CupertinoCheckboxWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _channel?.invokeMethod('setValue', {'value': widget.value});
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
      return _buildFlutterCupertinoCheckbox(context);
    }

    return SizedBox(
      width: 24,
      height: 24,
      child: UiKitView(
        viewType: 'adaptive_cupertino_ios/toggle',
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: {
          'value': widget.value,
          'isRadio': false,
          'useGlass': true, // Native iOS 26 glass toggle
        },
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }

  Widget _buildFlutterCupertinoCheckbox(BuildContext context) {
    return CupertinoCheckbox(
      value: widget.value,
      onChanged: widget.onChanged,
      activeColor: widget.activeColor,
      checkColor: widget.checkColor,
      side: widget.borderColor != null
          ? BorderSide(color: widget.borderColor!)
          : null,
    );
  }
}

class _MaterialCheckboxWidget extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final Color? activeColor;
  final Color? checkColor;

  const _MaterialCheckboxWidget({
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.checkColor,
  });

  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: value,
      onChanged: onChanged,
      activeColor: activeColor,
      checkColor: checkColor,
    );
  }
}
