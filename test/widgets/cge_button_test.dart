import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cge_lounge_app/widgets/cge_button.dart';

void main() {
  group('CgeButton', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CgeButton(
              label: 'Book Now',
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Book Now'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CgeButton(
              label: 'Tap Me',
              onPressed: () {
                pressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CgeButton(
              label: 'Loading',
              onPressed: () {},
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Label should still be visible alongside the spinner
      expect(find.text('Loading'), findsOneWidget);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CgeButton(
              label: 'Disabled',
              onPressed: null,
            ),
          ),
        ),
      );

      // The button renders with reduced opacity when disabled
      final opacity = tester.widget<AnimatedOpacity>(
        find.byType(AnimatedOpacity),
      );
      expect(opacity.opacity, 0.5);

      // Label is still rendered
      expect(find.text('Disabled'), findsOneWidget);
    });

    testWidgets('does not call onPressed when isLoading is true', (tester) async {
      bool pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CgeButton(
              label: 'Loading',
              onPressed: () {
                pressed = true;
              },
              isLoading: true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Loading'));
      await tester.pump();

      expect(pressed, isFalse);
    });
  });
}
