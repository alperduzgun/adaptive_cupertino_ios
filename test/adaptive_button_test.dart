import 'package:adaptive_cupertino_ios/adaptive_cupertino_ios.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdaptiveButton', () {
    testWidgets('renders standard button', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: AdaptiveButton(
              onPressed: () {
                pressed = true;
              },
              child: const Text('Test Button'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Test Button'), findsOneWidget);
      expect(pressed, isFalse);

      await tester.tap(find.text('Test Button'));
      expect(pressed, isTrue);
    });

    testWidgets('renders glass button', (tester) async {
      await tester.pumpWidget(
        const CupertinoApp(
          home: Center(
            child: AdaptiveButton.glass(
              onPressed: null,
              child: Text('Glass Button'),
            ),
          ),
        ),
      );

      // Wait for version check
      await tester.pumpAndSettle();

      // Verify button renders (actual style depends on iOS version)
      expect(find.text('Glass Button'), findsOneWidget);
    });

    testWidgets('renders glass button with icon', (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: Center(
            child: AdaptiveButton(
              style: AdaptiveButtonStyle.glass,
              icon: const Icon(CupertinoIcons.heart_fill),
              iconPlacement: IconPlacement.leading,
              onPressed: () {},
              child: const Text('Like'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify text renders
      expect(find.text('Like'), findsOneWidget);
    });

    test('IconPlacement enum values', () {
      expect(IconPlacement.leading, isA<IconPlacement>());
      expect(IconPlacement.trailing, isA<IconPlacement>());
      expect(IconPlacement.top, isA<IconPlacement>());
      expect(IconPlacement.bottom, isA<IconPlacement>());
    });

    test('AdaptiveButtonStyle enum values', () {
      expect(AdaptiveButtonStyle.filled, isA<AdaptiveButtonStyle>());
      expect(AdaptiveButtonStyle.text, isA<AdaptiveButtonStyle>());
      expect(AdaptiveButtonStyle.outlined, isA<AdaptiveButtonStyle>());
      expect(AdaptiveButtonStyle.glass, isA<AdaptiveButtonStyle>());
      expect(AdaptiveButtonStyle.glassProminent, isA<AdaptiveButtonStyle>());
      expect(AdaptiveButtonStyle.glassTinted, isA<AdaptiveButtonStyle>());
    });
  });
}
