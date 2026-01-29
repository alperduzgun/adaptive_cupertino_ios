import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Detents for native iOS Bottom Sheets.
enum AdaptiveSheetDetent {
  /// Approximately 50% of the screen height.
  medium,

  /// Approximately 100% of the screen height.
  large,
}

/// Shows a native iOS bottom sheet with Liquid Glass aesthetics (iOS 26+).
///
/// This uses `UISheetPresentationController` on iOS for true native behavior,
/// including interactive dismissal and detents.
///
/// [detents] defines the allowed heights for the sheet. Defaults to `[medium]`.
/// [showGrabber] whether to show the native grabber handle at the top.
/// [cornerRadius] the preferred corner radius for the sheet.
Future<bool> showAdaptiveCupertinoSheet(
  BuildContext context, {
  required Widget child,
  List<AdaptiveSheetDetent> detents = const [AdaptiveSheetDetent.medium],
  bool showGrabber = true,
  double cornerRadius = 16.0,
}) async {
  const channel = MethodChannel('adaptive_cupertino_ios');

  try {
    final List<String> detentStrings = detents.map((d) => d.name).toList();

    final bool? result = await channel.invokeMethod<bool>(
      'showSheet',
      {
        'detents': detentStrings,
        'showGrabber': showGrabber,
        'cornerRadius': cornerRadius,
      },
    );

    return result ?? false;
  } on PlatformException catch (e) {
    debugPrint('Failed to show native sheet: ${e.message}');
    return false;
  }
}
