import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../platform/ios_version.dart';

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

  const AdaptiveCupertinoTabItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badge,
    this.sfSymbolName,
    this.selectedSfSymbolName,
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

  const AdaptiveCupertinoTabBar({
    Key? key,
    required this.items,
    this.currentIndex = 0,
    this.onTap,
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
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
  }

  @override
  Widget build(BuildContext context) {
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
