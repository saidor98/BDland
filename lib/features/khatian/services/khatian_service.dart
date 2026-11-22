import '../models/ana_gonda_share.dart';
import '../models/khatian_owner.dart';

class KhatianDistributionResult {
  final List<KhatianOwner> owners;
  final double totalPlotDecimal;
  final int totalTil;
  final AnaGondaShare totalShare;
  final bool isExactly16Ana;
  final int remainingTil; // Positive if under 16 ana, negative if over 16 ana
  final AnaGondaShare differenceShare;
  final double remainingDecimal;

  const KhatianDistributionResult({
    required this.owners,
    required this.totalPlotDecimal,
    required this.totalTil,
    required this.totalShare,
    required this.isExactly16Ana,
    required this.remainingTil,
    required this.differenceShare,
    required this.remainingDecimal,
  });
}

class KhatianService {
  KhatianService._();

  static const double sqFtPerDecimal = 435.60;
  static const double sqFtPerKatha = 720.00;

  /// Calculate land distribution for each owner given Dag total land
  static KhatianDistributionResult distributeLand({
    required double totalPlotDecimal,
    required List<KhatianOwner> rawOwners,
  }) {
    int sumTil = 0;
    for (final owner in rawOwners) {
      sumTil += owner.share.toTotalTil();
    }

    final totalShare = AnaGondaShare.fromTotalTil(sumTil);
    final is16Ana = sumTil == AnaGondaShare.totalTilIn16Ana;
    final diffTil = AnaGondaShare.totalTilIn16Ana - sumTil;
    final diffShare = AnaGondaShare.fromTotalTil(diffTil.abs());
    final remainingDec = (diffTil / AnaGondaShare.totalTilIn16Ana) * totalPlotDecimal;

    final updatedOwners = rawOwners.map((owner) {
      final frac = owner.share.toFraction();
      final dec = totalPlotDecimal * frac;
      final sqFt = dec * sqFtPerDecimal;
      final katha = sqFt / sqFtPerKatha;
      final pct = frac * 100.0;

      return owner.copyWith(
        allocatedDecimal: dec,
        allocatedKatha: katha,
        allocatedSqFt: sqFt,
        percentage: pct,
      );
    }).toList();

    return KhatianDistributionResult(
      owners: updatedOwners,
      totalPlotDecimal: totalPlotDecimal,
      totalTil: sumTil,
      totalShare: totalShare,
      isExactly16Ana: is16Ana,
      remainingTil: diffTil,
      differenceShare: diffShare,
      remainingDecimal: remainingDec,
    );
  }
}
