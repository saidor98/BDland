import 'package:intl/intl.dart';
import '../constants/bangla_numerals.dart';

class BanglaFormatter {
  BanglaFormatter._();

  /// Format a double number to a string with specified decimals, in Bengali numerals
  static String formatNumber(double value, {int fractionDigits = 2}) {
    final formatter = NumberFormat.currency(
      locale: 'en_US',
      symbol: '',
      decimalDigits: fractionDigits,
    );
    final formatted = formatter.format(value).trim();
    return BanglaNumerals.toBangla(formatted);
  }

  /// Format currency with Taka symbol (৳) in Bangladeshi formatting
  static String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN', // South Asian grouping (lakhs, crores)
      symbol: '৳ ',
      decimalDigits: 2,
    );
    final formatted = formatter.format(amount);
    return BanglaNumerals.toBangla(formatted);
  }

  /// Format land area breakdown into: বিঘা - কাঠা - ছটাক - বর্গফুট
  /// Standard: 1 Bigha = 20 Katha = 14,400 sq ft; 1 Katha = 16 Chhatak = 720 sq ft; 1 Chhatak = 45 sq ft.
  static String formatLandBreakdown(double sqFt) {
    if (sqFt <= 0) return '০ বিঘা ০ কাঠা ০ ছটাক ০ বর্গফুট';

    int bigha = (sqFt / 14400).floor();
    double remAfterBigha = sqFt - (bigha * 14400);

    int katha = (remAfterBigha / 720).floor();
    double remAfterKatha = remAfterBigha - (katha * 720);

    int chhatak = (remAfterKatha / 45).floor();
    double remSqFt = remAfterKatha - (chhatak * 45);

    final parts = <String>[];
    if (bigha > 0) parts.add('${BanglaNumerals.toBangla(bigha)} বিঘা');
    if (katha > 0 || bigha > 0) parts.add('${BanglaNumerals.toBangla(katha)} কাঠা');
    if (chhatak > 0 || katha > 0 || bigha > 0) parts.add('${BanglaNumerals.toBangla(chhatak)} ছটাক');
    parts.add('${formatNumber(remSqFt, fractionDigits: 2)} বর্গফুট');

    return parts.join(' ');
  }

  /// Format percentage to Bengali with % symbol
  static String formatPercentage(double percent) {
    return '${formatNumber(percent, fractionDigits: 2)}%';
  }

  /// Format DateTime to Bengali readable format
  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('dd MMM yyyy, hh:mm a');
    final formatted = formatter.format(dateTime);
    return BanglaNumerals.toBangla(formatted);
  }
}
