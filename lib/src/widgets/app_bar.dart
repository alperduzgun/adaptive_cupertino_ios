import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../platform/ios_version.dart';
import '../util/serialization.dart';
import 'action.dart';
import 'layout_notification.dart';

/// Configuration options for native search bar in [AdaptiveCupertinoAppBar].
class AdaptiveCupertinoSearchOptions {
  /// The placeholder text to display in the search bar.
  final String? placeholder;

  /// Whether to hide the search bar when the user scrolls.
  ///
  /// Defaults to true.
  final bool hidesNavigationBarDuringPresentation;

  /// Whether to automatically show the cancel button.
  ///
  /// Defaults to true.
  final bool automaticallyShowsCancelButton;

  /// Whether the search bar should be initially visible.
  final bool initiallyVisible;

  /// Callback when the search query changes.
  final ValueChanged<String>? onQueryChanged;

  /// Callback when search is submitted.
  final ValueChanged<String>? onSubmitted;

  /// Callback when search is cancelled.
  final VoidCallback? onCancelled;

  /// Whether to automatically add a search action button to the trailing position.
  ///
  /// Defaults to true. Set to false if you want to manually place the search action
  /// using [AdaptiveCupertinoAction] with [isSearchAction: true].
  final bool automaticallyImplySearchAction;

  const AdaptiveCupertinoSearchOptions({
    this.placeholder,
    this.hidesNavigationBarDuringPresentation = true,
    this.automaticallyShowsCancelButton = true,
    this.initiallyVisible = false,
    this.onQueryChanged,
    this.onSubmitted,
    this.onCancelled,
    this.automaticallyImplySearchAction = true,
  });

  Map<String, dynamic> toMap() {
    return {
      if (placeholder != null) 'placeholder': placeholder,
      'hidesNavigationBarDuringPresentation':
          hidesNavigationBarDuringPresentation,
      'automaticallyShowsCancelButton': automaticallyShowsCancelButton,
      'initiallyVisible': initiallyVisible,
      'automaticallyImplySearchAction': automaticallyImplySearchAction,
    };
  }
}

/// Controller for [AdaptiveCupertinoAppBar] to control search and other native behaviors.
class AdaptiveCupertinoAppBarController extends ChangeNotifier {
  bool _isSearchActive = false;
  bool get isSearchActive => _isSearchActive;

  /// Programmatically set the search bar active/inactive.
  void setSearchActive(bool active) {
    _isSearchActive = active;
    notifyListeners();
  }
}

/// Adaptive AppBar that uses native iOS UINavigationBar on iOS 18+
/// and falls back to CupertinoNavigationBar on older versions.
class AdaptiveCupertinoAppBar extends StatefulWidget
    implements ObstructingPreferredSizeWidget {
  /// The title widget displayed in the navigation bar.
  final Widget? title;

  /// Widget to place at the leading position (typically a back button).
  final Widget? leading;

  /// Reliable leading action (uses IconData).
  final AdaptiveCupertinoAction? leadingAction;

  /// Widgets to place at the trailing position (typically action buttons).
  final List<Widget>? trailing;

  /// Reliable trailing actions (uses IconData).
  final List<AdaptiveCupertinoAction>? trailingActions;

  /// Whether to display the title as a large title on iOS 11+.
  ///
  /// Only applicable when using native iOS navigation bar.
  /// Defaults to false.
  final bool largeTitle;

  /// Background color (only used in fallback mode).
  final Color? backgroundColor;

  /// Border settings (only used in fallback mode).
  final Border? border;

  /// Padding for the middle widget (only used in fallback mode).
  final EdgeInsetsDirectional? padding;

  /// Whether to automatically add a back button (only in fallback mode).
  final bool automaticallyImplyLeading;

  /// Controller for programmatic interaction.
  final AdaptiveCupertinoAppBarController? controller;

  /// Search configuration for native search bar.
  final AdaptiveCupertinoSearchOptions? searchOptions;

  /// The minimization factor of the app bar (0.0 to 1.0).
  ///
  /// 0.0 means fully expanded (Large Title visible if [largeTitle] is true).
  /// 1.0 means fully minimized (Standard height, title in middle).
  final double minimizationFactor;

  /// Unique identifier for Liquid Morphing (iOS 26+).
  ///
  /// If provided, the navigation bar's glass backing can morph into/from other
  /// elements (like sheets or buttons) with the same [glassEffectID].
  final String? glassEffectID;

  const AdaptiveCupertinoAppBar({
    Key? key,
    this.title,
    this.leading,
    this.leadingAction,
    this.trailing,
    this.trailingActions,
    this.searchOptions,
    this.controller,
    this.largeTitle = false,
    this.minimizationFactor = 0.0,
    this.glassEffectID,
    this.backgroundColor,
    this.border,
    this.padding,
    this.automaticallyImplyLeading = true,
  }) : super(key: key);

  @override
  State<AdaptiveCupertinoAppBar> createState() =>
      _AdaptiveCupertinoAppBarState();

  @override
  Size get preferredSize {
    // NATIVE UI HEIGHTS:
    // Standard: 44.0
    // Large Title: 96.0 (approx 52 extra)
    // Search Bar: +52.0
    double height = largeTitle ? 96.0 : 44.0;
    if (searchOptions != null) {
      height += 52.0;
    }
    return Size.fromHeight(height);
  }

  @override
  bool shouldFullyObstruct(BuildContext context) => false;
}

class _AdaptiveCupertinoAppBarState extends State<AdaptiveCupertinoAppBar> {
  bool _useNativeAppBar = false;
  bool _useModernToolbar = false; // iOS 26+ native UIToolbar
  bool _isCheckingVersion = true;
  MethodChannel? _appBarChannel;
  String? _titleText;

  @override
  void initState() {
    super.initState();
    _extractTitleText();

    // Phase 3: Synchronous Cache Access 🛡️⚡
    // If we have pre-warmed values, we can skip the initial flicker
    final iosVersion = IOSVersion();
    if (iosVersion.cachedSupportsNativeUI != null) {
      _useNativeAppBar = iosVersion.cachedSupportsNativeUI!;
      _useModernToolbar = iosVersion.cachedSupportsModernToolbar ?? false;
      _isCheckingVersion = false;
    }

    _checkIOSVersion();
    widget.controller?.addListener(_handleControllerChange);
  }

  void _handleControllerChange() {
    if (widget.controller != null &&
        _appBarChannel != null &&
        _useNativeAppBar) {
      _appBarChannel?.invokeMethod('setSearchActive', {
        'active': widget.controller!.isSearchActive,
      });
    }
  }

  void _extractTitleText() {
    _titleText = WidgetSerializer.extractText(widget.title);
  }

  /// Check iOS version for native UI support
  /// CHAOS RESISTANT: Multiple fallback layers, fail-safe defaults
  /// IDEMPOTENT: Safe to call multiple times (cached by IOSVersion)
  Future<void> _checkIOSVersion() async {
    // Fast path: Non-iOS platforms
    if (!Platform.isIOS) {
      if (mounted) {
        setState(() {
          _useNativeAppBar = false;
          _useModernToolbar = false;
          _isCheckingVersion = false;
        });
      }
      return;
    }

    try {
      // Check iOS 26+ for modern toolbar (ANTI-FRAGILE: Primary check)
      final supportsModernToolbar = await IOSVersion().supportsModernToolbar();

      // Fallback: Check iOS 18+ for navigation bar (GRACEFUL DEGRADATION)
      final supportsNativeUI = await IOSVersion().supportsNativeUI();

      if (mounted) {
        setState(() {
          _useModernToolbar = supportsModernToolbar;
          _useNativeAppBar = supportsNativeUI;
          _isCheckingVersion = false;
        });
      }

      // OBSERVABILITY: Structured logging
      if (kDebugMode) {
        debugPrint(
            '📱 AppBar: Version check result - Modern: $supportsModernToolbar, NativeUI: $supportsNativeUI');
      }
    } catch (e) {
      // FAIL-SAFE: On any error, use fallback
      if (kDebugMode) {
        debugPrint('⚠️ AppBar: Version check failed: $e, using fallback');
      }

      if (mounted) {
        setState(() {
          _useNativeAppBar = false;
          _useModernToolbar = false;
          _isCheckingVersion = false;
        });
      }
    }
  }

  void _setupPlatformChannel(int viewId) {
    _appBarChannel = MethodChannel('adaptive_cupertino_ios/app_bar_$viewId');
    _appBarChannel?.setMethodCallHandler(_handleMethodCall);

    // Sync initial shrinkage
    if (widget.minimizationFactor > 0) {
      _appBarChannel?.invokeMethod(
          'setMinimizationFactor', {'factor': widget.minimizationFactor});
    }
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
      case 'onLayoutChanged':
        final args = call.arguments as Map<dynamic, dynamic>;
        final height = args['height'] as double;
        final safeArea = args['safeArea'] as double;

        if (mounted) {
          AdaptiveLayoutNotification(
            height: height,
            isTop: true,
            safeArea: safeArea,
          ).dispatch(context);
        }
        break;
    }
  }

  void _triggerWidgetTap(Widget? widget) {
    if (widget == null) return;

    // Try to extract and call onPressed from CupertinoButton
    if (widget is CupertinoButton) {
      widget.onPressed?.call();
      return;
    }

    // Try to extract and call onTap from GestureDetector
    try {
      final dynamic dynamicWidget = widget;
      final dynamic onTap = dynamicWidget.onTap;
      if (onTap != null && onTap is VoidCallback) {
        onTap();
      }
    } catch (_) {
      // Widget doesn't have onTap
    }
  }

  @override
  void didUpdateWidget(AdaptiveCupertinoAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Safe controller lifecycle management
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChange);
      widget.controller?.addListener(_handleControllerChange);

      if (_useNativeAppBar && widget.controller != null) {
        _handleControllerChange();
      }
    }

    // Update title if changed
    if (widget.title != oldWidget.title) {
      _extractTitleText();
      if (_useNativeAppBar && _titleText != null) {
        _appBarChannel?.invokeMethod('setTitle', {'title': _titleText});
      }
    }

    // Update large title setting if changed
    if (widget.largeTitle != oldWidget.largeTitle && _useNativeAppBar) {
      _appBarChannel?.invokeMethod('setLargeTitle', {
        'enabled': widget.largeTitle,
      });
    }

    // Dynamic shrinkage sync
    if (widget.minimizationFactor != oldWidget.minimizationFactor &&
        _useNativeAppBar) {
      _appBarChannel?.invokeMethod(
          'setMinimizationFactor', {'factor': widget.minimizationFactor});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Multi-View Awareness (Tech Lead Fix):
    // If this widget is rendered in a secondary view (like a native bottom sheet),
    // it MUST hide itself to prevent "UI Mirroring" of the main app's layout.
    try {
      if (View.of(context).viewId != 0) {
        return const SizedBox.shrink();
      }
    } catch (_) {
      // Fallback for environments whereView.of fails
    }

    // Show placeholder while checking version (CHAOS: Non-blocking UI)
    if (_isCheckingVersion) {
      return SizedBox(
        height: widget.preferredSize.height,
        child: Container(
          color: CupertinoColors.systemBackground.resolveFrom(context),
        ),
      );
    }

    // ANTI-FRAGILE: Three-tier fallback strategy
    // 1. iOS 26+ → Native UIToolbar (pill-shaped buttons)
    // 2. iOS 18-25 → Native UINavigationBar (liquid glass)
    // 3. iOS <18 → CupertinoNavigationBar (standard)

    // Validate prerequisites for native UI
    // SECURITY: Ensure title is available and widgets are serializable
    bool canUseNative =
        (_useModernToolbar || _useNativeAppBar) && _titleText != null;

    if (kDebugMode && !canUseNative && !_isCheckingVersion) {
      debugPrint('⚠️ [AppBar] canUseNative is FALSE: '
          'useModern: $_useModernToolbar, useNative: $_useNativeAppBar, '
          'titleText: ${_titleText != null}');
    }

    if (canUseNative) {
      // Check serialization only if explicit actions are NOT provided
      if (widget.leadingAction == null && widget.leading != null) {
        final leadingData = WidgetSerializer.serialize(widget.leading!);
        if (leadingData == null) {
          canUseNative = false;
          if (kDebugMode) {
            debugPrint(
                '⚠️ [AppBar] Leading widget not serializable, using fallback');
          }
        }
      }
    }

    if (canUseNative) {
      if (widget.trailingActions == null &&
          widget.trailing != null &&
          widget.trailing!.isNotEmpty) {
        final trailingData = widget.trailing!
            .map((w) => WidgetSerializer.serialize(w))
            .whereType<Map<String, dynamic>>()
            .toList();
        if (trailingData.isEmpty) {
          canUseNative = false;
          if (kDebugMode) {
            debugPrint(
                '⚠️ [AppBar] Trailing widgets not serializable, using fallback');
          }
        }
      }
    }

    // SAFETY CHECK: Ensure manageability by warning about multiple search actions
    if (kDebugMode && widget.trailingActions != null) {
      final searchActionCount =
          widget.trailingActions!.where((a) => a.isSearchAction).length;
      if (searchActionCount > 1) {
        debugPrint(
            '⚠️ [AdaptiveCupertinoAppBar] Warning: You have $searchActionCount manual search actions. '
            'All of them will trigger the same search bar. Consider using only one.');
      }
    }

    // ROUTING: Choose appropriate implementation
    if (canUseNative) {
      if (_useNativeAppBar) {
        // iOS 18+: Use the modernized NavigationBar factory for all AppBars.
        // It provides the "True iOS 26" detached pill look and Large Title support.
        if (kDebugMode && _useModernToolbar) {
          debugPrint(
              '📱 AppBar: Using native Modernized UINavigationBar (iOS 26+)');
        }
        return _buildNativeAppBar();
      }
    }

    // Fallback: Cupertino standard (iOS <18 or serialization failed)
    if (kDebugMode) {
      debugPrint('📱 AppBar: Using fallback CupertinoNavigationBar');
      debugPrint('   Has leading: ${widget.leading != null}');
      debugPrint('   Has trailing: ${widget.trailing != null}');
      debugPrint('   Title: ${widget.title}');
    }

    return _buildFallbackAppBar(context);
  }

  /// Build iOS 18-25 native UINavigationBar
  Widget _buildNativeAppBar() {
    // Serialize leading widget
    Map<String, dynamic>? leadingData;
    if (widget.leadingAction != null) {
      leadingData = widget.leadingAction!.toMap();
    } else if (widget.leading != null) {
      leadingData = WidgetSerializer.serialize(widget.leading!);
      if (kDebugMode) {
        debugPrint('📱 [AppBar] Serialized leading: $leadingData');
      }
    }

    // Serialize trailing widgets
    List<Map<String, dynamic>>? trailingData;
    if (widget.trailingActions != null) {
      trailingData = widget.trailingActions!.map((a) => a.toMap()).toList();
    } else if (widget.trailing != null && widget.trailing!.isNotEmpty) {
      trailingData = widget.trailing!
          .map((w) => WidgetSerializer.serialize(w))
          .whereType<Map<String, dynamic>>()
          .toList();
      if (kDebugMode) {
        debugPrint('📱 [AppBar] Serialized trailing: $trailingData');
      }
    }

    final bool isIOS26Plus = _useModernToolbar;
    final double baseHeight = widget.largeTitle
        ? (isIOS26Plus ? 104.0 : 96.0)
        : (isIOS26Plus ? 52.0 : 44.0);
    final double shrunkHeight = isIOS26Plus ? 52.0 : 44.0;
    final double currentHeight = widget.largeTitle
        ? (baseHeight - (baseHeight - shrunkHeight) * widget.minimizationFactor)
        : baseHeight;

    return SizedBox(
      height: currentHeight + MediaQuery.paddingOf(context).top,
      child: UiKitView(
        viewType: 'adaptive_cupertino_ios/navigation_bar',
        creationParams: {
          'title': _titleText,
          'largeTitle': widget.largeTitle,
          'minimizationFactor': widget.minimizationFactor,
          'topPadding': MediaQuery.paddingOf(context).top,
          if (leadingData != null) 'leading': leadingData,
          if (trailingData != null) 'trailing': trailingData,
          if (widget.glassEffectID != null)
            'glassEffectID': widget.glassEffectID,
          if (widget.searchOptions != null)
            'searchOptions': widget.searchOptions!.toMap(),
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _setupPlatformChannel,
      ),
    );
  }

  // Serialization moved to WidgetSerializer utility

  Widget _buildFallbackAppBar(BuildContext context) {
    // Style fallback to look like iOS 18+ liquid glass
    // Style fallback to look like iOS 18+ liquid glass
    return Builder(
      builder: (context) {
        // Use blur background for iOS 18+ look
        return ColoredBox(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoNavigationBar(
                  middle: widget.title,
                  leading: widget.leading,
                  trailing:
                      widget.trailing != null && widget.trailing!.isNotEmpty
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: widget.trailing!,
                            )
                          : null,
                  backgroundColor: widget.backgroundColor ??
                      CupertinoColors.systemBackground
                          .resolveFrom(context)
                          .withOpacity(
                              0.8), // Semi-transparent like liquid glass
                  border: widget.border ??
                      Border(
                        bottom: BorderSide(
                          color: CupertinoColors.separator
                              .resolveFrom(context)
                              .withOpacity(0.3),
                          width: 0.0,
                        ),
                      ),
                  padding: widget.padding,
                  automaticallyImplyLeading: widget.automaticallyImplyLeading,
                  transitionBetweenRoutes: true, // Smooth transitions
                ),
                if (widget.searchOptions != null)
                  Container(
                    color: widget.backgroundColor ??
                        CupertinoColors.systemBackground.resolveFrom(context),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: CupertinoSearchTextField(
                      placeholder: widget.searchOptions?.placeholder,
                      onChanged: widget.searchOptions?.onQueryChanged,
                      onSubmitted: widget.searchOptions?.onSubmitted,
                      onSuffixTap: widget.searchOptions?.onCancelled,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleControllerChange);
    _appBarChannel?.setMethodCallHandler(null);
    super.dispose();
  }
}
