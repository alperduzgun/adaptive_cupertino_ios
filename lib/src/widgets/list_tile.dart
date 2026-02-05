import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'badge.dart'; // For AdaptiveBadge detection
import 'menu.dart'; // For AdaptiveContextMenuItem
import 'switch.dart'; // For AdaptiveSwitch detection

/// An adaptive list tile that provides platform-appropriate styling.
///
/// Uses [CupertinoListTile] on iOS and Material [ListTile] on Android.
class AdaptiveListTile extends StatelessWidget {
  /// Leading widget (e.g., Icon).
  final Widget? leading;

  /// Title widget (usually Text).
  final Widget title;

  /// Subtitle widget.
  final Widget? subtitle;

  /// Trailing widget.
  final Widget? trailing;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Whether to use glass effect backing.
  final bool useGlass;

  /// Native Context Menu Actions (iOS 16+).
  final List<AdaptiveContextMenuItem>? contextMenuActions;

  AdaptiveListTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.useGlass = false,
    this.contextMenuActions,
  });

  @override
  Widget build(BuildContext context) {
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      // Serialize actions
      List<Map<String, dynamic>>? serializedActions;
      if (contextMenuActions != null) {
        serializedActions = contextMenuActions!.map((action) {
          String label = 'Action';
          if (action.child is Text) {
            label = (action.child as Text).data ?? 'Action';
          }
          return {
            'label': label,
            'isDestructive': action.isDestructive,
            'icon': action.icon,
          };
        }).toList();
      }

      // Native Implementation
      return SizedBox(
        width: double.infinity,
        height: min(subtitle != null ? 64 : 48,
            100), // Approximate height refined for proportionality
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: UiKitView(
            viewType: 'adaptive_cupertino_ios/list_tile',
            creationParams: {
              'title': (title is Text) ? (title as Text).data : '',
              'subtitle': (subtitle is Text) ? (subtitle as Text).data : null,
              'useGlass': useGlass,
              if (serializedActions != null)
                'contextMenuActions': serializedActions,
              if (trailing != null) 'trailing': _serializeTrailing(trailing!),
              if (leading != null)
                'leading': _serializeTrailing(
                    leading!), // Re-using trailing serializer for now
            },
            creationParamsCodec: const StandardMessageCodec(),
            // gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            //   Factory<OneSequenceGestureRecognizer>(
            //     () => EagerGestureRecognizer(),
            //   ),
            // },
            onPlatformViewCreated: (id) {
              // Setup channel for callbacks
              final channel =
                  MethodChannel('adaptive_cupertino_ios/list_tile_$id');
              channel.setMethodCallHandler((call) async {
                if (call.method == 'onTap') {
                  // Native can still trigger tap if needed, but primary is now Flutter
                  onTap?.call();
                } else if (call.method == 'onContextMenuAction') {
                  final index = call.arguments['index'] as int;
                  if (contextMenuActions != null &&
                      index < contextMenuActions!.length) {
                    contextMenuActions![index].onPressed();
                  }
                } else if (call.method == 'onTrailingChanged') {
                  final newValue = call.arguments['value'] as bool;
                  if (trailing is AdaptiveSwitch) {
                    (trailing as AdaptiveSwitch).onChanged?.call(newValue);
                  }
                }
              });
            },
          ),
        ),
      );
    }

    // Material Fallback
    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      onTap: onTap,
    );
  }

  Map<String, dynamic>? _serializeTrailing(Widget widget) {
    if (widget is AdaptiveSwitch) {
      return {
        'type': 'switch',
        'value': widget.value,
      };
    } else if (widget is AdaptiveBadge) {
      return {
        'type': 'badge',
        'text': widget.label is Text ? (widget.label as Text).data : null,
        'sfSymbol': widget.sfSymbol,
        'effect': widget.effect,
        'isRepeating': widget.isRepeating,
        'useGlass': widget.useGlass,
        'backgroundColor': widget.backgroundColor?.value,
        'labelColor': widget.labelColor?.value,
      };
    } else if (widget is Icon) {
      // Logic from WidgetSerializer.serialize(widget)
      return {
        'type': 'icon',
        'iconCode': widget.icon?.codePoint,
        'iconFamily': widget.icon?.fontFamily,
        'iconPackage': widget.icon?.fontPackage,
      };
    } else if (widget is Text) {
      return {
        'type': 'text',
        'data': widget.data,
      };
    } else if (widget is Container) {
      // Check if child is AdaptiveBadge first
      if (widget.child is AdaptiveBadge) {
        return _serializeTrailing(widget.child!);
      }

      final boxDecoration = widget.decoration as BoxDecoration?;
      Color? color = boxDecoration?.color;
      double radius = 0;
      if (boxDecoration?.borderRadius is BorderRadius) {
        radius = (boxDecoration!.borderRadius as BorderRadius).topLeft.x;
      }

      String? text;
      if (widget.child is Text) {
        text = (widget.child as Text).data;
      } else if (widget.child is Center &&
          (widget.child as Center).child is Text) {
        text = ((widget.child as Center).child as Text).data;
      }

      if (color != null && text != null) {
        return {
          'type': 'badge',
          'color': color.value,
          'text': text,
          'radius': radius,
        };
      }
    }
    return null;
  }
}


// Mixin removed as we are converting to direct implementation for simplicity in this phase.
