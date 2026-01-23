import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge for communication with native iOS code.
///
/// Handles method channel communication for iOS version detection
/// and native UI coordination.
class AdaptiveCupertinoBridge {
  static const MethodChannel _channel =
      MethodChannel('adaptive_cupertino_ios');

  /// Check if device supports iOS 18+ native UI.
  Future<bool> supportsNativeUI() async {
    try {
      final result = await _channel.invokeMethod<bool>('supportsNativeUI');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if device supports Liquid Glass (iOS 18+)
  Future<bool> supportsLiquidGlass() async {
    try {
      final result = await _channel.invokeMethod<bool>('supportsLiquidGlass');
      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to check Liquid Glass support: $e');
      }
      return false;
    }
  }

  /// Check if device supports iOS 26+ modern toolbar (pill-shaped buttons)
  /// CHAOS RESISTANT: Returns false on any error (fail-safe default)
  Future<bool> supportsModernToolbar() async {
    try {
      final result = await _channel.invokeMethod<bool>('supportsModernToolbar');
      return result ?? false; // FAIL-SAFE: Default to false if null
    } catch (e) {
      // OBSERVABILITY: Log error in debug mode
      if (kDebugMode) {
        debugPrint('Failed to check modern toolbar support: $e');
      }
      // GRACEFUL DEGRADATION: Return false on error
      return false;
    }
  }

  /// Get iOS version information
  Future<Map<String, dynamic>?> getIOSVersion() async {
    try {
      final result = await _channel.invokeMethod('getIOSVersion');
      return Map<String, dynamic>.from(result as Map);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to get iOS version: $e');
      }
      return null;
    }
  }

  /// Notify native side of tab selection change.
  Future<void> notifyTabChanged(int index) async {
    try {
      await _channel.invokeMethod('notifyTabChanged', {'index': index});
    } catch (e) {
      // Silently fail if native side is not available
    }
  }

  /// Listen to tab changes from native side.
  Stream<int> get onTabChanged {
    return const EventChannel('adaptive_cupertino_ios/tab_changes')
        .receiveBroadcastStream()
        .map((dynamic event) => event as int);
  }
}
