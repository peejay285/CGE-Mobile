import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cge_lounge_app/widgets/cge_badge.dart';
import 'package:cge_lounge_app/core/theme/app_colors.dart';

void main() {
  group('CgeBadge', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CgeBadge(label: 'Active'),
          ),
        ),
      );

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('applies cyan color by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CgeBadge(label: 'Default'),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Default'));
      expect((text.style as TextStyle).color, AppColors.cyan);
    });

    testWidgets('applies correct color for magenta variant', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CgeBadge(label: 'Hot', color: BadgeColor.magenta),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Hot'));
      expect((text.style as TextStyle).color, AppColors.magenta);
    });

    testWidgets('applies correct color for gold variant', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CgeBadge(label: 'Premium', color: BadgeColor.gold),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Premium'));
      expect((text.style as TextStyle).color, AppColors.gold);
    });

    testWidgets('applies correct color for green variant', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CgeBadge(label: 'Online', color: BadgeColor.green),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Online'));
      expect((text.style as TextStyle).color, AppColors.green);
    });

    testWidgets('applies correct color for red variant', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CgeBadge(label: 'Error', color: BadgeColor.red),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Error'));
      expect((text.style as TextStyle).color, AppColors.red);
    });
  });
}
