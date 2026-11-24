import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bdland_pro/features/tools/05_quadmaster/quadmaster_screen.dart';
import 'package:bdland_pro/features/tools/widgets/touch_magnifier_loupe.dart';

void main() {
  group('QuadMasterScreen Undo/Redo & Measurement Tests', () {
    testWidgets('QuadMaster records pre-edit state on input change and clears redo on new edit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: QuadMasterScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find first TextField (north controller: default '120.0')
      final textFields = find.byType(TextField);
      expect(textFields, findsWidgets);

      // Verify initial text
      expect(find.text('120.0'), findsOneWidget);

      // Change North value to 150.0
      await tester.enterText(textFields.first, '150.0');
      await tester.pumpAndSettle();
      expect(find.text('150.0'), findsOneWidget);

      // Tap Undo button
      final undoBtn = find.byTooltip('পূর্বাবস্থা (Undo)');
      expect(undoBtn, findsOneWidget);
      await tester.tap(undoBtn);
      await tester.pumpAndSettle();

      // North should be restored to pre-edit value (120.0)
      expect(find.text('120.0'), findsOneWidget);

      // Tap Redo button
      final redoBtn = find.byTooltip('পুনরাবৃত্তি (Redo)');
      expect(redoBtn, findsOneWidget);
      await tester.tap(redoBtn);
      await tester.pumpAndSettle();

      // North should be restored to redone value (150.0)
      expect(find.text('150.0'), findsOneWidget);

      // Undo again back to 120.0
      await tester.tap(undoBtn);
      await tester.pumpAndSettle();
      expect(find.text('120.0'), findsOneWidget);

      // Make a brand new edit to North (e.g. 180.0)
      await tester.enterText(textFields.first, '180.0');
      await tester.pumpAndSettle();
      expect(find.text('180.0'), findsOneWidget);

      // Now Redo should be cleared because a new edit occurred
      await tester.tap(redoBtn);
      await tester.pumpAndSettle();

      // Should show snackbar that there's no redo history
      expect(find.text('সামনে যাওয়ার তথ্য নেই'), findsOneWidget);
    });
  });

  group('TouchMagnifierLoupe Tests', () {
    testWidgets('TouchMagnifierLoupe applies sourceSize constraints to content', (tester) async {
      const sourceSize = Size(400, 600);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                TouchMagnifierLoupe(
                  touchPosition: const Offset(100, 100),
                  sourceSize: sourceSize,
                  child: Container(color: Colors.blue),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final matchingBox = sizedBoxes.where((sb) => sb.width == 400 && sb.height == 600);
      expect(matchingBox, isNotEmpty);
    });
  });

  group('WGS84 Coordinate Range Validation Tests', () {
    bool isValidWGS84(double? lat, double? lng) {
      if (lat == null || lng == null) return false;
      if (!lat.isFinite || !lng.isFinite) return false;
      if (lat < -90.0 || lat > 90.0) return false;
      if (lng < -180.0 || lng > 180.0) return false;
      return true;
    }

    test('Validates normal coordinates within range', () {
      expect(isValidWGS84(23.8103, 90.4125), isTrue); // Dhaka
      expect(isValidWGS84(0.0, 0.0), isTrue);
      expect(isValidWGS84(-90.0, -180.0), isTrue);
      expect(isValidWGS84(90.0, 180.0), isTrue);
    });

    test('Rejects latitude 280 and out-of-range coordinates', () {
      expect(isValidWGS84(280.0, 90.0), isFalse);
      expect(isValidWGS84(-95.0, 90.0), isFalse);
      expect(isValidWGS84(23.8, 185.0), isFalse);
      expect(isValidWGS84(23.8, -185.0), isFalse);
    });

    test('Rejects non-finite values (NaN and Infinity)', () {
      expect(isValidWGS84(double.nan, 90.0), isFalse);
      expect(isValidWGS84(23.8, double.nan), isFalse);
      expect(isValidWGS84(double.infinity, 90.0), isFalse);
      expect(isValidWGS84(23.8, double.negativeInfinity), isFalse);
    });
  });
}
