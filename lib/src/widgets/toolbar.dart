import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../platform/ios_version.dart';
import '../util/serialization.dart';
import 'action.dart';
import 'app_bar.dart';
import 'layout_notification.dart';

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

  /// Search configuration for native search bar.
  final AdaptiveCupertinoSearchOptions? searchOptions;

  /// Controller for programmatic interaction.
  final AdaptiveCupertinoAppBarController? controller;

  /// Whether the toolbar is positioned at the bottom of the screen.
  ///
  /// When true, the toolbar will apply bottom safe area padding (Home Indicator)
  /// and render as a floating capsule (Pill) on iOS 26+.
  final bool isBottom;

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
    this.searchOptions,
    this.controller,
    this.isBottom = false,
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
    widget.controller?.addListener(_handleControllerChange);
  }

  @override
  void didUpdateWidget(AdaptiveCupertinoToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChange);
      widget.controller?.addListener(_handleControllerChange);

      if (_useNativeToolbar && widget.controller != null) {
        // Sync new controller state immediately
        _handleControllerChange();
      }
    }
  }

  void _handleControllerChange() {
    if (widget.controller != null &&
        _toolbarChannel != null &&
        _useNativeToolbar) {
      _toolbarChannel?.invokeMethod('setSearchActive', {
        'active': widget.controller!.isSearchActive,
      });
    }
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
      case 'onSearchQueryChanged':
        final args = call.arguments as Map<dynamic, dynamic>;
        final query = args['query'] as String;
        widget.searchOptions?.onQueryChanged?.call(query);
        break;
      case 'onSearchSubmitted':
        final args = call.arguments as Map<dynamic, dynamic>;
        final query = args['query'] as String;
        widget.searchOptions?.onSubmitted?.call(query);
        break;
      case 'onSearchCancelled':
        widget.searchOptions?.onCancelled?.call();
        break;
      case 'onSearchActive':
        final active = call.arguments['active'] as bool;
        widget.controller?.setSearchActive(active);
        break;
      case 'onLayoutChanged':
        final args = call.arguments as Map<dynamic, dynamic>;
        final height = args['height'] as double;
        final safeArea = args['safeArea'] as double;

        if (mounted) {
          // Dispatch notification up to AdaptiveScaffold
          AdaptiveLayoutNotification(
            height: height,
            isTop: false,
            safeArea: safeArea,
          ).dispatch(context);
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

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChange);
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
      leadingData = WidgetSerializer.serialize(widget.leading!);
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
          .map((w) => WidgetSerializer.serialize(w))
          .whereType<Map<String, dynamic>>()
          .toList();
    }

    final bool isIOS26Plus = _useNativeToolbar;
    final double adjustedHeight = widget.height + (isIOS26Plus ? 12.0 : 0.0);

    // CHAOS SAFETY: Prevent NaN/Infinite from breaking platform view frame
    final double rawTopPadding = MediaQuery.paddingOf(context).top;
    final double topPadding =
        (rawTopPadding.isNaN || rawTopPadding.isInfinite) ? 0.0 : rawTopPadding;

    final double rawBottomPadding = MediaQuery.paddingOf(context).bottom;
    final double bottomPadding =
        (rawBottomPadding.isNaN || rawBottomPadding.isInfinite)
            ? 0.0
            : rawBottomPadding;

    final double totalHeight =
        adjustedHeight + (widget.isBottom ? bottomPadding : topPadding);

    final double validHeight =
        (totalHeight.isNaN || totalHeight.isInfinite) ? 44.0 : totalHeight;

    return SizedBox(
      height: validHeight,
      child: UiKitView(
        viewType: 'adaptive_cupertino_ios/toolbar',
        creationParams: {
          'title': widget.title,
          'topPadding': topPadding,
          'bottomPadding': bottomPadding,
          'isBottom': widget.isBottom,
          'enableLiquidGlass': widget.enableLiquidGlass,
          'usePlainTitle': widget.usePlainTitle,
          if (widget.titleColor != null) 'titleColor': widget.titleColor!.value,
          if (leadingData != null) 'leading': leadingData,
          if (trailingData != null) 'trailing': trailingData,
          if (widget.searchOptions != null)
            'searchOptions': widget.searchOptions!.toMap(),
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _setupPlatformChannel,
      ),
    );
  }
}
