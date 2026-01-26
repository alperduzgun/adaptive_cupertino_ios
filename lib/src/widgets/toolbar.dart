import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../platform/ios_version.dart';
import 'action.dart';

/// Native iOS 26+ Toolbar with pill-shaped button grouping.
///
/// Features:
/// - Liquid Glass blur effects
/// - Automatic pill-shaped grouping of buttons (iOS 26+)
/// - Native gesture handling
/// - Graceful fallback to UINavigationBar (iOS 18-25) or CupertinoNavigationBar (iOS <18)
class AdaptiveCupertinoToolbar extends StatefulWidget
    implements PreferredSizeWidget {
  /// The title displayed in the toolbar (optional).
  final String? title;

  /// Leading widget (typically a single icon button).
  final Widget? leading;

  /// Reliable leading action (uses IconData).
  final AdaptiveCupertinoAction? leadingAction;

  /// Trailing widgets (typically multiple icon buttons).
  final List<Widget>? trailing;

  /// Reliable trailing actions (uses IconData).
  final List<AdaptiveCupertinoAction>? trailingActions;

  /// Height of the toolbar (standard is 44.0).
  final double height;

  /// Enable/disable the custom LiquidGlass background effect.
  /// When false, toolbar has no background (completely transparent).
  /// Default: true
  final bool enableLiquidGlass;

  /// Use plain text title (no pill/bubble background).
  /// When true: Title appears as plain text (recommended by Apple HIG)
  /// When false: Title appears in iOS 26 glass pill style
  /// Default: false
  final bool usePlainTitle;

  /// Custom color for the title text.
  /// When null: Uses system adaptive color (black in light mode, white in dark mode)
  /// Default: null (adaptive)
  final Color? titleColor;

  const AdaptiveCupertinoToolbar({
    Key? key,
    this.title,
    this.leading,
    this.leadingAction,
    this.trailing,
    this.trailingActions,
    this.height = 44.0,
    this.enableLiquidGlass = true,
    this.usePlainTitle = false,
    this.titleColor,
  })  : assert(
          title == null || title.length <= 100,
          'Title must be 100 characters or less for optimal display',
        ),
        assert(
          height >= 44.0 && height <= 200.0,
          'Height must be between 44.0 and 200.0',
        ),
        super(key: key);

  @override
  State<AdaptiveCupertinoToolbar> createState() =>
      _AdaptiveCupertinoToolbarState();

  @override
  Size get preferredSize => Size.fromHeight(height);
}

class _AdaptiveCupertinoToolbarState extends State<AdaptiveCupertinoToolbar> {
  bool _useNativeToolbar = false;
  bool _isCheckingVersion = true;
  MethodChannel? _toolbarChannel;

  @override
  void initState() {
    super.initState();
    _checkIOSVersion();
  }

  Future<void> _checkIOSVersion() async {
    if (!Platform.isIOS) {
      if (mounted) {
        setState(() {
          _useNativeToolbar = false;
          _isCheckingVersion = false;
        });
      }
      return;
    }

    try {
      final supportsModernToolbar = await IOSVersion().supportsModernToolbar();
      if (mounted) {
        setState(() {
          _useNativeToolbar = supportsModernToolbar;
          _isCheckingVersion = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _useNativeToolbar = false;
          _isCheckingVersion = false;
        });
      }
    }
  }

  void _setupPlatformChannel(int viewId) {
    _toolbarChannel = MethodChannel('adaptive_cupertino_ios/toolbar_$viewId');
    _toolbarChannel?.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onLeadingTapped':
        if (widget.leadingAction != null) {
          widget.leadingAction!.onPressed?.call();
        } else {
          _triggerWidgetTap(widget.leading);
        }
        break;
      case 'onTrailingTapped':
        final index = call.arguments['index'] as int?;
        if (index != null) {
          if (widget.trailingActions != null &&
              index < widget.trailingActions!.length) {
            widget.trailingActions![index].onPressed?.call();
          } else if (widget.trailing != null &&
              index < widget.trailing!.length) {
            _triggerWidgetTap(widget.trailing![index]);
          }
        }
        break;
    }
  }

  void _triggerWidgetTap(Widget? widget) {
    if (widget == null) return;
    if (widget is CupertinoButton) {
      widget.onPressed?.call();
    } else {
      try {
        final dynamic dynamicWidget = widget;
        final dynamic onTap = dynamicWidget.onTap;
        if (onTap != null && onTap is VoidCallback) {
          onTap();
        }
      } catch (_) {}
    }
  }

  Map<String, dynamic>? _serializeWidget(Widget widget) {
    if (widget is Icon) {
      return {
        'type': 'icon',
        'iconCode': widget.icon?.codePoint,
        'iconFamily': widget.icon?.fontFamily,
      };
    }
    if (widget is CupertinoButton) {
      final child = widget.child;
      if (child is Icon) {
        return {
          'type': 'icon',
          'iconCode': child.icon?.codePoint,
          'iconFamily': child.icon?.fontFamily,
          'prominent':
              widget.color != null, // Treat colored buttons as prominent
        };
      }
    }
    return null;
  }

  @override
  void dispose() {
    _toolbarChannel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingVersion) {
      return SizedBox(height: widget.height);
    }

    if (_useNativeToolbar) {
      return _buildNativeToolbar();
    }

    // Fallback to standard Cupertino Navigation Bar
    return CupertinoNavigationBar(
      middle: widget.title != null ? Text(widget.title!) : null,
      leading: widget.leading,
      trailing: widget.trailing != null && widget.trailing!.isNotEmpty
          ? Row(mainAxisSize: MainAxisSize.min, children: widget.trailing!)
          : null,
    );
  }

  Widget _buildNativeToolbar() {
    // Serialize leading widget
    Map<String, dynamic>? leadingData;
    if (widget.leadingAction != null) {
      leadingData = widget.leadingAction!.toMap();
      if (kDebugMode) {
        debugPrint('📱 [Toolbar] Using shared Action model for leading');
      }
    } else if (widget.leading != null) {
      leadingData = _serializeWidget(widget.leading!);
    }

    // Serialize trailing widgets
    List<Map<String, dynamic>>? trailingData;
    if (widget.trailingActions != null) {
      trailingData = widget.trailingActions!.map((a) => a.toMap()).toList();
      if (kDebugMode) {
        debugPrint('📱 [Toolbar] Using shared Action model for trailing');
      }
    } else if (widget.trailing != null && widget.trailing!.isNotEmpty) {
      trailingData = widget.trailing!
          .map((w) => _serializeWidget(w))
          .whereType<Map<String, dynamic>>()
          .toList();
    }

    return Container(
      height: 44.0 + MediaQuery.of(context).padding.top,
      // Note: No decoration here - native LiquidGlassBackgroundView handles the blur & gradient
      child: UiKitView(
        viewType: 'adaptive_cupertino_ios/toolbar',
        creationParams: {
          'title': widget.title,
          'topPadding': MediaQuery.of(context).padding.top,
          'enableLiquidGlass': widget.enableLiquidGlass,
          'usePlainTitle': widget.usePlainTitle,
          if (widget.titleColor != null)
            'titleColor': widget.titleColor!.toARGB32(),
          if (leadingData != null) 'leading': leadingData,
          if (trailingData != null) 'trailing': trailingData,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _setupPlatformChannel,
      ),
    );
  }
}
