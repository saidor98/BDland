import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Shared PDF & Print helper.
/// Uses Android/Platform native HTML-to-PDF (`Printing.convertHtml`) for
/// textbook Bengali conjunct shaping (হস্তান্তরিত, সম্পত্তির, স্বাক্ষর etc.)
/// with structured Cadastral Emerald & Brass Gold A4 print formatting.
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
      return null;
    }
  }

  static String escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static String buildCadastralHtmlDocument({
    required String title,
    required String subtitle,
    String badgeText = 'অফিশিয়াল জরিপ প্রতিবেদন',
    required String bodyHtml,
    String leftSignatureLabel = 'জমির মালিক / দলিলগ্রহীতার স্বাক্ষর',
    String rightSignatureLabel = 'সার্ভেয়ার / আমিনের স্বাক্ষর ও সিল',
    String? footerNote,
  }) {
    final escTitle = escapeHtml(title);
    final escSub = escapeHtml(subtitle);
    final escBadge = escapeHtml(badgeText);
    final escLeftSig = escapeHtml(leftSignatureLabel);
    final escRightSig = escapeHtml(rightSignatureLabel);
    final escFooter = escapeHtml(footerNote ?? 'BDLandPro — বাংলাদেশ ক্যাডাস্ট্রাল ও ভূমি পরিমাপ সিস্টেম');

    return '''
<!DOCTYPE html>
<html lang="bn">
<head>
<meta charset="utf-8" />
<style>
  @page {
    size: A4;
    margin: 14mm 15mm;
  }
  * { box-sizing: border-box; }
  body {
    font-family: 'Noto Sans Bengali', 'Hind Siliguri', 'SolaimanLipi', sans-serif;
    color: #131B2E;
    margin: 0;
    padding: 0;
    font-size: 12.5px;
    line-height: 1.65;
    background: #FFFFFF;
  }
  .page-frame {
    border: 2px solid #004126;
    border-radius: 6px;
    padding: 18px 20px;
    min-height: 262mm;
    display: flex;
    flex-direction: column;
    justify-content: space-between;
  }
  .header-banner {
    background: linear-gradient(135deg, #004126 0%, #0F5A38 100%);
    color: #FFFFFF;
    padding: 16px 20px;
    border-radius: 6px;
    border-bottom: 4px solid #FFC64D;
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16px;
  }
  .header-title {
    font-size: 19px;
    font-weight: 700;
    margin: 0 0 3px 0;
    letter-spacing: -0.2px;
  }
  .header-subtitle {
    font-size: 11.5px;
    color: #FFDEA3;
    margin: 0;
  }
  .header-badge {
    background: #FFC64D;
    color: #261900;
    font-size: 10.5px;
    font-weight: 700;
    padding: 5px 10px;
    border-radius: 4px;
    white-space: nowrap;
  }
  .section-title {
    font-size: 13.5px;
    font-weight: 700;
    color: #004126;
    border-left: 4px solid #FFC64D;
    padding-left: 8px;
    margin: 14px 0 8px 0;
  }
  .kpi-grid {
    display: flex;
    gap: 10px;
    margin-bottom: 14px;
  }
  .kpi-box {
    flex: 1;
    background: #F2F3FF;
    border: 1px solid #D2D9F4;
    border-top: 3px solid #004126;
    border-radius: 6px;
    padding: 9px 11px;
  }
  .kpi-label {
    font-size: 10.5px;
    color: #404942;
    margin-bottom: 2px;
  }
  .kpi-val {
    font-size: 14.5px;
    font-weight: 700;
    color: #004126;
  }
  table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 14px;
  }
  th, td {
    border: 1px solid #CBD5E1;
    padding: 7px 10px;
    text-align: left;
    font-size: 12px;
    vertical-align: top;
  }
  th {
    background: #EAEDFF;
    color: #004126;
    font-weight: 700;
  }
  tr:nth-child(even) td {
    background: #FAF8FF;
  }
  .info-panel {
    background: #FAF8FF;
    border: 1px solid #D2D9F4;
    border-radius: 6px;
    padding: 12px 14px;
    margin-bottom: 12px;
  }
  .status-paid {
    display: inline-block;
    background: #DCFCE7;
    color: #166534;
    padding: 3px 10px;
    border-radius: 12px;
    font-weight: 700;
    font-size: 11px;
  }
  .status-due {
    display: inline-block;
    background: #FEE2E2;
    color: #991B1B;
    padding: 3px 10px;
    border-radius: 12px;
    font-weight: 700;
    font-size: 11px;
  }
  .image-box {
    border: 1px solid #CBD5E1;
    border-radius: 6px;
    padding: 8px;
    background: #FAF8FF;
    text-align: center;
    margin-top: 8px;
  }
  .image-box img {
    max-width: 100%;
    max-height: 155mm;
    object-fit: contain;
  }
  .footer-area {
    margin-top: 22px;
    padding-top: 14px;
    border-top: 1px dashed #94A3B8;
  }
  .sig-row {
    display: flex;
    justify-content: space-between;
    margin-top: 26px;
    margin-bottom: 10px;
  }
  .sig-col {
    width: 44%;
    text-align: center;
    border-top: 1px solid #334155;
    padding-top: 5px;
    font-size: 11px;
    font-weight: 600;
    color: #1E293B;
  }
  .footnote {
    text-align: center;
    font-size: 10px;
    color: #64748B;
    margin-top: 6px;
  }
</style>
</head>
<body>
  <div class="page-frame">
    <div>
      <div class="header-banner">
        <div>
          <h1 class="header-title">$escTitle</h1>
          <p class="header-subtitle">$escSub</p>
        </div>
        <div class="header-badge">$escBadge</div>
      </div>
      $bodyHtml
    </div>
    <div class="footer-area">
      <div class="sig-row">
        <div class="sig-col">$escLeftSig</div>
        <div class="sig-col">$escRightSig</div>
      </div>
      <div class="footnote">$escFooter</div>
    </div>
  </div>
</body>
</html>
''';
  }

  static String pngBytesToDataUri(Uint8List bytes) {
    return 'data:image/png;base64,${base64Encode(bytes)}';
  }

  static Future<void> printHtmlPdf({
    required String html,
    required String jobName,
    PdfPageFormat pageFormat = PdfPageFormat.a4,
  }) async {
    await Printing.layoutPdf(
      name: jobName,
      format: pageFormat,
      onLayout: (PdfPageFormat format) async {
        return await Printing.convertHtml(
          format: format,
          html: html,
        );
      },
    );
  }
}
