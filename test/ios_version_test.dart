import 'package:adaptive_cupertino_ios/adaptive_cupertino_ios.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IOSVersion', () {
    setUp(() {
      // Reset singleton before each test
      IOSVersion().reset();
    });

    test('returns singleton instance', () {
      final instance1 = IOSVersion();
      final instance2 = IOSVersion();
      expect(identical(instance1, instance2), isTrue);
    });

    test('caches support status after first check', () async {
      final version = IOSVersion();

      // First check
      final result1 = await version.supportsNativeUI();
      expect(version.cachedSupportsNativeUI, isNotNull);

      // Second check should return cached value
      final result2 = await version.supportsNativeUI();
      expect(result1, result2);
      expect(version.cachedSupportsNativeUI, result1);
    });

    test('reset clears cache', () {
      final version = IOSVersion();
      version.supportsNativeUI(); // Populate cache

      version.reset();

      expect(version.cachedSupportsNativeUI, isNull);
      expect(version.lastCheckTime, isNull);
      expect(version.lastError, isNull);
    });

    test('tracks last check time', () async {
      final version = IOSVersion();
      expect(version.lastCheckTime, isNull);

      await version.supportsNativeUI();

      expect(version.lastCheckTime, isNotNull);
      expect(version.lastCheckTime!.isBefore(DateTime.now()), isTrue);
    });
  });
}
