import '../../../core/constants/bangla_numerals.dart';

class AnaGondaShare {
  final int ana; // 0 to 16
  final int gonda; // 0 to 19
  final int kora; // 0 to 3
  final int kranti; // 0 to 2
  final int til; // 0 to 19

  // Constant unit weights in Til
  static const int tilPerKranti = 20;
  static const int tilPerKora = 60; // 3 * 20
  static const int tilPerGonda = 240; // 4 * 60
  static const int tilPerAna = 4800; // 20 * 240
  static const int totalTilIn16Ana = 76800; // 16 * 4800

  const AnaGondaShare({
    this.ana = 0,
    this.gonda = 0,
    this.kora = 0,
    this.kranti = 0,
    this.til = 0,
  });

  /// Total canonical value expressed in Til
  int toTotalTil() {
    return (ana * tilPerAna) +
        (gonda * tilPerGonda) +
        (kora * tilPerKora) +
        (kranti * tilPerKranti) +
        til;
  }

  /// Construct normalized AnaGondaShare from total Til count
  factory AnaGondaShare.fromTotalTil(int totalTil) {
    if (totalTil <= 0) {
      return const AnaGondaShare();
    }

    int remaining = totalTil;

    final ana = remaining ~/ tilPerAna;
    remaining %= tilPerAna;

    final gonda = remaining ~/ tilPerGonda;
    remaining %= tilPerGonda;

    final kora = remaining ~/ tilPerKora;
    remaining %= tilPerKora;

    final kranti = remaining ~/ tilPerKranti;
    remaining %= tilPerKranti;

    final til = remaining;

    return AnaGondaShare(
      ana: ana,
      gonda: gonda,
      kora: kora,
      kranti: kranti,
      til: til,
    );
  }

  /// Convert a decimal fraction (0.0 to 1.0) into AnaGondaShare
  factory AnaGondaShare.fromFraction(double fraction) {
    if (fraction <= 0) return const AnaGondaShare();
    final totalTil = (fraction * totalTilIn16Ana).round();
    return AnaGondaShare.fromTotalTil(totalTil);
  }

  /// Convert to decimal fraction (0.0 to 1.0)
  double toFraction() {
    return toTotalTil() / totalTilIn16Ana;
  }

  /// Convert to percentage (0% to 100%)
  double toPercentage() {
    return toFraction() * 100.0;
  }

  /// Calculate land amount allocated for this share given total plot land
  double calculateLand(double totalLand) {
    return totalLand * toFraction();
  }

  AnaGondaShare operator +(AnaGondaShare other) {
    return AnaGondaShare.fromTotalTil(toTotalTil() + other.toTotalTil());
  }

  AnaGondaShare operator -(AnaGondaShare other) {
    final diff = toTotalTil() - other.toTotalTil();
    return AnaGondaShare.fromTotalTil(diff > 0 ? diff : 0);
  }

  /// Full descriptive text in Bengali numerals
  String toBanglaText() {
    final parts = <String>[];
    if (ana > 0) parts.add('${BanglaNumerals.toBangla(ana)} আনা');
    if (gonda > 0) parts.add('${BanglaNumerals.toBangla(gonda)} গণ্ডা');
    if (kora > 0) parts.add('${BanglaNumerals.toBangla(kora)} কড়া');
    if (kranti > 0) parts.add('${BanglaNumerals.toBangla(kranti)} ক্রান্তি');
    if (til > 0) parts.add('${BanglaNumerals.toBangla(til)} তিল');

    if (parts.isEmpty) return '০ আনা ০ গণ্ডা';
    return parts.join(' ');
  }

  /// Traditional Bengali handwriting symbols representation (যেমন: ৲৶ ২ গণ্ডা । ইত্যাদি)
  String toSymbolRepresentation() {
    final anaSymbol = BanglaNumerals.anaSymbols[ana] ?? BanglaNumerals.toBangla(ana);
    final koraSymbol = BanglaNumerals.koraSymbols[kora] ?? '';
    final krantiSymbol = BanglaNumerals.krantiSymbols[kranti] ?? '';

    final buffer = StringBuffer();
    buffer.write(anaSymbol);
    if (gonda > 0) buffer.write(' ${BanglaNumerals.toBangla(gonda)} গণ্ডা');
    if (koraSymbol.isNotEmpty && kora > 0) buffer.write(' $koraSymbol কড়া');
    if (krantiSymbol.isNotEmpty && kranti > 0) buffer.write(' $krantiSymbol ক্রান্তি');
    if (til > 0) buffer.write(' ${BanglaNumerals.toBangla(til)} তিল');

    return buffer.toString().trim();
  }

  Map<String, dynamic> toMap() {
    return {
      'ana': ana,
      'gonda': gonda,
      'kora': kora,
      'kranti': kranti,
      'til': til,
    };
  }

  factory AnaGondaShare.fromMap(Map<String, dynamic> map) {
    return AnaGondaShare(
      ana: map['ana'] as int? ?? 0,
      gonda: map['gonda'] as int? ?? 0,
      kora: map['kora'] as int? ?? 0,
      kranti: map['kranti'] as int? ?? 0,
      til: map['til'] as int? ?? 0,
    );
  }
}
