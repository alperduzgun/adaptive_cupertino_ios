import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// Internal registry for widget factories.
///
/// Since native sheets use isolated Flutter engines (FlutterEngineGroup)
/// for total UI isolation, factories MUST be registered in your main()
/// function to be available to all isolates.
class SheetContentFactory {
  static final Map<String, Widget Function()> _factories = {};

  /// Registers a named factory for sheet content.
  /// Call this in your main() function.
  static void register(String id, Widget Function() builder) {
    _factories[id] = builder;
  }

  /// Retrieves a widget from a factory.
  static Widget? build(String id) => _factories[id]?.call();
}

/// A widget that hosts registered content for native sheets.
///
/// This is used internally by the native side to render the correct widget.
class SheetHost extends StatelessWidget {
  final String contentId;

  const SheetHost({super.key, required this.contentId});

  @override
  Widget build(BuildContext context) {
    final widget = SheetContentFactory.build(contentId);

    if (widget != null) {
      // Phase 2.1: Smooth Transitions
      // Notify native side to unhide content after the first frame is scheduled.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint(
            '🛡️ [AdaptiveSheet] First frame ready for "$contentId", notifying native to unhide.');
        const MethodChannel('adaptive_cupertino_ios/sheet_lifecycle')
            .invokeMethod('unhide_content');
      });
    }

    if (widget == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle, size: 48),
            const SizedBox(height: 16),
            Text(
              'Sheet content "$contentId" not found.\nDid you register it in main()?',
              textAlign: TextAlign.center,
              style: const TextStyle(color: CupertinoColors.systemRed),
            ),
          ],
        ),
      );
    }
    return Container(
      color: CupertinoColors
          .transparent, // Chaos-Proof: Ensure no masking of native glass
      child: widget,
    );
  }
}

/// Detents for native iOS Bottom Sheets.
enum AdaptiveSheetDetent {
  /// Approximately 50% of the screen height.
  medium,

  /// Approximately 100% of the screen height.
  large,
}

/// Shows a native iOS bottom sheet with interactive Flutter content.
///
/// [contentId] refers to a widget registered via [SheetContentFactory.register]
/// in the global main() function.
///
/// **Phase 4 High-Fidelity Features:**
/// - [isFloating]: If true, the sheet appears as a detached card (iOS 26+ style).
/// - [customDetents]: List of fractional (0.0-1.0) or absolute heights.
/// - [sourceKey]: A GlobalKey used to calculate the morphing transition source.
Future<bool> showAdaptiveCupertinoSheet(
  BuildContext context, {
  required String contentId,
  List<AdaptiveSheetDetent> detents = const [
    AdaptiveSheetDetent.medium,
    AdaptiveSheetDetent.large
  ],
  List<double> customDetents = const [],
  bool isDismissible = true,
  bool enableDrag = true,
  bool isFloating = false,
  bool showGrabber = true,
  double? cornerRadius,
  GlobalKey? sourceKey,
}) async {
  const channel = MethodChannel('adaptive_cupertino_ios');

  // Phase 4 Chaos Remediation: Advanced Sanitization
  // Assume malicious or accidental inputs (Chaos Lens)
  final sanitizedCustomDetents = customDetents
      .map((d) => d.clamp(0.001, 1.0)) // 0.0 is invalid for native detents
      .toList()
    ..sort(); // Native detents must be sorted ascending

  final sanitizedCornerRadius =
      cornerRadius != null ? cornerRadius.clamp(0.0, 100.0) : null;

  // Setup callback for lifecycle and detents (Observability & Resize Bridge)
  // Self-Healing: Use a localized handler that doesn't leak
  channel.setMethodCallHandler((call) async {
    switch (call.method) {
      case 'onDetentChanged':
        debugPrint(
            '🛡️ [AdaptiveSheet] Native detent changed: ${call.arguments['detent']}');
        break;
      case 'onSheetDismissed':
        debugPrint(
            '🛡️ [AdaptiveSheet] Native sheet dismissed. Cleaning up handler.');
        // Cleanup: Nullify handler on dismissal to prevent leaks
        channel.setMethodCallHandler(null);
        break;
    }
  });

  try {
    debugPrint(
        '🛡️ [AdaptiveSheet] Requesting native sheet presentation for contentId: $contentId');
    final List<String> detentStrings = detents.map((d) => d.name).toList();

    Map<String, double>? sourceRect;
    if (sourceKey != null) {
      final RenderBox? renderBox =
          sourceKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        sourceRect = {
          'x': position.dx,
          'y': position.dy,
          'width': size.width,
          'height': size.height,
        };
        debugPrint(
            '🛡️ [AdaptiveSheet] Matched Transition Source: $sourceRect');
      }
    }

    final bool? result = await channel.invokeMethod<bool>(
      'showSheet',
      {
        'contentId': contentId,
        'detents': detentStrings,
        'customDetents': sanitizedCustomDetents,
        'isDismissible': isDismissible,
        'enableDrag': enableDrag,
        'isFloating': isFloating,
        'showGrabber': showGrabber,
        'cornerRadius': sanitizedCornerRadius,
        'sourceRect': sourceRect,
      },
    );

    if (result == true) {
      debugPrint('🛡️ [AdaptiveSheet] Native sheet presented successfully.');
    } else {
      debugPrint(
          '🛡️ [AdaptiveSheet] Native sheet presentation failed or was rejected.');
      // Cleanup on failure
      channel.setMethodCallHandler(null);
    }

    return result ?? false;
  } on PlatformException catch (e) {
    debugPrint('🛡️ [AdaptiveSheet] Failed to show native sheet: ${e.message}');
    channel.setMethodCallHandler(null);
    return false;
  }
}

/// Route handler for adaptive sheet content isolates.
Route? onGenerateAdaptiveSheetRoute(RouteSettings settings) {
  if (settings.name?.startsWith('/adaptive-sheet') ?? false) {
    final uri = Uri.parse(settings.name!);
    final id = uri.queryParameters['id'];
    if (id != null) {
      return CupertinoPageRoute(
        settings: settings,
        builder: (_) => SheetHost(contentId: id),
      );
    }
  }
  return null;
}
