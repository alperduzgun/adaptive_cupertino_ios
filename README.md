# Adaptive Cupertino iOS

[![pub package](https://img.shields.io/pub/v/adaptive_cupertino_ios.svg)](https://pub.dev/packages/adaptive_cupertino_ios)

Native iOS Cupertino widgets with automatic platform adaptation. Provides iOS 18+ Liquid Glass TabBar/AppBar and iOS 26+ Glass Buttons with automatic fallback for older versions.

## Features by iOS Version

| iOS Version | Available Features |
|-------------|-------------------|
| **iOS 26+** | ✨ Native Glass Buttons (UIButton.Configuration.glass/prominentGlass) |
| **iOS 18+** | ✨ Native Liquid Glass TabBar & AppBar (UITabBar/UINavigationBar) |
| **iOS 10+** | 🎨 Runtime Badge Customization (color, value) |
| **iOS <18** | 🔄 Automatic Fallback (CupertinoTabBar/NavigationBar) |
| **All iOS** | 📱 Adaptive Platform Detection, Type-Safe API |

## Key Features

- ✨ **iOS 18+ Liquid Glass TabBar/AppBar**: Native UITabBar and UINavigationBar with Apple's Liquid Glass design
- 🎯 **iOS 26+ Glass Buttons**: Native glass/prominentGlass button styles with SF Symbols icon support
- 🔄 **Automatic Fallback**: Gracefully degrades to standard Cupertino widgets on older iOS versions
- 🎨 **Type-Safe API**: Clean, Flutter-idiomatic API with strong typing
- 📱 **Zero Configuration**: Automatic iOS version detection
- 🚀 **Production Ready**: Built on battle-tested implementations
- ♿ **Accessibility**: Respects system settings (reduce transparency, etc.)

## Supported Widgets

### Navigation & Layout

| Widget | iOS 18+ | iOS <18 | Android |
|--------|---------|---------|---------|
| `AdaptiveCupertinoTabBar` | Native UITabBar (Liquid Glass) | CupertinoTabBar | BottomNavigationBar |
| `AdaptiveCupertinoAppBar` | Native UINavigationBar (Liquid Glass) | CupertinoNavigationBar | AppBar |

### Controls

| Widget | iOS 26+ | iOS <26 | Android |
|--------|---------|---------|---------|
| `AdaptiveButton.glass()` | Native UIButton.Configuration.glass() | CupertinoButton | ElevatedButton |
| `AdaptiveButton.glassProminent()` | Native prominentGlass | CupertinoButton | ElevatedButton |

### App & Theme

| Widget | Description |
|--------|-------------|
| `AdaptiveApp` | Unified app wrapper with Material + Cupertino themes |
| `AdaptiveAppRouter` | Router-based navigation support |

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  adaptive_cupertino_ios: ^0.2.1
```

## Usage

### Quick Start with AdaptiveApp

```dart
import 'package:adaptive_cupertino_ios/adaptive_cupertino_ios.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveApp(
      title: 'My App',
      materialTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      cupertinoTheme: const CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
      ),
      home: const HomePage(),
    );
  }
}
```

### AdaptiveScaffold

```dart
AdaptiveScaffold(
  appBar: AdaptiveCupertinoAppBar(
    title: const Text('My App'),
  ),
  body: Center(
    child: Text('Hello World'),
  ),
  bottomNavigationBar: AdaptiveCupertinoTabBar(
    items: const [
      AdaptiveCupertinoTabItem(
        label: 'Home',
        icon: CupertinoIcons.house,
        selectedIcon: CupertinoIcons.house_fill,
      ),
    ],
    currentIndex: 0,
    onTap: (index) {},
  ),
)
```

### AdaptiveButton with Liquid Glass (iOS 26+)

```dart
// Standard button
AdaptiveButton(
  onPressed: () {},
  child: const Text('Save'),
)

// iOS 26+ Native Glass button
AdaptiveButton.glass(
  onPressed: () {},
  child: const Text('Glass Button'),
)

// iOS 26+ Prominent Glass button
AdaptiveButton.glassProminent(
  onPressed: () {},
  child: const Text('Prominent'),
)

// iOS 26+ Glass button with icon (SF Symbols)
AdaptiveButton.glass(
  icon: Icon(CupertinoIcons.heart_fill),
  iconPlacement: IconPlacement.leading,
  onPressed: () {},
  child: const Text('Like'),
)

// Icon placement variants
AdaptiveButton.glassProminent(
  icon: Icon(CupertinoIcons.arrow_right),
  iconPlacement: IconPlacement.trailing,  // leading, trailing, top, bottom
  onPressed: () {},
  child: const Text('Next'),
)
```

### TabBar Runtime Badge Management (iOS 10+)

```dart
// Get tab bar state reference
final GlobalKey<_AdaptiveCupertinoTabBarState> tabBarKey = GlobalKey();

AdaptiveCupertinoTabBar(
  key: tabBarKey,
  items: const [...],
  currentIndex: 0,
  onTap: (index) {},
)

// Update badge at runtime
await tabBarKey.currentState?.setBadge(2, '5');

// Clear badge
await tabBarKey.currentState?.clearBadge(2);

// Customize badge color (iOS 10+)
await tabBarKey.currentState?.setBadgeColor(2, '#FF0000');
```

### AdaptiveAlertDialog

```dart
// Show alert dialog
showAdaptiveAlertDialog(
  context: context,
  title: const Text('Confirm'),
  content: const Text('Are you sure?'),
  actions: [
    AdaptiveDialogAction(
      onPressed: () => Navigator.pop(context),
      child: const Text('Cancel'),
    ),
    AdaptiveDialogAction(
      onPressed: () => Navigator.pop(context),
      isDefaultAction: true,
      child: const Text('OK'),
    ),
  ],
);

// Simple confirmation dialog
final result = await showAdaptiveConfirmDialog(
  context: context,
  title: const Text('Delete'),
  content: const Text('Delete this item?'),
  isDestructive: true,
);
if (result == true) {
  // User confirmed
}
```

### TabBar

```dart
import 'package:adaptive_cupertino_ios/adaptive_cupertino_ios.dart';

AdaptiveCupertinoTabBar(
  items: const [
    AdaptiveCupertinoTabItem(
      label: 'Home',
      icon: CupertinoIcons.house,
      selectedIcon: CupertinoIcons.house_fill,
      badge: '3', // Optional badge
    ),
    AdaptiveCupertinoTabItem(
      label: 'Profile',
      icon: CupertinoIcons.person,
      selectedIcon: CupertinoIcons.person_fill,
    ),
  ],
  currentIndex: _selectedIndex,
  onTap: (index) {
    setState(() => _selectedIndex = index);
  },
)
```

### AppBar

```dart
AdaptiveCupertinoAppBar(
  title: const Text('My App'),
  largeTitle: true, // iOS 11+ large title
  leading: CupertinoButton(
    child: const Icon(CupertinoIcons.back),
    onPressed: () => Navigator.pop(context),
  ),
  trailing: [
    CupertinoButton(
      child: const Icon(CupertinoIcons.add),
      onPressed: () {},
    ),
  ],
)
```

### Complete Example

```dart
import 'package:flutter/cupertino.dart';
import 'package:adaptive_cupertino_ios/adaptive_cupertino_ios.dart';

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Column(
        children: [
          // AppBar
          AdaptiveCupertinoAppBar(
            title: const Text('My App'),
            trailing: [
              CupertinoButton(
                child: const Icon(CupertinoIcons.settings),
                onPressed: () {},
              ),
            ],
          ),

          // Content
          Expanded(
            child: Center(
              child: Text('Tab $_selectedIndex'),
            ),
          ),

          // TabBar
          AdaptiveCupertinoTabBar(
            items: const [
              AdaptiveCupertinoTabItem(
                label: 'Home',
                icon: CupertinoIcons.house,
                selectedIcon: CupertinoIcons.house_fill,
              ),
              AdaptiveCupertinoTabItem(
                label: 'Search',
                icon: CupertinoIcons.search,
              ),
              AdaptiveCupertinoTabItem(
                label: 'Profile',
                icon: CupertinoIcons.person,
                selectedIcon: CupertinoIcons.person_fill,
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
          ),
        ],
      ),
    );
  }
}
```

## How It Works

The package automatically detects the iOS version and uses the appropriate implementation:

### iOS 18+
- Uses native `UITabBar` and `UINavigationBar`
- Applies Apple's Liquid Glass design language
- Includes `.systemChromeMaterial` blur effects
- Respects system accessibility settings

### iOS <18
- Falls back to standard `CupertinoTabBar` and `CupertinoNavigationBar`
- Maintains consistent API
- No code changes required

## API Reference

### AdaptiveCupertinoTabBar

| Property | Type | Description |
|----------|------|-------------|
| `items` | `List<AdaptiveCupertinoTabItem>` | Tab items to display |
| `currentIndex` | `int` | Currently selected index |
| `onTap` | `ValueChanged<int>?` | Callback when tab is tapped |
| `backgroundColor` | `Color?` | Background color (fallback mode only) |
| `activeColor` | `Color?` | Active item color (fallback mode only) |
| `inactiveColor` | `Color?` | Inactive item color (fallback mode only) |

### AdaptiveCupertinoTabItem

| Property | Type | Description |
|----------|------|-------------|
| `label` | `String` | Tab label |
| `icon` | `IconData` | Icon (SF Symbol) |
| `selectedIcon` | `IconData?` | Selected state icon (optional) |
| `badge` | `String?` | Badge text (optional) |

### AdaptiveCupertinoAppBar

| Property | Type | Description |
|----------|------|-------------|
| `title` | `Widget?` | Title widget |
| `leading` | `Widget?` | Leading widget (typically back button) |
| `trailing` | `List<Widget>?` | Trailing action buttons |
| `largeTitle` | `bool` | Use large title on iOS 11+ |
| `backgroundColor` | `Color?` | Background color (fallback mode only) |
| `border` | `Border?` | Border (fallback mode only) |
| `automaticallyImplyLeading` | `bool` | Auto add back button (fallback mode) |

## Platform Requirements

- **iOS**: 15.0+
- **Flutter**: 3.10.0+
- **Dart**: 3.0.0+

## Comparison with Other Packages

| Feature | adaptive_cupertino_ios | adaptive_platform_ui |
|---------|----------------------|---------------------|
| iOS 18+ Liquid Glass | ✅ Native | ❌ |
| Auto version detection | ✅ | ✅ |
| Follows Apple guidelines | ✅ | ⚠️ |
| Type-safe API | ✅ | ⚠️ |
| Production ready | ✅ | ⚠️ |
| Pure iOS focus | ✅ | ❌ Multi-platform |

## Roadmap

### v0.2.0 (Planned)
- Tab bar minimize behavior (scroll-based)
- AppBar scroll edge effects
- Badge customization (color, position)

### v0.3.0 (Planned)
- `AdaptiveCupertinoButton` (Liquid Glass button styles)
- `AdaptiveCupertinoSheet` (Modal sheets)

### v1.0.0 (Future)
- Complete Cupertino widget suite
- Theme system extensions

## Contributing

Contributions are welcome! Please read our contributing guidelines.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Credits

Built with ❤️ following [Apple's Liquid Glass Design Guidelines](https://developer.apple.com/design/).

Based on research from:
- Apple Developer Documentation
- WWDC 2024 Sessions
- Community feedback

## Support

- 🐛 [Report bugs](https://github.com/alper/adaptive_cupertino_ios/issues)
- 💡 [Request features](https://github.com/alper/adaptive_cupertino_ios/issues)
- 📖 [Documentation](https://pub.dev/documentation/adaptive_cupertino_ios)
- 💻 [Source Code](https://github.com/alper/adaptive_cupertino_ios)

---

Made with Flutter 💙
