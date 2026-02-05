part of '../menu.dart';

class _CupertinoContextMenuWidget extends StatefulWidget {
  final Widget child;
  final List<AdaptiveContextMenuItem> actions;

  const _CupertinoContextMenuWidget({
    required this.child,
    required this.actions,
  });

  @override
  State<_CupertinoContextMenuWidget> createState() =>
      _CupertinoContextMenuWidgetState();
}

class _CupertinoContextMenuWidgetState
    extends State<_CupertinoContextMenuWidget> {
  MethodChannel? _channel;

  void _onPlatformViewCreated(int id) {
    _channel = MethodChannel('adaptive_cupertino_ios/menu_$id');
    _channel?.setMethodCallHandler((call) async {
      if (call.method == 'onAction') {
        final index = call.arguments['index'] as int;
        if (index >= 0 && index < widget.actions.length) {
          widget.actions[index].onPressed();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform != TargetPlatform.iOS) {
      return widget.child; // Fallback handled by parent if necessary
    }

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: UiKitView(
            viewType: 'adaptive_cupertino_ios/menu',
            onPlatformViewCreated: _onPlatformViewCreated,
            creationParams: {
              'actions': widget.actions
                  .map((item) => {
                        'title': _extractText(item.child),
                        'icon': item.icon,
                        'isDestructive': item.isDestructive,
                      })
                  .toList(),
            },
            creationParamsCodec: const StandardMessageCodec(),
          ),
        ),
      ],
    );
  }

  String _extractText(Widget widget) {
    if (widget is Text) return widget.data ?? '';
    return 'Action';
  }
}

class _MaterialContextMenuWidget extends StatefulWidget {
  final Widget child;
  final List<AdaptiveContextMenuItem> actions;

  const _MaterialContextMenuWidget({
    required this.child,
    required this.actions,
  });

  @override
  State<_MaterialContextMenuWidget> createState() =>
      _MaterialContextMenuWidgetState();
}

class _MaterialContextMenuWidgetState
    extends State<_MaterialContextMenuWidget> {
  final ContextMenuController _contextMenuController = ContextMenuController();

  void _showContextMenu(BuildContext context, Offset offset) {
    _contextMenuController.show(
      context: context,
      contextMenuBuilder: (context) {
        return AdaptiveMaterialMenu(
          offset: offset,
          actions: widget.actions,
          onDismiss: () => _contextMenuController.remove(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (details) =>
          _showContextMenu(context, details.globalPosition),
      child: widget.child,
    );
  }
}

class AdaptiveMaterialMenu extends StatelessWidget {
  final Offset offset;
  final List<AdaptiveContextMenuItem> actions;
  final VoidCallback onDismiss;

  const AdaptiveMaterialMenu({
    super.key,
    required this.offset,
    required this.actions,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: actions.map((item) {
              return ListTile(
                title: item.child,
                onTap: () {
                  onDismiss();
                  item.onPressed();
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
