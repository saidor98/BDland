import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bdland_pro/core/utils/pdf_report_helper.dart';
import 'package:bdland_pro/features/tools/02_mouza_simple/mouza_map_simple_screen.dart';
import 'package:bdland_pro/features/tools/04_anyshape_divider/anyshape_divider_screen.dart';
import 'package:bdland_pro/features/tools/05_quadmaster/quadmaster_screen.dart';
import 'package:bdland_pro/features/tools/13_unknown_side_solver/unknown_side_solver_screen.dart';
import 'package:bdland_pro/features/tools/19_hindu_inheritance/hindu_inheritance_screen.dart';
import 'package:bdland_pro/features/tools/20_hissya_calculator/hissya_calculator_screen.dart';
import 'package:bdland_pro/features/tools/23_survey_formulas/land_survey_formulas_screen.dart';
import 'package:bdland_pro/features/tools/widgets/touch_magnifier_loupe.dart';

void main() {
  group('QuadMasterScreen Undo/Redo & Measurement Tests', () {
    testWidgets('QuadMaster records pre-edit state on input change and clears redo on new edit', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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

    testWidgets('QuadMaster switches between all 4 functional tabs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: QuadMasterScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('২  পদ্ধতি'));
      await tester.pumpAndSettle();
      expect(find.text('হেরন সূত্র (আইনসম্মত ২ ত্রিভুজ পদ্ধতি)'), findsOneWidget);

      await tester.tap(find.text('৩  ক্ষেত্রফল'));
      await tester.pumpAndSettle();
      expect(find.text('সকল ভূমি এককে প্রকৃত ক্ষেত্রফল'), findsOneWidget);

      await tester.tap(find.text('৪  বণ্টন'));
      await tester.pumpAndSettle();
      expect(find.text('অংশীদার / ওয়ারিশদের মাঝে সমান বণ্টন'), findsOneWidget);
    });
  });

  group('HinduInheritanceScreen 1937 Act Tests', () {
    testWidgets('Widow receives equal 1/3 share alongside 2 sons under 1937 Act', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HinduInheritanceScreen()));
      await tester.pumpAndSettle();

      // Default: 100.0 decimal, 2 sons, 1 widow -> 2 parts (66.667) + 1 part (33.333)
      expect(find.text('পুত্র / ছেলে (২ জন)'), findsOneWidget);
      expect(find.text('বিধবা স্ত্রী (১ জন)'), findsOneWidget);
      expect(find.text('৬৬.৬৬৭ শতক'), findsOneWidget);
      expect(find.text('৩৩.৩৩৩ শতক'), findsOneWidget);
      expect(find.textContaining('১৯৩৭ সালের আইন'), findsOneWidget);
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

  group('HissyaCalculatorScreen & AnyShapeDividerScreen Tests', () {
    testWidgets('HissyaCalculator supports multiply and divide share operations', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HissyaCalculatorScreen()));
      await tester.pumpAndSettle();

      // Default Share 1 = 4 Ana 10 Gonda. Switch to Multiply (x2) -> 9 Ana
      await tester.tap(find.text('× গুণ'));
      await tester.pumpAndSettle();
      expect(find.textContaining('৯ আনা'), findsOneWidget);

      // Switch to Divide (/2) -> 2 Ana 5 Gonda
      await tester.tap(find.text('÷ ভাগ'));
      await tester.pumpAndSettle();
      expect(find.textContaining('২ আনা ৫ গণ্ডা'), findsOneWidget);
    });

    testWidgets('AnyShapeDivider allows adding a new polygon corner vertex', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AnyShapeDividerScreen()));
      await tester.pumpAndSettle();

      final addVertexBtn = find.text('+ কোণ যোগ');
      expect(addVertexBtn, findsOneWidget);
      await tester.ensureVisible(addVertexBtn);
      await tester.tap(addVertexBtn);
      await tester.pumpAndSettle();
    });
  });

  group('MouzaMapSimpleScreen Stitch Portal Tests', () {
    testWidgets('Renders Stitch Cadastral Precision portal decks and opens CAD view', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: MouzaMapSimpleScreen()));
      await tester.pumpAndSettle();

      expect(find.text('সংরক্ষিত প্রজেক্ট ও ড্রাফট'), findsOneWidget);
      expect(find.text('ডিভাইস থেকে'), findsOneWidget);
      expect(find.text('ক্লাউড ডাটাবেস'), findsOneWidget);
      expect(find.text('Total Station ও লাইভ GPS'), findsOneWidget);
      expect(find.text('CAD ক্যানভাস ও জমি হিসাব'), findsOneWidget);

      final ctaBtn = find.text('CAD পরিমাপ ক্যানভাসে প্রবেশ করুন');
      expect(ctaBtn, findsOneWidget);
      await tester.ensureVisible(ctaBtn);
      await tester.tap(ctaBtn);
      await tester.pumpAndSettle();

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.text('অটো-ডিভিশন / বণ্টন'), findsOneWidget);
    });
  });

  group('Tool 13 UnknownSide & Tool 23 Formulas Tests', () {
    testWidgets('UnknownSideSolver detects impossible trapezoid geometry', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: UnknownSideSolverScreen()));
      await tester.pumpAndSettle();

      // Switch to Trapezoid mode where default 5 dec = 2178 sq ft, a = 80, h = 60 -> b = (4356/60)-80 = -7.4 <= 0
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ট্রাপিজিয়াম (১ম বাহু ও উচ্চতা দেওয়া, ২য় বাহু নির্ণয়)').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('অসম্ভব জ্যামিতি'), findsOneWidget);
    });

    testWidgets('LandSurveyFormulas filters sections by search query', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LandSurveyFormulasScreen()));
      await tester.pumpAndSettle();

      expect(find.textContaining('গান্টার্স চেইন'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'নামজারি');
      await tester.pumpAndSettle();

      expect(find.textContaining('নামজারি (Mutation)'), findsOneWidget);
      expect(find.textContaining('গান্টার্স চেইন'), findsNothing);
    });

    test('PdfReportHelper builds stylized Emerald & Gold A4 Bengali HTML safely', () {
      final html = PdfReportHelper.buildCadastralHtmlDocument(
        title: 'সম্পত্তির তফসিল বিবরণী',
        subtitle: 'মৌজা: <জাফরাবাদ> & দাগ ৫০১',
        bodyHtml: '<p>হস্তান্তরিত জমি: ৫.০০ শতক</p>',
      );
      expect(html, contains('#004126'));
      expect(html, contains('#FFC64D'));
      expect(html, contains('সম্পত্তির তফসিল বিবরণী'));
      expect(html, contains('&lt;জাফরাবাদ&gt; &amp; দাগ ৫০১'));
      expect(html, contains('হস্তান্তরিত জমি: ৫.০০ শতক'));
    });
  });
}
