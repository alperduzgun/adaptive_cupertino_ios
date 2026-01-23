# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - 2024-01-21

### Added
- **TabBar Runtime Badge Management** (iOS 10+)
  - `setBadge(index, badge)` - Update badge at runtime
  - `clearBadge(index)` - Remove badge
  - `setBadgeColor(index, color)` - Customize badge color
- **Button Icon Support** (iOS 26+)
  - SF Symbols icon support via `IconData`
  - `IconPlacement` enum (leading, trailing, top, bottom)
  - Icon + text combinations with configurable placement
  - Fallback icon support for iOS <26

### Improved
- Better title text extraction in `AdaptiveCupertinoAppBar`
- Improved documentation with iOS version clarity
- Fixed UIColor extension duplication

### Fixed
- Removed duplicate `UIColor+Hex` extension causing compiler errors
- Fixed version inconsistencies in documentation

## [0.2.0] - 2024-01-21 (Phase 1 Complete)

### Added
- **AdaptiveButton** - Platform-aware button with iOS 26+ Liquid Glass styles
  - `.glass` style (iOS 26+ native UIButton.Configuration.glass())
  - `.glassProminent` style (iOS 26+ prominentGlass)
  - `.glassTinted` style with custom tint colors
  - `.filled`, `.text`, `.outlined` styles for all platforms
- Enhanced iOS version detection system
- Comprehensive usage examples

### Improved
- Better type-safe API
- Proper fallback for iOS <26

## [0.1.0] - 2024-01-21

### Added
- Initial release
- `AdaptiveCupertinoTabBar` widget with iOS 18+ Liquid Glass support
- `AdaptiveCupertinoAppBar` widget with native UINavigationBar
- Automatic iOS version detection
- Graceful fallback to standard Cupertino widgets on iOS <18
- Comprehensive example app
- Full API documentation

### Features
- Native UITabBar with Liquid Glass blur on iOS 18+
- Native UINavigationBar with large title support
- Badge support for tab items
- Type-safe Dart API
- Zero-configuration setup
- Accessibility support

[0.2.0]: https://github.com/yourusername/adaptive_cupertino_ios/releases/tag/v0.2.0
[0.1.0]: https://github.com/yourusername/adaptive_cupertino_ios/releases/tag/v0.1.0
