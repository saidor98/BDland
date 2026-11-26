import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bdland_pro/features/home/data/tools_data.dart';
import 'package:bdland_pro/features/tools/25_name_share_calculator/name_share_calculator_screen.dart';
import 'package:bdland_pro/features/tools/25_name_share_calculator/name_share_model.dart';

void main() {
  group('NameShareCalculatorLogic Unit Tests', () {
    test('Parses decimal, 1000-scale namjari, fraction, and ana-gonda shares accurately', () {
      final dec = NameShareCalculatorLogic.parseShareInput(
        mode: ShareInputMode.decimal,
        decimalText: '0.25',
      );
      expect(dec.isValid, isTrue);
      expect(dec.shareFraction, closeTo(0.25, 1e-6));

      final namjari = NameShareCalculatorLogic.parseShareInput(
        mode: ShareInputMode.namjari1000,
        namjariText: '125',
      );
      expect(namjari.isValid, isTrue);
      expect(namjari.shareFraction, closeTo(0.125, 1e-6));

      final frac = NameShareCalculatorLogic.parseShareInput(
        mode: ShareInputMode.fraction,
        numeratorText: '1',
        denominatorText: '8',
      );
      expect(frac.isValid, isTrue);
      expect(frac.shareFraction, closeTo(0.125, 1e-6));

      final ana = NameShareCalculatorLogic.parseShareInput(
        mode: ShareInputMode.anaGonda,
        ana: 4,
      );
      expect(ana.isValid, isTrue);
      expect(ana.shareFraction, closeTo(0.25, 1e-6));
    });

    test('Rejects invalid inputs (zero denominator, >1.0 fraction, out-of-range ana/gonda)', () {
      expect(
        NameShareCalculatorLogic.parseShareInput(
          mode: ShareInputMode.fraction,
          numeratorText: '1',
          denominatorText: '0',
        ).isValid,
        isFalse,
      );
      expect(
        NameShareCalculatorLogic.parseShareInput(
          mode: ShareInputMode.fraction,
          numeratorText: '5',
          denominatorText: '4',
        ).isValid,
        isFalse,
      );
      expect(
        NameShareCalculatorLogic.parseShareInput(
          mode: ShareInputMode.namjari1000,
          namjariText: '1200',
        ).isValid,
        isFalse,
      );
      expect(
        NameShareCalculatorLogic.parseShareInput(
          mode: ShareInputMode.anaGonda,
          ana: 16,
          gonda: 5,
        ).isValid,
        isFalse,
      );
    });

    test('Summarizes 16-ana exact, remaining, and excess share balances', () {
      const exactEntries = [
        NameShareEntry(id: '1', name: 'ক', shareFraction: 0.5),
        NameShareEntry(id: '2', name: 'খ', shareFraction: 0.5),
      ];
      final exactAudit = NameShareCalculatorLogic.summarizeShares(exactEntries);
      expect(exactAudit.isExact16Ana, isTrue);
      expect(exactAudit.hasExcess, isFalse);
      expect(exactAudit.remainingShare, closeTo(0.0, 1e-6));

      const partialEntries = [
        NameShareEntry(id: '1', name: 'ক', shareFraction: 0.625),
      ];
      final partialAudit = NameShareCalculatorLogic.summarizeShares(partialEntries);
      expect(partialAudit.isExact16Ana, isFalse);
      expect(partialAudit.remainingShare, closeTo(0.375, 1e-6));

      const excessEntries = [
        NameShareEntry(id: '1', name: 'ক', shareFraction: 0.75),
        NameShareEntry(id: '2', name: 'খ', shareFraction: 0.50),
      ];
      final excessAudit = NameShareCalculatorLogic.summarizeShares(excessEntries);
      expect(excessAudit.hasExcess, isTrue);
      expect(excessAudit.excessShare, closeTo(0.25, 1e-6));
    });

    test('Distributes equal shares among 3 owners with exact sum conservation', () {
      final equal3 = NameShareCalculatorLogic.distributeEqually(
        ownerNames: ['ক', 'খ', 'গ'],
        totalFraction: 1.0,
      );
      expect(equal3.length, 3);
      final sum = equal3.fold<double>(0.0, (s, e) => s + e.shareFraction);
      expect(sum, closeTo(1.0, 1e-6));
    });

    test('Filters entries by name or guardian name', () {
      const list = [
        NameShareEntry(id: '1', name: 'মো: করিম উদ্দিন', guardianName: 'রহিম', shareFraction: 0.5),
        NameShareEntry(id: '2', name: 'মোছা: ফাতেমা বেগম', guardianName: 'জব্বার', shareFraction: 0.5),
      ];
      expect(NameShareCalculatorLogic.filterEntries(list, 'ফাতেমা').length, 1);
      expect(NameShareCalculatorLogic.filterEntries(list, 'রহিম').length, 1);
      expect(NameShareCalculatorLogic.filterEntries(list, '').length, 2);
    });
  });

  group('NameShareCalculatorScreen Widget & Registry Tests', () {
    test('ToolsData registers Tool #25 Name Share Calculator', () {
      expect(ToolsData.allTools.length, 25);
      final t25 = ToolsData.allTools.last;
      expect(t25.id, 'tool_25_name_share');
      expect(t25.number, 25);
      expect(t25.title, 'নামের অংশ ক্যালকুলেটর');
    });

    testWidgets('Renders audit deck, filters by owner name, and opens equal split dialog', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const MaterialApp(home: NameShareCalculatorScreen()));
      await tester.pumpAndSettle();

      expect(find.text('নামের অংশ ক্যালকুলেটর'), findsOneWidget);
      expect(find.text('১৬ আনা পূর্ণ সঠিক'), findsOneWidget);
      expect(find.text('মো: আব্দুর রহমান'), findsOneWidget);
      expect(find.text('মোছা: আয়েশা বেগম'), findsOneWidget);

      // Filter by owner name
      await tester.enterText(find.byWidgetPredicate((w) => w is TextField && (w.decoration?.hintText?.contains('খুঁজুন') ?? false)), 'সাইফুল');
      await tester.pumpAndSettle();

      expect(find.text('মো: সাইফুল ইসলাম'), findsOneWidget);
      expect(find.text('মো: আব্দুর রহমান'), findsNothing);

      // Clear search and test equal split dialog
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      await tester.tap(find.text('সম-বণ্টন'));
      await tester.pumpAndSettle();
      expect(find.text('একাধিক নামে সম-বণ্টন'), findsOneWidget);
      await tester.tap(find.text('সম-বণ্টন করুন'));
      await tester.pumpAndSettle();

      expect(find.text('ক. করিম'), findsOneWidget);
      expect(find.text('খ. রহিম'), findsOneWidget);
    });
  });
}
