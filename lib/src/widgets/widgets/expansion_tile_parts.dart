part of '../expansion_tile.dart';

class _CupertinoExpansionTileWidget extends StatefulWidget {
  final Widget title;
  final Widget? leading;
  final List<Widget> children;
  final ValueChanged<bool>? onExpansionChanged;

  const _CupertinoExpansionTileWidget({
    required this.title,
    this.leading,
    required this.children,
    this.onExpansionChanged,
  });

  @override
  State<_CupertinoExpansionTileWidget> createState() =>
      _CupertinoExpansionTileWidgetState();
}

class _CupertinoExpansionTileWidgetState
    extends State<_CupertinoExpansionTileWidget> {
  bool _isExpanded = false;
  MethodChannel? _channel;

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('adaptive_cupertino_ios/expansion_tile_$id');
    _channel?.setMethodCallHandler((call) async {
      if (call.method == 'onChanged') {
        final expanded = call.arguments['isExpanded'] as bool;
        setState(() => _isExpanded = expanded);
        widget.onExpansionChanged?.call(expanded);
      }
    });
  }

  String? _getText(Widget widget) {
    if (widget is Text) return widget.data;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final titleText = _getText(widget.title);
    final isNativeEligible = Theme.of(context).platform == TargetPlatform.iOS &&
        titleText != null &&
        widget.leading == null;

    if (!isNativeEligible) {
      return _buildFlutterExpansionTile();
    }

    return Column(
      children: [
        SizedBox(
          height: 56,
          child: UiKitView(
            viewType: 'adaptive_cupertino_ios/expansion_tile',
            onPlatformViewCreated: _onPlatformViewCreated,
            creationParams: {
              'title': titleText,
              'useGlass': true,
              'isExpanded': _isExpanded,
            },
            creationParamsCodec: const StandardMessageCodec(),
          ),
        ),
        if (_isExpanded) ...widget.children,
      ],
    );
  }

  Widget _buildFlutterExpansionTile() {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: widget.leading,
        title: widget.title,
        onExpansionChanged: widget.onExpansionChanged,
        trailing: const Icon(CupertinoIcons.chevron_down, size: 16),
        children: widget.children,
      ),
    );
  }
}

class _MaterialExpansionTileWidget extends StatelessWidget {
  final Widget title;
  final Widget? leading;
  final List<Widget> children;
  final ValueChanged<bool>? onExpansionChanged;

  const _MaterialExpansionTileWidget({
    required this.title,
    this.leading,
    required this.children,
    this.onExpansionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: leading,
      title: title,
      onExpansionChanged: onExpansionChanged,
      children: children,
    );
  }
}
