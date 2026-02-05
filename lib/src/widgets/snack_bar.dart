import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glass_box.dart';

/// Shows an adaptive snackbar or banner.
///
/// On iOS, it displays a floating banner at the top of the screen.
/// On Android, it uses the standard [ScaffoldMessenger.showSnackBar].
void showAdaptiveSnackBar(
  BuildContext context, {
  required String message,
  Duration duration = const Duration(seconds: 3),
  bool useGlass = false,
}) {
  final platform = Theme.of(context).platform;

  if (platform == TargetPlatform.iOS) {
    _showCupertinoBanner(context, message, duration, useGlass);
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration,
    ),
  );
}

void _showCupertinoBanner(
  BuildContext context,
  String message,
  Duration duration,
  bool useGlass,
) {
  // Try native via channel
  try {
    const channel = MethodChannel('adaptive_cupertino_ios');
    channel.invokeMethod('showSnackBar', {
      'message': message,
      'duration': duration.inMilliseconds / 1000.0,
      'icon': 'info.circle.fill', // Default icon
    });
    // If success, we are done.
    // If native failed or not supported, we could fallback, but for now we assume it works if on iOS.
    return;
  } catch (e) {
    debugPrint('Native SnackBar failed: $e');
  }

  // Fallback (Flutter Implementation) - if needed or for older iOS
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) => _CupertinoBannerWidget(
      message: message,
      useGlass: useGlass,
      onDismiss: () {
        if (entry.mounted) {
          entry.remove();
        }
      },
    ),
  );

  overlay.insert(entry);

  // CHAOS SAFETY: Ensure entry is removed after duration, even if context is gone
  Future.delayed(duration, () {
    if (entry.mounted) {
      entry.remove();
    }
  });
}

class _CupertinoBannerWidget extends StatelessWidget {
  final String message;
  final bool useGlass;
  final VoidCallback onDismiss;

  const _CupertinoBannerWidget({
    required this.message,
    required this.useGlass,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: onDismiss,
        child: Material(
          // For text style and elevation
          color: Colors.transparent,
          child: useGlass
              ? AdaptiveGlassBox(
                  borderRadius: 16,
                  child: _buildContent(context),
                )
              : Container(
                  decoration: BoxDecoration(
                    color:
                        CupertinoColors.systemBackground.resolveFrom(context),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _buildContent(context),
                ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Icon(CupertinoIcons.info_circle_fill,
              color: CupertinoColors.activeBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: CupertinoColors.label,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
