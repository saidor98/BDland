import 'package:flutter_test/flutter_test.dart';
import 'package:bdland_pro/core/services/mouza_cloud_service.dart';

void main() {
  group('MouzaCloudService Tests', () {
    final service = MouzaCloudService();

    test('8 Divisions exist with proper drive index and metadata', () {
      expect(MouzaCloudService.divisions.length, equals(8));
      expect(MouzaCloudService.divisions[0]['name'], equals('ঢাকা'));
      expect(MouzaCloudService.divisions[0]['drive'], equals(0));
      expect(MouzaCloudService.divisions[1]['name'], equals('চট্টগ্রাম'));
      expect(MouzaCloudService.divisions[1]['drive'], equals(1));
    });

    test('Offline fallback returns districts for Dhaka division', () async {
      final items = await service.fetchDirectory(driveIndex: 0, path: '');
      expect(items, isNotEmpty);
      expect(items.any((item) => item.name == 'Dhaka'), isTrue);
      expect(items.any((item) => item.name == 'Narayanganj'), isTrue);
      expect(items.first.isFolder, isTrue);
    });

    test('Offline fallback returns upazilas for Dhaka district', () async {
      final items = await service.fetchDirectory(driveIndex: 0, path: 'Dhaka');
      expect(items, isNotEmpty);
      expect(items.any((item) => item.name == 'ধানমন্ডি'), isTrue);
      expect(items.any((item) => item.name == 'গুলশান'), isTrue);
    });

    test('Offline fallback returns survey types for Dhanmondi', () async {
      final items = await service.fetchDirectory(driveIndex: 0, path: 'Dhaka/ধানমন্ডি');
      expect(items, isNotEmpty);
      expect(items.any((item) => item.name == 'RS'), isTrue);
      expect(items.any((item) => item.name == 'CITY'), isTrue);
    });

    test('Bundled authentic Mouza maps exist in service catalog', () {
      expect(MouzaCloudService.bundledMaps, isNotEmpty);
      expect(MouzaCloudService.bundledMaps.length, greaterThanOrEqualTo(2));
      expect(MouzaCloudService.bundledMaps.any((m) => m['upazila'] == 'তেজগাঁও'), isTrue);
      expect(MouzaCloudService.bundledMaps.any((m) => m['mouza'] == 'আমিনপুর'), isTrue);
    });

    test('Namjari 1000-scale integer share calculation', () {
      const total = 12.50;
      const part = 6.25;
      final namjariShare = ((part / total) * 1000).round();
      expect(namjariShare, equals(500));
    });

    test('Shoelace Area Calculation for 33,000 sq ft plot', () {
      // Points: (60, 60), (260, 60), (280, 220), (40, 200)
      const points = [
        Offset(60, 60),
        Offset(260, 60),
        Offset(280, 220),
        Offset(40, 200),
      ];

      double sum = 0.0;
      for (int i = 0; i < points.length; i++) {
        final p1 = points[i];
        final p2 = points[(i + 1) % points.length];
        sum += (p1.dx * p2.dy) - (p2.dx * p1.dy);
      }
      final areaSqFt = (sum.abs() / 2.0);
      expect(areaSqFt, closeTo(33000.0, 0.01));

      final decimal = areaSqFt / 435.60;
      expect(decimal, closeTo(75.758, 0.001));

      final katha = areaSqFt / 720.00;
      expect(katha, closeTo(45.83, 0.01));
    });

    test('MouzaCloudItem resolves relative, root-relative, and absolute URLs properly', () {
      final itemRelative = MouzaCloudItem.fromJson({
        'name': 'sheet_1.pdf',
        'link': 'files/sheet_1.pdf',
      }, 0, 'Dhaka');
      expect(itemRelative.downloadUrl, equals('https://free.mouzamap.tech/files/sheet_1.pdf'));

      final itemRootRelative = MouzaCloudItem.fromJson({
        'name': 'sheet_2.pdf',
        'link': '/files/sheet_2.pdf',
      }, 0, 'Dhaka');
      expect(itemRootRelative.downloadUrl, equals('https://free.mouzamap.tech/files/sheet_2.pdf'));

      final itemAbsolute = MouzaCloudItem.fromJson({
        'name': 'external.jpg',
        'link': 'https://custom-host.com/images/external.jpg',
      }, 0, 'Dhaka');
      expect(itemAbsolute.downloadUrl, equals('https://custom-host.com/images/external.jpg'));
    });

    test('MouzaCloudItem round-trips toMap/fromMap and detects PDF vs Image formats', () {
      final pdfItem = MouzaCloudItem(
        name: 'SA_Sheet_101.pdf',
        isFolder: false,
        mimeType: 'application/pdf',
        size: 102400,
        downloadUrl: 'https://free.mouzamap.tech/download.aspx?id=101',
        path: 'Dhaka/Tejgaon',
        driveIndex: 0,
      );
      expect(pdfItem.isPdf, isTrue);
      expect(pdfItem.isImage, isFalse);

      final restored = MouzaCloudItem.fromMap(pdfItem.toMap());
      expect(restored.name, equals('SA_Sheet_101.pdf'));
      expect(restored.downloadUrl, equals(pdfItem.downloadUrl));
      expect(restored.isPdf, isTrue);

      final jpgItem = MouzaCloudItem(name: 'sheet_102.JPG', isFolder: false);
      expect(jpgItem.isImage, isTrue);
      expect(jpgItem.isPdf, isFalse);
    });
  });
}
