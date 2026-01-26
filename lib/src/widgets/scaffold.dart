import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_bar.dart';
import 'tab_bar.dart';

/// Adaptive scaffold that provides platform-appropriate layout.
///
/// Uses CupertinoPageScaffold on iOS and Material Scaffold on Android.
/// Automatically handles AppBar and BottomNavigationBar with adaptive widgets.
class AdaptiveScaffold extends StatelessWidget {
  /// The primary content of the scaffold.
  final Widget body;

  /// Optional app bar at the top.
  ///
  /// On iOS, uses [AdaptiveCupertinoAppBar].
  /// On Android, uses Material AppBar.
  final PreferredSizeWidget? appBar;

  /// Optional bottom navigation bar.
  ///
  /// On iOS, uses [AdaptiveCupertinoTabBar].
  /// On Android, uses Material BottomNavigationBar.
  final Widget? bottomNavigationBar;

  /// Background color of the scaffold.
  final Color? backgroundColor;

  /// Whether the body should extend behind the app bar.
  ///
  /// Defaults to false.
  final bool extendBodyBehindAppBar;

  /// Key for the scaffold.
  final Key? scaffoldKey;

  /// Floating action button (Android only).
  ///
  /// Ignored on iOS.
  final Widget? floatingActionButton;

  /// Whether to resize the body when keyboard appears.
  ///
  /// Defaults to true.
  final bool? resizeToAvoidBottomInset;

  const AdaptiveScaffold({
    Key? key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.extendBodyBehindAppBar = false,
    this.scaffoldKey,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    if (platform == TargetPlatform.iOS) {
      return _buildIOSScaffold(context);
    }

    return _buildMaterialScaffold(context);
  }

  Widget _buildIOSScaffold(BuildContext context) {
    // Standard Flutter Way for Liquid Glass: Use a Stack to layer the AppBar over the body.
    // This allows the body content to start at the top (under the notch) and flow behind the bar.
    return CupertinoPageScaffold(
      backgroundColor: backgroundColor ?? CupertinoColors.systemBackground,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset ?? true,
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            // 1. The primary content (Full screen, including area behind bars)
            Positioned.fill(child: body),

            // 2. The AppBar as an overlay at the top
            if (appBar != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: appBar!,
              ),

            // 3. Custom Bottom Navigation Bar at the bottom
            if (bottomNavigationBar != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: bottomNavigationBar!,
              ),

            // 4. Floating Action Button (Handled here as CupertinoScaffold doesn't have one)
            if (floatingActionButton != null)
              Positioned(
                right: 16,
                bottom:
                    (bottomNavigationBar != null || Platform.isIOS ? 80 : 16) +
                        MediaQuery.paddingOf(context).bottom,
                child: floatingActionButton!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialScaffold(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

/// Convenience wrapper for AdaptiveScaffold with typed AppBar and TabBar.
///
/// Provides a cleaner API for common use cases.
class AdaptiveScaffoldWithNavigation extends StatelessWidget {
  /// The primary content of the scaffold.
  final Widget body;

  /// Title for the app bar.
  final String? title;

  /// Leading widget for the app bar (typically a back button).
  final Widget? leading;

  /// Trailing widgets for the app bar (typically action buttons).
  final List<Widget>? trailing;

  /// Whether to use large title on iOS 11+.
  final bool largeTitle;

  /// Tab bar items.
  final List<AdaptiveCupertinoTabItem>? tabItems;

  /// Currently selected tab index.
  final int currentTabIndex;

  /// Callback when tab is tapped.
  final ValueChanged<int>? onTabTap;

  /// Background color of the scaffold.
  final Color? backgroundColor;

  const AdaptiveScaffoldWithNavigation({
    Key? key,
    required this.body,
    this.title,
    this.leading,
    this.trailing,
    this.largeTitle = false,
    this.tabItems,
    this.currentTabIndex = 0,
    this.onTabTap,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      backgroundColor: backgroundColor,
      appBar: title != null
          ? AdaptiveCupertinoAppBar(
              title: Text(title!),
              leading: leading,
              trailing: trailing,
              largeTitle: largeTitle,
            )
          : null,
      bottomNavigationBar: tabItems != null && tabItems!.isNotEmpty
          ? AdaptiveCupertinoTabBar(
              items: tabItems!,
              currentIndex: currentTabIndex,
              onTap: onTabTap,
            )
          : null,
      body: body,
    );
  }
}
