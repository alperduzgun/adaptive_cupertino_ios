# Adaptive Cupertino iOS

[![pub package](https://img.shields.io/pub/v/adaptive_cupertino_ios.svg)](https://pub.dev/packages/adaptive_cupertino_ios)

A high-performance Flutter library providing native iOS system widgets with automatic platform adaptation. It specializes in implementing Apple's "Liquid Glass" design language for iOS 18+ and the "Quartz/Glass" aesthetic for iOS 26+, featuring advanced native visual effects and seamless fallback for legacy environments.

## Feature Compatibility Matrix

| iOS Version | Architectural Support | Key Subsystems |
|-------------|----------------------|----------------|
| **iOS 26+** | Advanced Quartz Design | Native Glass Buttons (prominentGlass/glass), Dynamic Spacers |
| **iOS 18+** | Liquid Glass Architecture | Native UITabBar & UINavigationBar with Gradient Blur |
| **iOS 10+** | Legacy Support | Runtime Badge Management, Adaptive UI Transitions |
| **Cross-Platform**| Material Materialization | Automatic Android/Web Fallback to Design-System Standards |

## Core Competencies

*   **Native Liquid Glass Implementation**: Leverages native `UITabBar` and `UINavigationBar` APIs for authentic iOS 18+ aesthetics.
*   **Quartz Visual Engine**: Native iOS 26+ UIButton configurations including `glass` and `prominentGlass` styles.
*   **Intelligent Platform Adaptation**: Automatic architectural detection ensures optimal performance and visual fidelity across all OS versions.
*   **Type-Safe Architectural Design**: Built with a clean, strongly-typed API tailored for Flutter developers.
*   **Accessibility Excellence**: Full compliance with system-level accessibility settings, including reduced transparency and dynamic type.

## Supported Components

### Navigation Framework

| Component | iOS 18+ Core | Legacy iOS | Android/Material |
|-----------|--------------|------------|------------------|
| `AdaptiveCupertinoTabBar` | Native UITabBar (Liquid Glass) | CupertinoTabBar | BottomNavigationBar |
| `AdaptiveCupertinoAppBar` | Native UINavigationBar (Liquid Glass) | CupertinoNavigationBar | AppBar |

### Native Controls

| Component | iOS 26+ Standard | Legacy iOS | Android/Material |
|-----------|-----------------|------------|------------------|
| `AdaptiveButton.glass()` | Native glass configuration | CupertinoButton | ElevatedButton |
| `AdaptiveButton.glassProminent()` | Native prominentGlass | CupertinoButton | ElevatedButton |

| `AdaptiveSegmentedControl` | Native UISegmentedControl (Liquid Glass) | CupertinoSegmentedControl | Material SegmentedButton |
| `AdaptiveSwitch` | Native UISwitch (Liquid Glass) | CupertinoSwitch | Switch.adaptive |
| `AdaptiveSlider` | Native UISlider (Liquid Glass) | CupertinoSlider | Slider.adaptive |

### System Integration

| Feature | Description |
|---------|-------------|
| `AdaptiveApp` | Centralized application wrapper for unified theme management |
| `AdaptiveAppRouter` | First-class routing support with platform-specific transitions |

## Installation

Add the following dependency to your `pubspec.yaml`:

```yaml
dependencies:
  adaptive_cupertino_ios: ^0.2.1
```

## Implementation Guide

### Initial Setup

```dart
import 'package:adaptive_cupertino_ios/adaptive_cupertino_ios.dart';

class SystemRoot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdaptiveApp(
      title: 'Enterprise Solution',
      cupertinoTheme: const CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
      ),
      home: const Dashboard(),
    );
  }
}
```

### Advanced Scaffold Layout

```dart
AdaptiveScaffold(
  appBar: AdaptiveCupertinoAppBar(
    title: const Text('Architecture Overview'),
  ),
  bottomNavigationBar: AdaptiveCupertinoTabBar(
    items: const [
      AdaptiveCupertinoTabItem(
        label: 'Workspace',
        icon: CupertinoIcons.house_fill,
      ),
    ],
    currentIndex: 0,
    onTap: (index) => _handleNavigation(index),
    minimizationFactor: _scrollOffset, // 0.0 to 1.0 for dynamic TabBar sizing
  ),
  body: const RepositoryStream(),
)
```

### Dynamic TabBar Minimization

The `minimizationFactor` property enables scroll-aware TabBar transformations:

```dart
// In your scroll listener:
void _onScroll() {
  final factor = (scrollController.position.pixels / 200.0).clamp(0.0, 1.0);
  setState(() => _minimizationFactor = factor);
}

// Apply to TabBar:
AdaptiveCupertinoTabBar(
  items: items,
  currentIndex: index,
  minimizationFactor: _minimizationFactor,
)
```

> **Note:** The TabBar automatically handles timing edge cases where Flutter calls native code before iOS completes layout. A retry mechanism with observability logging ensures reliable initialization.

### Native Button Configurations

```dart
// Native iOS 26 Glass Configuration
AdaptiveButton.glass(
  onPressed: _executeTask,
  child: const Text('Execute System Command'),
)

// High-visibility prominent configuration
AdaptiveButton.glassProminent(
  icon: Icon(CupertinoIcons.shield_fill),
  onPressed: _rebootSystem,
  child: const Text('Authorize Transition'),
)
```

### Adaptive Controls

```dart
// Adaptive Switch (Native iOS 26 Liquid Glass)
AdaptiveSwitch(
  value: _isEnabled,
  onChanged: (val) => setState(() => _isEnabled = val),
)

// Adaptive Segmented Control
AdaptiveSegmentedControl<int>(
  values: const [0, 1, 2],
  labels: const ['Day', 'Week', 'Month'],
  selectedValue: _selectedIndex,
  onValueChanged: (index) => _updateView(index),
)

// Adaptive Slider
AdaptiveSlider(
  value: _value,
  onChanged: (val) => setState(() => _value = val),
  activeColor: CupertinoColors.activeBlue,
)
```

## Technical Specifications

### iOS Architecture
The library utilizes a hybrid Flutter-Native bridge to ensure pixel-perfect rendering:
- **iOS 18+ Integration**: Hooks into native `standardAppearance` and `scrollEdgeAppearance` protocols.
- **Visual Effects**: Implements `.systemChromeMaterial` blur through native `UIVisualEffectView` layers.
- **Context Awareness**: Automatically adjusts contrast and levels based on system brightness and accessibility overrides.

### System Requirements
- **iOS Deployment Target**: 15.0 or higher
- **Flutter SDK**: 3.10.0 or higher
- **Dart SDK**: 3.0.0 or higher

## Development Roadmap

### Version 0.4.0 (Current)
- [x] **Native iOS 26 Controls**: Native-backed `AdaptiveSegmentedControl` component.
- [x] **Native iOS 26 Controls**: Native-backed `AdaptiveSwitch`.
- [x] **Native iOS 26 Controls**: Native-backed `AdaptiveSlider` component.
- [x] **Dynamic Structural Minimization**: Native scroll-aware TabBar transformations with `minimizationFactor` property.
- [ ] **Native Contextual Search**: Implementation of iOS 26+ native search tab transitions.
- [ ] **Flexible Layout Spacers**: Enhanced horizontal distribution API for complex toolbar requirements.
- [ ] **Adaptive Elevation**: Automatic depth/shadow management for Liquid Glass layers.
- [ ] **Immersive View Controllers**: Support for Liquid Glass modal presentations and sheet interactions.
- [ ] **Enhanced Transitions**: Native cross-page Hero animations for glass elements.

### Version 1.0.0 (Long-term)
- [ ] **Architectural Completion**: Complete UIKit suite with native iOS 26+ design language.
- [ ] **Knowledge Base**: Comprehensive documentation and interactive examples.
- [ ] **Advanced Aesthetic Engine**: System extensions for custom glass aesthetics and blur physics.

## Support & Contributions

Technical inquiries and issue reports should be directed to the [Official Issue Tracker](https://github.com/alper/adaptive_cupertino_ios/issues). Contributions providing architectural improvements or feature expansions are reviewed in accordance with established code quality standards.

---

**Adaptive Cupertino iOS** | Engineered for High-Fidelity Professional Applications
