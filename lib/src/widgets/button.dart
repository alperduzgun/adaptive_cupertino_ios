import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../platform/ios_version.dart';
import 'popup_menu.dart'; // For definition

/// Button style for Adaptive buttons.
enum AdaptiveButtonStyle {
  /// Standard filled button.
  filled,

  /// Text-only button (no background).
  text,

  /// Outlined button with border.
  outlined,

  /// iOS 26+ Liquid Glass style (uses native UIButton.Configuration.glass()).
  ///
  /// Falls back to [filled] on older iOS versions.
  /// **Uses native iOS platform view for true Liquid Glass effect.**
  glass,

  /// iOS 26+ Prominent Liquid Glass style (uses native UIButton.Configuration.prominentGlass()).
  ///
  /// Falls back to [filled] on older iOS versions.
  /// **Uses native iOS platform view for true Liquid Glass effect.**
  glassProminent,

  /// iOS 26+ Tinted Liquid Glass style (uses native UIButton.Configuration.glass() with tint).
  ///
  /// Falls back to [filled] on older iOS versions.
  /// **Uses native iOS platform view for true Liquid Glass effect.**
  glassTinted,

  /// iOS 26+ Clear Liquid Glass style (uses native UIButton.Configuration.glass() with .clear variant).
  ///
  /// Falls back to [filled] on older iOS versions.
  /// **Uses native iOS platform view for true Liquid Glass effect.**
  glassClear,

  /// iOS 26+ Identity Liquid Glass style (uses native UIButton.Configuration.glass() with .identity variant).
  ///
  /// Falls back to [filled] on older iOS versions.
  /// **Uses native iOS platform view for true Liquid Glass effect.**
  glassIdentity,
}

/// Icon placement for buttons (iOS 26+).
enum IconPlacement {
  /// Icon appears before text (left in LTR, right in RTL).
  leading,

  /// Icon appears after text (right in LTR, left in RTL).
  trailing,

  /// Icon appears above text.
  top,

  /// Icon appears below text.
  bottom,
}

/// Adaptive button that provides platform-appropriate styling.
///
/// ## iOS 26+ Glass Buttons
/// On iOS 26+, glass button styles use **native UIButton with UIButton.Configuration.glass()**.
/// This provides the authentic Liquid Glass appearance with:
/// - Native blur effects
/// - System-provided visual treatment
/// - Proper accessibility support
/// - Automatic light/dark mode adaptation
///
/// ## iOS <26
/// Falls back to standard CupertinoButton with custom styling.
///
/// ## Android
/// Uses Material Design buttons (ElevatedButton, TextButton, etc.).
///
/// ## Example
/// ```dart
/// // iOS 26+ gets native glass button
/// AdaptiveButton.glass(
///   child: Text('Action'),
///   onPressed: () => print('Pressed'),
/// )
///
/// // With icon
/// AdaptiveButton.glassProminent(
///   child: Text('Delete'),
///   icon: Icon(Icons.delete),
///   onPressed: () => print('Delete'),
/// )
/// ```
class AdaptiveButton extends StatefulWidget {
  /// The button's label.
  final Widget child;

  /// Callback when button is pressed.
  final VoidCallback? onPressed;

  /// Button style.
  ///
  /// Defaults to [AdaptiveButtonStyle.filled].
  final AdaptiveButtonStyle style;

  /// Button icon (optional).
  ///
  /// **Native glass buttons (iOS 26+):** Supports SF Symbols via [IconData].
  /// Use [CupertinoIcons] for native iOS icons.
  ///
  /// Example:
  /// ```dart
  /// AdaptiveButton.glass(
  ///   icon: Icon(CupertinoIcons.heart_fill),
  ///   child: Text('Like'),
  ///   onPressed: () {},
  /// )
  /// ```
  final Widget? icon;

  /// Icon placement relative to text (iOS 26+ only).
  ///
  /// Options: [IconPlacement.leading], [trailing], [top], [bottom].
  /// Defaults to [leading].
  final IconPlacement iconPlacement;

  /// Button color (overrides default theme color).
  ///
  /// For [glassTinted], this sets the tint color.
  final Color? color;

  /// Text color.
  final Color? foregroundColor;

  /// Padding inside the button.
  final EdgeInsetsGeometry? padding;

  /// Minimum button size.
  final Size? minimumSize;

  /// Border radius (for filled/outlined styles).
  final BorderRadius? borderRadius;

  /// Unique identifier for Liquid Morphing (iOS 26+).
  ///
  /// If provided, this button can morph into/from other elements (like sheets)
  /// with the same [glassEffectID].
  final String? glassEffectID;

  /// Optional actions for a pull-down menu (iOS 14+).
  ///
  /// If provided, long-pressing (or tapping, depending on OS) will show a native menu.
  final List<AdaptivePopupMenuItem>? menuActions;

  /// Callback when a menu item is selected (native only).
  final ValueChanged<dynamic>? onMenuSelected;

  const AdaptiveButton({
    Key? key,
    required this.child,
    required this.onPressed,
    this.style = AdaptiveButtonStyle.filled,
    this.icon,
    this.iconPlacement = IconPlacement.leading,
    this.color,
    this.foregroundColor,
    this.padding,
    this.minimumSize,
    this.borderRadius,
    this.glassEffectID,
    this.menuActions,
    this.onMenuSelected,
  }) : super(key: key);

  /// Convenience constructor for text button.
  const AdaptiveButton.text({
    Key? key,
    required Widget child,
    required VoidCallback? onPressed,
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
  }) : this(
          key: key,
          child: child,
          onPressed: onPressed,
          style: AdaptiveButtonStyle.text,
          foregroundColor: foregroundColor,
          padding: padding,
        );

  /// Convenience constructor for icon button.
  const AdaptiveButton.icon({
    Key? key,
    required Widget icon,
    required Widget label,
    required VoidCallback? onPressed,
    AdaptiveButtonStyle style = AdaptiveButtonStyle.filled,
    Color? color,
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
  }) : this(
          key: key,
          icon: icon,
          child: label,
          onPressed: onPressed,
          style: style,
          color: color,
          foregroundColor: foregroundColor,
          padding: padding,
        );

  /// Convenience constructor for Liquid Glass button (iOS 26+).
  ///
  /// **Uses native iOS UIButton.Configuration.glass()** on iOS 26+.
  const AdaptiveButton.glass({
    Key? key,
    required Widget child,
    required VoidCallback? onPressed,
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
    String? glassEffectID,
  }) : this(
          key: key,
          child: child,
          onPressed: onPressed,
          style: AdaptiveButtonStyle.glass,
          foregroundColor: foregroundColor,
          padding: padding,
          glassEffectID: glassEffectID,
        );

  /// Convenience constructor for Prominent Liquid Glass button (iOS 26+).
  ///
  /// **Uses native iOS UIButton.Configuration.prominentGlass()** on iOS 26+.
  const AdaptiveButton.glassProminent({
    Key? key,
    required Widget child,
    required VoidCallback? onPressed,
    Color? color,
    Color? foregroundColor,
    EdgeInsetsGeometry? padding,
    String? glassEffectID,
  }) : this(
          key: key,
          child: child,
          onPressed: onPressed,
          style: AdaptiveButtonStyle.glassProminent,
          color: color,
          foregroundColor: foregroundColor,
          padding: padding,
          glassEffectID: glassEffectID,
        );

  /// Convenience constructor for Tinted Liquid Glass button (iOS 26+).
  ///
  /// **Uses native iOS UIButton.Configuration.glass()** with tint color on iOS 26+.
  const AdaptiveButton.glassTinted({
    Key? key,
    required Widget child,
    required VoidCallback? onPressed,
    required Color tintColor,
    EdgeInsetsGeometry? padding,
    String? glassEffectID,
  }) : this(
          key: key,
          child: child,
          onPressed: onPressed,
          style: AdaptiveButtonStyle.glassTinted,
          color: tintColor,
          padding: padding,
          glassEffectID: glassEffectID,
        );

  /// Convenience constructor for Clear Liquid Glass button (iOS 26+).
  ///
  /// **Uses native iOS UIButton.Configuration.glass()** with .clear variant on iOS 26+
  const AdaptiveButton.glassClear({
    Key? key,
    required Widget child,
    required VoidCallback? onPressed,
    String? glassEffectID,
  }) : this(
          key: key,
          child: child,
          onPressed: onPressed,
          style: AdaptiveButtonStyle.glassClear,
          glassEffectID: glassEffectID,
        );

  /// Convenience constructor for Identity Liquid Glass button (iOS 26+).
  ///
  /// **Uses native iOS UIButton.Configuration.glass()** with .identity variant on iOS 26+
  const AdaptiveButton.glassIdentity({
    Key? key,
    required Widget child,
    required VoidCallback? onPressed,
    String? glassEffectID,
  }) : this(
          key: key,
          child: child,
          onPressed: onPressed,
          style: AdaptiveButtonStyle.glassIdentity,
          glassEffectID: glassEffectID,
        );

  @override
  State<AdaptiveButton> createState() => _AdaptiveButtonState();
}

class _AdaptiveButtonState extends State<AdaptiveButton> {
  bool _supportsLiquidGlass = false;
  bool _isCheckingVersion = false;

  @override
  void initState() {
    super.initState();
    if (_requiresNativeGlassButton()) {
      _checkLiquidGlassSupport();
    }
  }

  bool _requiresNativeGlassButton() {
    // Fail Safe: Only use native view if child is simple Text.
    // Complex children (Rows, Columns, Loaders) cannot be rendered by the native factory.
    final bool isSimpleContent = widget.child is Text;
    return Platform.isIOS &&
        isSimpleContent &&
        (widget.style == AdaptiveButtonStyle.glass ||
            widget.style == AdaptiveButtonStyle.glassProminent ||
            widget.style == AdaptiveButtonStyle.glassTinted ||
            widget.style == AdaptiveButtonStyle.glassClear ||
            widget.style == AdaptiveButtonStyle.glassIdentity);
  }

  Future<void> _checkLiquidGlassSupport() async {
    if (!Platform.isIOS) {
      setState(() => _supportsLiquidGlass = false);
      return;
    }

    setState(() => _isCheckingVersion = true);

    try {
      final supports = await IOSVersion().supportsNativeUI();
      if (mounted) {
        setState(() {
          _supportsLiquidGlass = supports;
          _isCheckingVersion = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _supportsLiquidGlass = false;
          _isCheckingVersion = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;

    // Check if we need native glass button
    if (_requiresNativeGlassButton()) {
      if (_isCheckingVersion) {
        // Show placeholder while checking
        return const SizedBox(
          width: 120,
          height: 44,
          child: Center(child: CupertinoActivityIndicator()),
        );
      }

      if (_supportsLiquidGlass) {
        // Use native glass button on iOS 26+
        return _buildNativeGlassButton();
      }

      // Fallback to standard button on iOS <26
      return _buildIOSButton(context, useFallbackStyle: true);
    }

    if (platform == TargetPlatform.iOS) {
      return _buildIOSButton(context, useFallbackStyle: false);
    }

    return _buildMaterialButton(context);
  }

  /// Build native iOS glass button using platform view
  Widget _buildNativeGlassButton() {
    // Extract title from Text widget if possible
    String title = 'Button';
    if (widget.child is Text) {
      final textWidget = widget.child as Text;
      title = textWidget.data ?? '';
    }

    // Extract icon from Icon widget if possible
    String? iconName;
    if (widget.icon is Icon) {
      final iconWidget = widget.icon as Icon;
      iconName = _iconDataToSFSymbol(iconWidget.icon);
    }

    final styleString = _getGlassStyleString();
    final tintColorHex =
        widget.color != null ? _colorToHex(widget.color!) : null;
    final iconPlacementString = _getIconPlacementString();

    // CHAOS SAFETY: Prevent NaN from breaking platform view frame
    var minSize = widget.minimumSize ?? const Size(100, 44);
    if (minSize.width.isNaN || minSize.width.isInfinite) {
      minSize = Size(100, minSize.height);
    }
    if (minSize.height.isNaN || minSize.height.isInfinite) {
      minSize = Size(minSize.width, 44);
    }

    return SizedBox(
      width: minSize.width,
      height: minSize.height,
      child: _NativeGlassButton(
        title: title,
        style: styleString,
        enabled: widget.onPressed != null,
        tintColor: tintColorHex,
        icon: iconName,
        iconPlacement: iconPlacementString,
        glassEffectID: widget.glassEffectID,
        menuActions: widget.menuActions,
        onMenuSelected: widget.onMenuSelected,
        onPressed: widget.onPressed,
      ),
    );
  }

  String? _iconDataToSFSymbol(IconData? iconData) {
    if (iconData == null) return null;

    // Common CupertinoIcons to SF Symbols mapping
    const Map<int, String> iconMap = {
      0xf34b: 'doc.text',
      0xf47d: 'doc.text.fill',
      0xf4e2: 'sparkles',
      0xf37c: 'square.grid.2x2',
      0xf37d: 'square.grid.2x2.fill',
      0xf419: 'person.circle',
      0xf41a: 'person.circle.fill',
      0xf106: 'house',
      0xf107: 'house.fill',
      0xf10b: 'heart',
      0xf10c: 'heart.fill',
      0xf35e: 'gear',
      0xf4b9: 'plus',
      0xf4c1: 'minus',
    };

    return iconMap[iconData.codePoint] ?? 'circle';
  }

  String _getIconPlacementString() {
    switch (widget.iconPlacement) {
      case IconPlacement.leading:
        return 'leading';
      case IconPlacement.trailing:
        return 'trailing';
      case IconPlacement.top:
        return 'top';
      case IconPlacement.bottom:
        return 'bottom';
    }
  }

  String _getGlassStyleString() {
    switch (widget.style) {
      case AdaptiveButtonStyle.glass:
        return 'glass';
      case AdaptiveButtonStyle.glassProminent:
        return 'glassProminent';
      case AdaptiveButtonStyle.glassClear:
        return 'glassClear';
      case AdaptiveButtonStyle.glassIdentity:
        return 'glassIdentity';
      case AdaptiveButtonStyle.glassTinted:
        return 'glassTinted';
      default:
        return 'glass';
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
  }

  Widget _buildIOSButton(BuildContext context,
      {required bool useFallbackStyle}) {
    // Determine actual style (fallback for glass styles on iOS <26)
    AdaptiveButtonStyle actualStyle = widget.style;
    if (useFallbackStyle &&
        (widget.style == AdaptiveButtonStyle.glass ||
            widget.style == AdaptiveButtonStyle.glassProminent ||
            widget.style == AdaptiveButtonStyle.glassTinted ||
            widget.style == AdaptiveButtonStyle.glassClear ||
            widget.style == AdaptiveButtonStyle.glassIdentity)) {
      actualStyle = AdaptiveButtonStyle.filled;
    }

    final buttonContent = widget.icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.icon!,
              const SizedBox(width: 8),
              widget.child,
            ],
          )
        : widget.child;

    switch (actualStyle) {
      case AdaptiveButtonStyle.text:
        return CupertinoButton(
          onPressed: widget.onPressed,
          padding: widget.padding,
          color: null,
          child: DefaultTextStyle(
            style: TextStyle(
              color: widget.foregroundColor ?? CupertinoColors.activeBlue,
            ),
            child: buttonContent,
          ),
        );
      case AdaptiveButtonStyle.outlined:
        return CupertinoButton(
          onPressed: widget.onPressed,
          padding: widget.padding ?? const EdgeInsets.all(12),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          color: null,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: widget.color ?? CupertinoColors.activeBlue,
                width: 1.5,
              ),
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            ),
            padding: widget.padding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DefaultTextStyle(
              style: TextStyle(
                color: widget.foregroundColor ??
                    widget.color ??
                    CupertinoColors.activeBlue,
              ),
              child: buttonContent,
            ),
          ),
        );
      case AdaptiveButtonStyle.filled:
      default:
        return CupertinoButton(
          onPressed: widget.onPressed,
          padding: widget.padding,
          color: widget.color ?? CupertinoColors.activeBlue,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          child: SizedBox(
            height: widget.minimumSize?.height ?? 44,
            child: DefaultTextStyle(
              style: TextStyle(
                color: widget.foregroundColor ?? CupertinoColors.white,
              ),
              child: buttonContent,
            ),
          ),
        );
    }
  }

  Widget _buildMaterialButton(BuildContext context) {
    final buttonContent = widget.icon != null
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.icon!,
              const SizedBox(width: 8),
              widget.child,
            ],
          )
        : widget.child;

    switch (widget.style) {
      case AdaptiveButtonStyle.text:
        return TextButton(
          onPressed: widget.onPressed,
          style: TextButton.styleFrom(
            foregroundColor: widget.foregroundColor,
            padding: widget.padding,
            minimumSize: widget.minimumSize,
          ),
          child: buttonContent,
        );
      case AdaptiveButtonStyle.outlined:
        return OutlinedButton(
          onPressed: widget.onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: widget.foregroundColor,
            backgroundColor: widget.color,
            padding: widget.padding,
            minimumSize: widget.minimumSize,
          ),
          child: buttonContent,
        );
      case AdaptiveButtonStyle.glass:
      case AdaptiveButtonStyle.glassProminent:
      case AdaptiveButtonStyle.glassTinted:
      case AdaptiveButtonStyle.glassClear:
      case AdaptiveButtonStyle.glassIdentity:
      case AdaptiveButtonStyle.filled:
        return ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            foregroundColor: widget.foregroundColor,
            backgroundColor: widget.color,
            padding: widget.padding,
            minimumSize: widget.minimumSize,
          ),
          child: buttonContent,
        );
    }
  }
}

/// Internal widget for native iOS glass button platform view
class _NativeGlassButton extends StatefulWidget {
  final String title;
  final String style;
  final bool enabled;
  final String? tintColor;
  final String? icon;
  final String iconPlacement;
  final String? glassEffectID;
  final List<AdaptivePopupMenuItem>? menuActions;
  final ValueChanged<dynamic>? onMenuSelected;
  final VoidCallback? onPressed;

  const _NativeGlassButton({
    required this.title,
    required this.style,
    required this.enabled,
    this.tintColor,
    this.icon,
    this.iconPlacement = 'leading',
    this.glassEffectID,
    this.menuActions,
    this.onMenuSelected,
    this.onPressed,
  });

  @override
  State<_NativeGlassButton> createState() => _NativeGlassButtonState();
}

class _NativeGlassButtonState extends State<_NativeGlassButton> {
  MethodChannel? _buttonChannel;

  void _setupPlatformChannel(int viewId) {
    _buttonChannel =
        MethodChannel('adaptive_cupertino_ios/glass_button_$viewId');
    _buttonChannel!.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onPressed':
        widget.onPressed?.call();
        break;
      case 'onMenuAction':
        final index = call.arguments['index'] as int;
        if (widget.menuActions != null && index < widget.menuActions!.length) {
          final value = widget.menuActions![index].value;
          widget.onMenuSelected?.call(value);
        }
        break;
    }
  }

  @override
  void didUpdateWidget(_NativeGlassButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update button state if needed
    if (widget.enabled != oldWidget.enabled) {
      _buttonChannel?.invokeMethod('setEnabled', {'enabled': widget.enabled});
    }

    if (widget.title != oldWidget.title) {
      _buttonChannel?.invokeMethod('setTitle', {'title': widget.title});
    }
  }

  @override
  Widget build(BuildContext context) {
    // Serialize menu actions if present
    List<Map<String, dynamic>>? serializedMenuActions;
    if (widget.menuActions != null) {
      serializedMenuActions = widget.menuActions!.map((action) {
        String label = 'Action';
        if (action.child is Text) {
          label = (action.child as Text).data ?? 'Action';
        }
        return {
          'label': label,
          'isDestructive': action.isDestructive,
          // We might want to support icons in menu items too, but AdaptivePopupMenuItem doesn't explicitly have it in the separate file definition yet.
          // Let's assume for now we just use text.
        };
      }).toList();
    }

    return UiKitView(
      viewType: 'adaptive_cupertino_ios/button',
      creationParams: {
        'title': widget.title,
        'style': widget.style,
        'enabled': widget.enabled,
        if (widget.tintColor != null) 'tintColor': widget.tintColor,
        if (widget.icon != null) 'icon': widget.icon,
        'iconPlacement': widget.iconPlacement,
        if (widget.glassEffectID != null) 'glassEffectID': widget.glassEffectID,
        if (serializedMenuActions != null) 'menuActions': serializedMenuActions,
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _setupPlatformChannel,
    );
  }

  @override
  void dispose() {
    _buttonChannel?.setMethodCallHandler(null);
    super.dispose();
  }
}
