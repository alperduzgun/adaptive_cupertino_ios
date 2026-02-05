part of '../text_field.dart';

class _CupertinoTextFieldWidget extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? placeholder;
  final bool obscureText;
  final TextInputType? keyboardType;
  final bool useGlass;

  const _CupertinoTextFieldWidget({
    this.controller,
    this.onChanged,
    this.placeholder,
    this.obscureText = false,
    this.keyboardType,
    this.useGlass = false,
  });

  @override
  State<_CupertinoTextFieldWidget> createState() =>
      _CupertinoTextFieldWidgetState();
}

class _CupertinoTextFieldWidgetState extends State<_CupertinoTextFieldWidget> {
  MethodChannel? _channel;
  late final TextEditingController _effectiveController;

  @override
  void initState() {
    super.initState();
    _effectiveController = widget.controller ?? TextEditingController();
    _effectiveController.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    _effectiveController.removeListener(_handleControllerChanged);
    if (widget.controller == null) {
      _effectiveController.dispose();
    }
    super.dispose();
  }

  void _handleControllerChanged() {
    _channel?.invokeMethod('setText', {'text': _effectiveController.text});
  }

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('adaptive_cupertino_ios/text_field_$id');
    _channel?.setMethodCallHandler((call) async {
      if (call.method == 'onChanged') {
        final text = call.arguments['text'] as String;
        if (_effectiveController.text != text) {
          _effectiveController.text = text;
          widget.onChanged?.call(text);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // CHAOS SAFETY: Fallback to Flutter widget if not on iOS or if native creation fails
    if (Theme.of(context).platform != TargetPlatform.iOS) {
      return _buildFlutterCupertinoTextField(context);
    }

    return SizedBox(
      height: 50, // Standard height for native text field
      child: UiKitView(
        viewType: 'adaptive_cupertino_ios/text_field',
        onPlatformViewCreated: _onPlatformViewCreated,
        creationParams: {
          'placeholder': widget.placeholder,
          'text': _effectiveController.text,
          'useGlass': widget.useGlass,
          'obscureText': widget.obscureText,
          'keyboardType':
              widget.keyboardType?.toString().split('.').last ?? 'text',
        },
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }

  Widget _buildFlutterCupertinoTextField(BuildContext context) {
    return CupertinoTextField(
      controller: _effectiveController,
      onChanged: widget.onChanged,
      placeholder: widget.placeholder,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      padding: const EdgeInsets.all(12),
      decoration: widget.useGlass
          ? null
          : BoxDecoration(
              color: CupertinoColors.systemBackground.resolveFrom(context),
              border: Border.all(
                color: CupertinoColors.separator.resolveFrom(context),
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
    );
  }
}

class _MaterialTextFieldWidget extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? labelText;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _MaterialTextFieldWidget({
    this.controller,
    this.onChanged,
    this.labelText,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
