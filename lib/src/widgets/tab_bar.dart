import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../platform/ios_version.dart';
import '../util/serialization.dart';

/// Model class for tab bar items.
class AdaptiveCupertinoTabItem {
  /// The label displayed below the icon.
  final String label;

  /// The icon to display.
  final IconData icon;

  /// The selected icon variant (defaults to [icon] if not provided).
  final IconData? selectedIcon;

  /// Optional badge text to display on the tab.
  final String? badge;

  /// Optional SF Symbol name override for iOS native TabBar.
  final String? sfSymbolName;

  /// Optional SF Symbol name override for selected state.
  final String? selectedSfSymbolName;

  /// Whether this tab is a search tab (iOS 26+ native only).
  final bool isSearch;

  const AdaptiveCupertinoTabItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badge,
    this.sfSymbolName,
    this.selectedSfSymbolName,
    this.isSearch = false,
  });

  /// Convert to map for platform channel.
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      'label': label,
      'iconCode': icon.codePoint,
      'iconFamily': icon.fontFamily,
    };

    if (sfSymbolName != null) {
      data['iconName'] = sfSymbolName;
      data['selectedIconName'] = selectedSfSymbolName ?? sfSymbolName;
    } else {
      // Phase 2.2: Unified Auto-Mapping
      final autoIcon = WidgetSerializer.getSfSymbolName(icon);
      if (autoIcon != null) {
        data['iconName'] = autoIcon;
      }

      final autoSelectedIcon =
          WidgetSerializer.getSfSymbolName(selectedIcon ?? icon);
      if (autoSelectedIcon != null) {
        data['selectedIconName'] = autoSelectedIcon;
      }
    }

    if (selectedIcon != null) {
      data['selectedIconCode'] = selectedIcon!.codePoint;
      data['selectedIconFamily'] = selectedIcon!.fontFamily;
    } else {
      data['selectedIconCode'] = icon.codePoint;
      data['selectedIconFamily'] = icon.fontFamily;
    }

    if (badge != null) {
      data['badge'] = badge;
    }

    if (isSearch) {
      data['isSearch'] = true;
    }

    return data;
  }
}

/// Adaptive TabBar that uses native iOS implementation on iOS 18+
/// and falls back to CupertinoTabBar on older versions.
class AdaptiveCupertinoTabBar extends StatefulWidget {
  /// List of tab items to display.
  final List<AdaptiveCupertinoTabItem> items;

  /// Currently selected tab index.
  final int currentIndex;

  /// Callback when tab is tapped.
  final ValueChanged<int>? onTap;

  /// Background color (only used in fallback mode).
  final Color? backgroundColor;

  /// Active color for selected items (only used in fallback mode).
  final Color? activeColor;

  /// Inactive color for unselected items (only used in fallback mode).
  final Color? inactiveColor;

  /// The minimization factor (0.0 to 1.0) for dynamic structural transformations.
  /// Only available on iOS 26+ native implementation.
  final double minimizationFactor;

  /// The base elevation level (0.0 to 10.0) for shadow depth.
  final double elevation;

  const AdaptiveCupertinoTabBar({
    Key? key,
    required this.items,
    this.currentIndex = 0,
    this.onTap,
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
    this.minimizationFactor = 0.0,
    this.elevation = 4.0,
  }) : super(key: key);

  @override
  State<AdaptiveCupertinoTabBar> createState() =>
      _AdaptiveCupertinoTabBarState();
}

class _AdaptiveCupertinoTabBarState extends State<AdaptiveCupertinoTabBar> {
  bool _useNativeTabBar = false;
  bool _isCheckingVersion = true;
  MethodChannel? _tabBarChannel;

  @override
  void initState() {
    super.initState();

    // Phase 3: Synchronous Cache Access 🛡️⚡
    final iosVersion = IOSVersion();
    if (iosVersion.cachedSupportsNativeUI != null) {
      _useNativeTabBar = iosVersion.cachedSupportsNativeUI!;
      _isCheckingVersion = false;
    }

    _checkIOSVersion();
  }

  Future<void> _checkIOSVersion() async {
    if (!Platform.isIOS) {
      setState(() {
        _useNativeTabBar = false;
        _isCheckingVersion = false;
      });
      return;
    }

    try {
      final supportsNativeUI = await IOSVersion().supportsNativeUI();
      setState(() {
        _useNativeTabBar = supportsNativeUI;
        _isCheckingVersion = false;
      });

      if (kDebugMode) {
        debugPrint(
          '📱 TabBar: ${supportsNativeUI ? "Using native iOS 18+ TabBar" : "Using fallback CupertinoTabBar"}',
        );
      }
    } catch (e) {
      setState(() {
        _useNativeTabBar = false;
        _isCheckingVersion = false;
      });
    }
  }

  void _setupPlatformChannel(int viewId) {
    _tabBarChannel = MethodChannel('adaptive_cupertino_ios/tab_bar_$viewId');
    _tabBarChannel!.setMethodCallHandler(_handleMethodCall);

    // Set initial selection
    _tabBarChannel!.invokeMethod('selectTab', {'index': widget.currentIndex});

    // Set initial minimization factor
    _tabBarChannel!.invokeMethod(
        'setMinimizationFactor', {'factor': widget.minimizationFactor});

    // Set initial elevation
    _tabBarChannel!
        .invokeMethod('setElevation', {'elevation': widget.elevation});
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onTabChanged':
        final args = call.arguments as Map<dynamic, dynamic>;
        final index = args['index'] as int;
        widget.onTap?.call(index);
        break;
    }
  }

  @override
  void didUpdateWidget(AdaptiveCupertinoTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update selection if changed externally
    if (widget.currentIndex != oldWidget.currentIndex && _useNativeTabBar) {
      _tabBarChannel?.invokeMethod('selectTab', {'index': widget.currentIndex});
    }

    // Update minimization factor if changed
    if (widget.minimizationFactor != oldWidget.minimizationFactor &&
        _useNativeTabBar) {
      _tabBarChannel?.invokeMethod(
          'setMinimizationFactor', {'factor': widget.minimizationFactor});
    }

    // Update elevation if changed
    if (widget.elevation != oldWidget.elevation && _useNativeTabBar) {
      _tabBarChannel
          ?.invokeMethod('setElevation', {'elevation': widget.elevation});
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

    if (_isCheckingVersion) {
      return const SizedBox(height: 49);
    }

    if (_useNativeTabBar) {
      return _buildNativeTabBar();
    }

    return _buildFallbackTabBar();
  }

  Widget _buildNativeTabBar() {
    if (kDebugMode) {
      debugPrint('🔍 [TabBar-Dart] Building native TabBar');
      debugPrint('🔍 [TabBar-Dart] Items count: ${widget.items.length}');
      for (var i = 0; i < widget.items.length; i++) {
        final itemMap = widget.items[i].toMap();
        debugPrint('🔍 [TabBar-Dart] Item $i: $itemMap');
      }
    }

    return SizedBox(
      height: 83, // Standard tab bar height + safe area
      width: double.infinity,
      child: UiKitView(
        viewType: 'adaptive_cupertino_ios/tab_bar',
        creationParams: {
          'items': widget.items.map((item) => item.toMap()).toList(),
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: (int viewId) {
          if (kDebugMode) {
            debugPrint(
                '🔍 [TabBar-Dart] Platform view created with ID: $viewId');
          }
          _setupPlatformChannel(viewId);
        },
      ),
    );
  }

  Widget _buildFallbackTabBar() {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS) {
      return CupertinoTabBar(
        items: widget.items.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            activeIcon: Icon(item.selectedIcon ?? item.icon),
            label: item.label,
          );
        }).toList(),
        currentIndex: widget.currentIndex,
        onTap: widget.onTap,
        backgroundColor: widget.backgroundColor,
        activeColor: widget.activeColor ?? CupertinoColors.activeBlue,
        inactiveColor: widget.inactiveColor ?? CupertinoColors.inactiveGray,
      );
    }

    // Material Fallback
    return BottomNavigationBar(
      items: widget.items.map((item) {
        return BottomNavigationBarItem(
          icon: Icon(item.icon),
          activeIcon: Icon(item.selectedIcon ?? item.icon),
          label: item.label,
        );
      }).toList(),
      currentIndex: widget.currentIndex,
      onTap: widget.onTap,
      backgroundColor: widget.backgroundColor,
      selectedItemColor: widget.activeColor,
      unselectedItemColor: widget.inactiveColor,
      type: BottomNavigationBarType.fixed,
    );
  }

  /// Set badge value for a tab item at [index].
  ///
  /// Only works with native iOS TabBar (iOS 18+).
  /// Example:
  /// ```dart
  /// setState(() => _tabBarState?.setBadge(2, '5'));
  /// ```
  Future<void> setBadge(int index, String badge) async {
    if (_tabBarChannel != null && _useNativeTabBar) {
      await _tabBarChannel!.invokeMethod('setBadge', {
        'index': index,
        'badge': badge,
      });
    }
  }

  /// Clear badge value for a tab item at [index].
  ///
  /// Only works with native iOS TabBar (iOS 18+).
  Future<void> clearBadge(int index) async {
    if (_tabBarChannel != null && _useNativeTabBar) {
      await _tabBarChannel!.invokeMethod('clearBadge', {'index': index});
    }
  }

  /// Set badge color for a tab item at [index].
  ///
  /// Only works with native iOS TabBar (iOS 10+).
  /// [color] should be a hex string like '#FF0000' or 'FF0000'.
  Future<void> setBadgeColor(int index, String color) async {
    if (_tabBarChannel != null && _useNativeTabBar) {
      await _tabBarChannel!.invokeMethod('setBadgeColor', {
        'index': index,
        'color': color,
      });
    }
  }

  @override
  void dispose() {
    _tabBarChannel?.setMethodCallHandler(null);
    super.dispose();
  }
}
