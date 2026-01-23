import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Adaptive app wrapper that provides platform-appropriate theming.
///
/// Automatically uses CupertinoApp on iOS and MaterialApp on Android.
/// Supports both standard and router-based navigation.
class AdaptiveApp extends StatelessWidget {
  /// App title.
  final String title;

  /// Home widget (for standard navigation).
  final Widget? home;

  /// Initial route (for named routes).
  final String? initialRoute;

  /// Route generator (for named routes).
  final RouteFactory? onGenerateRoute;

  /// Routes map (for named routes).
  final Map<String, WidgetBuilder>? routes;

  /// Material theme data (Android).
  final ThemeData? materialTheme;

  /// Material dark theme data (Android).
  final ThemeData? materialDarkTheme;

  /// Cupertino theme data (iOS).
  final CupertinoThemeData? cupertinoTheme;

  /// Theme mode (light, dark, system).
  ///
  /// Defaults to [ThemeMode.system].
  final ThemeMode? themeMode;

  /// Localization delegates.
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;

  /// Supported locales.
  final Iterable<Locale> supportedLocales;

  /// Locale resolution callback.
  final LocaleResolutionCallback? localeResolutionCallback;

  /// Builder for wrapping the entire app.
  final TransitionBuilder? builder;

  /// Debug show checked mode banner.
  ///
  /// Defaults to true.
  final bool debugShowCheckedModeBanner;

  const AdaptiveApp({
    Key? key,
    required this.title,
    this.home,
    this.initialRoute,
    this.onGenerateRoute,
    this.routes,
    this.materialTheme,
    this.materialDarkTheme,
    this.cupertinoTheme,
    this.themeMode,
    this.localizationsDelegates,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.localeResolutionCallback,
    this.builder,
    this.debugShowCheckedModeBanner = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      home: home,
      initialRoute: initialRoute,
      onGenerateRoute: onGenerateRoute,
      routes: routes ?? const {},
      theme: materialTheme ??
          ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
      darkTheme: materialDarkTheme ??
          ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
          ),
      themeMode: themeMode ?? ThemeMode.system,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      localeResolutionCallback: localeResolutionCallback,
      builder: builder != null
          ? (context, child) {
              // Wrap with Cupertino theme for iOS widgets
              final wrappedChild = CupertinoTheme(
                data: cupertinoTheme ??
                    const CupertinoThemeData(
                      primaryColor: CupertinoColors.activeBlue,
                    ),
                child: child ?? const SizedBox.shrink(),
              );
              return builder!(context, wrappedChild);
            }
          : (context, child) => CupertinoTheme(
                data: cupertinoTheme ??
                    const CupertinoThemeData(
                      primaryColor: CupertinoColors.activeBlue,
                    ),
                child: child ?? const SizedBox.shrink(),
              ),
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
    );
  }
}

/// Adaptive app with router-based navigation.
///
/// Uses GoRouter or similar router packages.
class AdaptiveAppRouter extends StatelessWidget {
  /// App title.
  final String title;

  /// Router configuration.
  final RouterConfig<Object>? routerConfig;

  /// Material theme data (Android).
  final ThemeData? materialTheme;

  /// Material dark theme data (Android).
  final ThemeData? materialDarkTheme;

  /// Cupertino theme data (iOS).
  final CupertinoThemeData? cupertinoTheme;

  /// Theme mode (light, dark, system).
  ///
  /// Defaults to [ThemeMode.system].
  final ThemeMode? themeMode;

  /// Localization delegates.
  final Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates;

  /// Supported locales.
  final Iterable<Locale> supportedLocales;

  /// Locale resolution callback.
  final LocaleResolutionCallback? localeResolutionCallback;

  /// Builder for wrapping the entire app.
  final TransitionBuilder? builder;

  /// Debug show checked mode banner.
  ///
  /// Defaults to true.
  final bool debugShowCheckedModeBanner;

  const AdaptiveAppRouter({
    Key? key,
    required this.title,
    required this.routerConfig,
    this.materialTheme,
    this.materialDarkTheme,
    this.cupertinoTheme,
    this.themeMode,
    this.localizationsDelegates,
    this.supportedLocales = const <Locale>[Locale('en', 'US')],
    this.localeResolutionCallback,
    this.builder,
    this.debugShowCheckedModeBanner = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: title,
      routerConfig: routerConfig,
      theme: materialTheme ??
          ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
      darkTheme: materialDarkTheme ??
          ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
          ),
      themeMode: themeMode ?? ThemeMode.system,
      localizationsDelegates: localizationsDelegates,
      supportedLocales: supportedLocales,
      localeResolutionCallback: localeResolutionCallback,
      builder: builder != null
          ? (context, child) {
              final wrappedChild = CupertinoTheme(
                data: cupertinoTheme ??
                    const CupertinoThemeData(
                      primaryColor: CupertinoColors.activeBlue,
                    ),
                child: child ?? const SizedBox.shrink(),
              );
              return builder!(context, wrappedChild);
            }
          : (context, child) => CupertinoTheme(
                data: cupertinoTheme ??
                    const CupertinoThemeData(
                      primaryColor: CupertinoColors.activeBlue,
                    ),
                child: child ?? const SizedBox.shrink(),
              ),
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
    );
  }
}
