import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Shared helper to load Bengali-compatible fonts for PDF reports
/// so Bangla Unicode text does not render as missing glyphs.
class PdfReportHelper {
  PdfReportHelper._();

  static Future<pw.ThemeData?> loadBengaliTheme() async {
    try {
      final regular = await PdfGoogleFonts.notoSansBengaliRegular();
      final bold = await PdfGoogleFonts.notoSansBengaliBold();
      return pw.ThemeData.withFont(
        base: regular,
        bold: bold,
      );
    } catch (_) {
      // Offline / network unavailable fallback to default theme
      return null;
    }
  }
}
