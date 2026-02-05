import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_bar.dart';
import 'layout_notification.dart';
import 'tab_bar.dart';

/// Base breathing room added to the top of the content
/// to prevent visual cramping under the Liquid Glass header.
/// Set to 0.0 as native bars now report accurate logical heights
/// including their own internal safe margins.
const double _kLiquidGlassBreathingRoom = 8.0;

/// Adaptive scaffold that provides platform-appropriate layout.
///
/// Uses CupertinoPageScaffold on iOS and Material Scaffold on Android.
/// Automatically handles AppBar and BottomNavigationBar with adaptive widgets.
class AdaptiveScaffold extends StatefulWidget {
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
  /// **IMPORTANT for iOS 26:** Setting this to `true` is required for the
  /// "True iOS 26" look where content flows behind the detached pill header.
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

  /// Additional top padding to apply to the body content.
  ///
  /// Defaults to 20.0.
  ///
  /// Note: A base breathing room of 20.0px is ALWAYS added on top of this value.
  /// So effectively: NativeBar + 20.0 + topPaddingAdjustment.
  final double topPaddingAdjustment;

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
    this.topPaddingAdjustment = 0.0,
  }) : super(key: key);

  @override
  State<AdaptiveScaffold> createState() => _AdaptiveScaffoldState();
}

class _AdaptiveScaffoldState extends State<AdaptiveScaffold> {
  // Dynamic layout state
  double _topObstruction = 0.0;
  double _bottomObstruction = 0.0;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize with preferred sizes to avoid jump
    _topObstruction = widget.appBar?.preferredSize.height ?? 0.0;
    // Bottom obstruction will be refined in didChangeDependencies to include Safe Area
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      if (widget.bottomNavigationBar != null) {
        // Initial estimate: Standard 50.0 + Home Indicator
        _bottomObstruction = 50.0 + MediaQuery.of(context).padding.bottom;
      } else {
        _bottomObstruction = 0.0;
      }

      if (widget.appBar != null) {
        // Initial estimate: Preferred height + Status bar
        _topObstruction = widget.appBar!.preferredSize.height +
            MediaQuery.of(context).padding.top;
      }
    }
  }

  @override
  void didUpdateWidget(AdaptiveScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update defaults if widget changes and we haven't received dynamic updates yet?
    // Actually, if we have dynamic updates, we should trust them.
    // But if appBar is removed (null), we should reset.
    if (widget.appBar == null) {
      _topObstruction = 0.0;
    } else if (widget.appBar != oldWidget.appBar && !_initialized) {
      // PRE-WARM INITIALIZATION:
      // If we don't have a report yet, estimate the total height.
      // Standard: 44.0 (AppBar) + ~47.0 (StatusBar) = ~91.0
      _topObstruction = (widget.appBar?.preferredSize.height ?? 0.0) +
          MediaQuery.paddingOf(context).top;
    }

    if (widget.bottomNavigationBar == null) {
      _bottomObstruction = 0.0;
    } else if (widget.bottomNavigationBar != oldWidget.bottomNavigationBar &&
        !_initialized) {
      // Standard: ~34.0 (Home Indicator) + ~50.0 (Toolbar) = ~84.0
      _bottomObstruction = 50.0 + MediaQuery.paddingOf(context).bottom;
    }
  }

  bool _handleLayoutNotification(AdaptiveLayoutNotification notification) {
    setState(() {
      _initialized = true;
      if (notification.isTop) {
        _topObstruction = notification.height;
      } else {
        _bottomObstruction = notification.height;
      }
    });
    return true; // Stop bubbling
  }

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
    // standard height for Cupertino Tab Bar is 50.0
    // final double topObstruction = appBar?.preferredSize.height ?? 0.0;
    // final double bottomObstruction = bottomNavigationBar != null ? 50.0 : 0.0;

    return NotificationListener<AdaptiveLayoutNotification>(
      onNotification: _handleLayoutNotification,
      child: CupertinoPageScaffold(
        backgroundColor:
            widget.backgroundColor ?? CupertinoColors.systemBackground,
        resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset ?? true,
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              // 1. The primary content (Full screen, including area behind bars)
              // 1. The primary content (Full screen, including area behind bars)
              Positioned.fill(
                child: Builder(
                  builder: (context) {
                    final mediaQuery = MediaQuery.of(context);
                    final padding = mediaQuery.padding;

                    // ABSOLUTE HEIGHT PROTOCOL:
                    // Native bars now report their total visual height (including status bar/home indicator).
                    // This simplifies everything: we just use the reported values as direct offsets.
                    final topPadding = _topObstruction +
                        widget.topPaddingAdjustment +
                        _kLiquidGlassBreathingRoom;

                    // REVERT: Physical Constraint for Liquid Glass
                    // We want content to flow BEHIND the bottom bar.
                    // So we do NOT physically padding the bottom.
                    final bottomPadding = _bottomObstruction;

                    // AUTO-OFFSET LOGIC (Global Fix):
                    final double effectiveContentTopPadding =
                        widget.extendBodyBehindAppBar ? 0.0 : topPadding;

                    // We allow body to extend to the bottom (behind the bar).
                    const double effectiveContentBottomPadding = 0.0;

                    // For the injected MediaQuery:
                    // We tell the child about the bottom obstruction so it can pad its list end.
                    final double effectiveInjectedTopPadding =
                        widget.extendBodyBehindAppBar ? topPadding : 0.0;

                    final double effectiveInjectedBottomPadding = bottomPadding;

                    return Padding(
                      padding: EdgeInsets.only(top: effectiveContentTopPadding),
                      child: MediaQuery(
                        data: mediaQuery.copyWith(
                          padding: padding.copyWith(
                            top: effectiveInjectedTopPadding,
                            bottom: effectiveInjectedBottomPadding,
                          ),
                        ),
                        child: widget.body,
                      ),
                    );
                  },
                ),
              ),

              // 2. The AppBar as an overlay at the top
              if (widget.appBar != null)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  // We provide the system's actual hardware padding (viewPadding)
                  // to the AppBar so it can correctly normalize its native reporting,
                  // even if the local 'padding' has been consumed by a parent shell.
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      padding: MediaQuery.viewPaddingOf(context),
                    ),
                    child: widget.appBar!,
                  ),
                ),

              // 3. Custom Bottom Navigation Bar at the bottom
              if (widget.bottomNavigationBar != null)
                Builder(
                  builder: (context) {
                    final mediaQuery = MediaQuery.of(context);
                    final viewPadding = MediaQuery.viewPaddingOf(context);

                    // SMART NESTING:
                    final bool isNested =
                        mediaQuery.padding.bottom > viewPadding.bottom;

                    final double lift =
                        isNested ? mediaQuery.padding.bottom : 0.0;

                    // If lifted, neutralize internal padding (pass 0 bottom).
                    final double injectedBottomPadding =
                        isNested ? 0.0 : viewPadding.bottom;

                    return Positioned(
                      bottom: lift,
                      left: 0,
                      right: 0,
                      child: MediaQuery(
                        data: mediaQuery.copyWith(
                          padding: viewPadding.copyWith(
                              bottom: injectedBottomPadding),
                        ),
                        child: widget.bottomNavigationBar!,
                      ),
                    );
                  },
                ),

              // 4. Floating Action Button
              if (widget.floatingActionButton != null)
                Positioned(
                  right: 16,
                  bottom: (_bottomObstruction > 0
                          ? _bottomObstruction
                          : MediaQuery.paddingOf(context).bottom) +
                      16.0,
                  child: widget.floatingActionButton!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialScaffold(BuildContext context) {
    return Scaffold(
      key: widget.scaffoldKey,
      appBar: widget.appBar,
      // If expanding behind app bar (Liquid Glass), inject the toolbar height into padding
      // so children can use MediaQuery.padding.top to clear it if needed.
      body: widget.extendBodyBehindAppBar
          ? Builder(
              builder: (context) {
                final mediaQuery = MediaQuery.of(context);
                final topPadding = mediaQuery.padding.top + kToolbarHeight;

                return MediaQuery(
                  data: mediaQuery.copyWith(
                    padding: mediaQuery.padding.copyWith(top: topPadding),
                  ),
                  child: widget.body,
                );
              },
            )
          : widget.body,
      bottomNavigationBar: widget.bottomNavigationBar,
      backgroundColor: widget.backgroundColor,
      extendBodyBehindAppBar: widget.extendBodyBehindAppBar,
      floatingActionButton: widget.floatingActionButton,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
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
