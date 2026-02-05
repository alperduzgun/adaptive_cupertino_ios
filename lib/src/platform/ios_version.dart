import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'bridge.dart';

/// iOS version detection utility.
///
/// Provides methods to check iOS version and determine if native
/// implementations should be used.
///
/// Features:
/// - Singleton pattern with cached results
/// - Structural logging with context
/// - Fail-safe error handling
/// - Observable state
class IOSVersion {
  factory IOSVersion() => _instance;

  IOSVersion._internal();

  static final IOSVersion _instance = IOSVersion._internal();

  /// Pre-warms the iOS version cache.
  ///
  /// This should be called early in the app lifecycle (e.g. main)
  /// to ensure version info is available synchronously during build.
  static Future<void> prewarm() async {
    final instance = IOSVersion();
    if (instance._supportsNativeUI == null) {
      await instance.supportsNativeUI();
    }
    if (instance._supportsModernToolbar == null) {
      await instance.supportsModernToolbar();
    }
  }

  // IDEMPOTENCY: Cached results
  bool? _supportsNativeUI;
  bool? _supportsModernToolbar;
  DateTime? _lastCheckTime;
  Object? _lastError;

  /// Get cached iOS 18+ support status
  bool? get cachedSupportsNativeUI => _supportsNativeUI;

  /// Get cached iOS 26+ modern toolbar support status
  bool? get cachedSupportsModernToolbar => _supportsModernToolbar;

  /// Get last check timestamp
  DateTime? get lastCheckTime => _lastCheckTime;

  /// Get last error if any
  Object? get lastError => _lastError;

  /// Check if device supports iOS 18+ native UI (Glass Effect).
  ///
  /// Returns `true` for iOS 18+, `false` otherwise.
  /// Caches the result for performance.
  ///
  /// Features:
  /// - Idempotent: Returns cached result after first check
  /// - Fail-safe: Returns false on error
  /// - Observable: Logs all operations with context
  Future<bool> supportsNativeUI() async {
    // Return cached result if available
    if (_supportsNativeUI != null) {
      _logInfo('Returning cached iOS version check result: $_supportsNativeUI');
      return _supportsNativeUI!;
    }

    _lastCheckTime = DateTime.now();
    _logInfo('Starting iOS version check...');

    // Fast path: Non-iOS platforms don't support native UI
    if (!Platform.isIOS) {
      _supportsNativeUI = false;
      _logInfo(
          'Platform: ${Platform.operatingSystem} - Native UI not supported');
      return false;
    }

    try {
      final bridge = AdaptiveCupertinoBridge();
      _supportsNativeUI = await bridge.supportsNativeUI();
      _lastError = null; // Clear error on success

      _logInfo(
          'iOS version check completed: Native UI ${_supportsNativeUI! ? "supported (iOS 18+)" : "not supported (iOS <18)"}');

      return _supportsNativeUI!;
    } catch (error, stackTrace) {
      _lastError = error;
      _supportsNativeUI = false;

      _logError(
        'iOS version check failed',
        error: error,
        stackTrace: stackTrace,
      );

      // Fail-safe: Return false on error
      return false;
    }
  }

  /// Check if device supports iOS 26+ modern toolbar (pill-shaped buttons).
  ///
  /// Returns `true` for iOS 26+, `false` otherwise.
  /// Caches the result for performance (idempotent).
  ///
  /// CHAOS ENGINEERING PRINCIPLES:
  /// - Fail-safe: Returns false on error
  /// - Observable: Logs all operations with context
  /// - Anti-fragile: Multiple fallback checks
  /// - Idempotent: Cached result returned after first check
  Future<bool> supportsModernToolbar() async {
    // IDEMPOTENCY: Return cached result if available
    if (_supportsModernToolbar != null) {
      _logInfo(
          'Returning cached iOS 26+ check result: $_supportsModernToolbar');
      return _supportsModernToolbar!;
    }

    _lastCheckTime = DateTime.now();
    _logInfo('Starting iOS 26+ modern toolbar check...');

    // FAIL-FAST: Non-iOS platforms don't support modern toolbar
    if (!Platform.isIOS) {
      _supportsModernToolbar = false;
      _logInfo(
          'Platform: ${Platform.operatingSystem} - Modern toolbar not supported');
      return false;
    }

    try {
      final bridge = AdaptiveCupertinoBridge();
      _supportsModernToolbar = await bridge.supportsModernToolbar();
      _lastError = null; // Clear error on success

      _logInfo(
        'iOS 26+ check completed: Modern toolbar ${_supportsModernToolbar! ? "supported (iOS 26+)" : "not supported (iOS <26)"}',
      );

      return _supportsModernToolbar!;
    } catch (error, stackTrace) {
      // FAIL-SAFE: On error, fall back to false
      _lastError = error;
      _supportsModernToolbar = false;

      _logError(
        'iOS 26+ modern toolbar check failed',
        error: error,
        stackTrace: stackTrace,
      );

      // Graceful degradation: Return false
      return false;
    }
  }

  /// Reset cached version checks.
  ///
  /// SELF-HEALING: Useful for testing or recovery from stale state.
  void reset() {
    _supportsNativeUI = null;
    _supportsModernToolbar = null;
    _lastCheckTime = null;
    _lastError = null;
    _logInfo('iOS version cache reset (all checks)');
  }

  /// Structured logging - Info level
  void _logInfo(String message) {
    developer.log(
      message,
      name: 'IOSVersion',
      level: 800, // Info
      time: DateTime.now(),
    );

    if (kDebugMode) {
      debugPrint('[IOSVersion] $message');
    }
  }

  /// Structured logging - Error level
  void _logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: 'IOSVersion',
      error: error,
      stackTrace: stackTrace,
      level: 1000, // Severe
      time: DateTime.now(),
    );

    if (kDebugMode) {
      debugPrint('[IOSVersion] ❌ $message');
      if (error != null) {
        debugPrint('[IOSVersion] Error: $error');
      }
    }
  }
}
