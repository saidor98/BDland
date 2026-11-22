import 'ana_gonda_share.dart';

class KhatianOwner {
  final String id;
  final String name;
  final String khatianNo;
  final AnaGondaShare share;
  final double allocatedDecimal;
  final double allocatedKatha;
  final double allocatedSqFt;
  final double percentage;

  const KhatianOwner({
    required this.id,
    required this.name,
    required this.khatianNo,
    required this.share,
    required this.allocatedDecimal,
    required this.allocatedKatha,
    required this.allocatedSqFt,
    required this.percentage,
  });

  KhatianOwner copyWith({
    String? id,
    String? name,
    String? khatianNo,
    AnaGondaShare? share,
    double? allocatedDecimal,
    double? allocatedKatha,
    double? allocatedSqFt,
    double? percentage,
  }) {
    return KhatianOwner(
      id: id ?? this.id,
      name: name ?? this.name,
      khatianNo: khatianNo ?? this.khatianNo,
      share: share ?? this.share,
      allocatedDecimal: allocatedDecimal ?? this.allocatedDecimal,
      allocatedKatha: allocatedKatha ?? this.allocatedKatha,
      allocatedSqFt: allocatedSqFt ?? this.allocatedSqFt,
      percentage: percentage ?? this.percentage,
    );
  }
}
