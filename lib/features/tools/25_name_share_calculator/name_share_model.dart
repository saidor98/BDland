import '../../../core/constants/bangla_numerals.dart';
import '../../khatian/models/ana_gonda_share.dart';

enum ShareInputMode {
  decimal,
  namjari1000,
  fraction,
  anaGonda,
}

class NameShareEntry {
  final String id;
  final String name;
  final String guardianName;
  final String roleLabel;
  final String dagNo;
  final double shareFraction; // Valid range: 0.0 < shareFraction <= 1.0
  final ShareInputMode inputMode;
  final String inputSummaryText;

  const NameShareEntry({
    required this.id,
    required this.name,
    this.guardianName = '',
    this.roleLabel = 'খতিয়ান মালিক',
    this.dagNo = '',
    required this.shareFraction,
    this.inputMode = ShareInputMode.decimal,
    this.inputSummaryText = '',
  });

  AnaGondaShare get anaGonda => AnaGondaShare.fromFraction(shareFraction);

  int get namjari1000 => (shareFraction * 1000.0).round();

  double get percentage => shareFraction * 100.0;

  double landDecimal(double totalLandDec) => totalLandDec * shareFraction;

  double landSqFt(double totalLandDec) => landDecimal(totalLandDec) * 435.60;

  double landKatha(double totalLandDec) => landSqFt(totalLandDec) / 720.00;

  double landBigha(double totalLandDec) => landDecimal(totalLandDec) / 33.0;

  NameShareEntry copyWith({
    String? id,
    String? name,
    String? guardianName,
    String? roleLabel,
    String? dagNo,
    double? shareFraction,
    ShareInputMode? inputMode,
    String? inputSummaryText,
  }) {
    return NameShareEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      guardianName: guardianName ?? this.guardianName,
      roleLabel: roleLabel ?? this.roleLabel,
      dagNo: dagNo ?? this.dagNo,
      shareFraction: shareFraction ?? this.shareFraction,
      inputMode: inputMode ?? this.inputMode,
      inputSummaryText: inputSummaryText ?? this.inputSummaryText,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'guardianName': guardianName,
        'roleLabel': roleLabel,
        'dagNo': dagNo,
        'shareFraction': shareFraction,
        'inputMode': inputMode.name,
        'inputSummaryText': inputSummaryText,
      };

  factory NameShareEntry.fromMap(Map<String, dynamic> map) {
    final modeStr = map['inputMode'] as String? ?? 'decimal';
    final mode = ShareInputMode.values.firstWhere(
      (m) => m.name == modeStr,
      orElse: () => ShareInputMode.decimal,
    );
    return NameShareEntry(
      id: map['id'] as String? ?? 'entry_${DateTime.now().millisecondsSinceEpoch}',
      name: map['name'] as String? ?? 'মালিক',
      guardianName: map['guardianName'] as String? ?? '',
      roleLabel: map['roleLabel'] as String? ?? 'খতিয়ান মালিক',
      dagNo: map['dagNo'] as String? ?? '',
      shareFraction: ((map['shareFraction'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0),
      inputMode: mode,
      inputSummaryText: map['inputSummaryText'] as String? ?? '',
    );
  }
}

class ShareAuditSummary {
  final double totalShare;
  final double remainingShare;
  final double excessShare;
  final int totalNamjari1000;
  final bool isExact16Ana;
  final bool hasExcess;

  const ShareAuditSummary({
    required this.totalShare,
    required this.remainingShare,
    required this.excessShare,
    required this.totalNamjari1000,
    required this.isExact16Ana,
    required this.hasExcess,
  });
}

class ParsedShareResult {
  final double? shareFraction;
  final String? errorBangla;
  final String normalizedLabel;

  const ParsedShareResult({
    this.shareFraction,
    this.errorBangla,
    this.normalizedLabel = '',
  });

  bool get isValid => shareFraction != null && errorBangla == null;
}

class NameShareCalculatorLogic {
  NameShareCalculatorLogic._();

  static const double _tolerance = 0.0005;

  static ParsedShareResult parseShareInput({
    required ShareInputMode mode,
    String decimalText = '',
    String namjariText = '',
    String numeratorText = '',
    String denominatorText = '',
    int ana = 0,
    int gonda = 0,
    int kora = 0,
    int kranti = 0,
    int til = 0,
  }) {
    double raw = 0.0;
    String label = '';

    switch (mode) {
      case ShareInputMode.decimal:
        final val = double.tryParse(decimalText.trim());
        if (val == null || !val.isFinite || val <= 0) {
          return const ParsedShareResult(errorBangla: 'সঠিক দশমিক অংশ দিন (০-এর বেশি, সর্বোচ্চ ১.০০০০)।');
        }
        raw = val;
        label = val.toStringAsFixed(4);
      case ShareInputMode.namjari1000:
        final val = double.tryParse(namjariText.trim());
        if (val == null || !val.isFinite || val <= 0) {
          return const ParsedShareResult(errorBangla: 'নামজারি স্কেলে ১ থেকে ১০০০ এর মধ্যে মান দিন।');
        }
        if (val > 1000.0) {
          return const ParsedShareResult(errorBangla: 'নামজারি অংশ ১০০০-এর বেশি হতে পারে না।');
        }
        raw = val / 1000.0;
        label = '${BanglaNumerals.toBangla(val.round())}/১০০০';
      case ShareInputMode.fraction:
        final numVal = double.tryParse(numeratorText.trim());
        final denVal = double.tryParse(denominatorText.trim());
        if (numVal == null || denVal == null || !numVal.isFinite || !denVal.isFinite) {
          return const ParsedShareResult(errorBangla: 'ভগ্নাংশের লব ও হর উভয়ই সংখ্যায় লিখুন।');
        }
        if (denVal <= 0) {
          return const ParsedShareResult(errorBangla: 'ভগ্নাংশের হর শূন্য (০) হতে পারে না।');
        }
        if (numVal <= 0) {
          return const ParsedShareResult(errorBangla: 'ভগ্নাংশের লব অবশ্যই শূন্যের চেয়ে বড় হতে হবে।');
        }
        if (numVal > denVal) {
          return const ParsedShareResult(errorBangla: 'লব কখনোই হরের চেয়ে বড় (১.০-এর বেশি) হতে পারে না।');
        }
        raw = numVal / denVal;
        label = '${numeratorText.trim()}/${denominatorText.trim()}';
      case ShareInputMode.anaGonda:
        if (ana < 0 || gonda < 0 || kora < 0 || kranti < 0 || til < 0) {
          return const ParsedShareResult(errorBangla: 'আনা-গণ্ডার মান ঋণাত্মক হতে পারে না।');
        }
        if (gonda >= 20 || kora >= 4 || kranti >= 3 || til >= 20 || ana > 16) {
          return const ParsedShareResult(
            errorBangla: 'প্রথাগত সীমা: আনা ≤১৬, গণ্ডা ≤১৯, কড়া ≤৩, ক্রান্তি ≤২, তিল ≤১৯।',
          );
        }
        final share = AnaGondaShare(ana: ana, gonda: gonda, kora: kora, kranti: kranti, til: til);
        final totalTil = share.toTotalTil();
        if (totalTil <= 0) {
          return const ParsedShareResult(errorBangla: 'কমপক্ষে ১ তিল বা তার বেশি অংশ দিন।');
        }
        if (totalTil > AnaGondaShare.totalTilIn16Ana) {
          return const ParsedShareResult(errorBangla: 'মোট হিস্যা ১৬ আনার (৭৬,৮০০ তিল) বেশি হতে পারে না।');
        }
        raw = share.toFraction();
        label = share.toBanglaText();
    }

    if (!raw.isFinite || raw <= 0 || raw > 1.00001) {
      return const ParsedShareResult(errorBangla: 'অংশের মান অবশ্যই ১.০০০০ (১৬ আনা)-এর মধ্যে হতে হবে।');
    }

    return ParsedShareResult(
      shareFraction: raw.clamp(0.0, 1.0),
      normalizedLabel: label,
    );
  }

  static ShareAuditSummary summarizeShares(List<NameShareEntry> entries) {
    final total = entries.fold<double>(0.0, (sum, e) => sum + e.shareFraction);
    final hasExcess = total > (1.0 + _tolerance);
    final isExact = (total - 1.0).abs() <= _tolerance;
    final remaining = hasExcess ? 0.0 : (1.0 - total).clamp(0.0, 1.0);
    final excess = hasExcess ? (total - 1.0) : 0.0;
    final total1000 = (total * 1000.0).round();

    return ShareAuditSummary(
      totalShare: total,
      remainingShare: remaining,
      excessShare: excess,
      totalNamjari1000: total1000,
      isExact16Ana: isExact,
      hasExcess: hasExcess,
    );
  }

  static List<NameShareEntry> distributeEqually({
    required List<String> ownerNames,
    double totalFraction = 1.0,
    String roleLabel = 'সমান অংশীদার',
  }) {
    final cleaned = ownerNames.map((n) => n.trim()).where((n) => n.isNotEmpty).toList();
    if (cleaned.isEmpty || totalFraction <= 0) return const [];

    final count = cleaned.length;
    final clampedTotal = totalFraction.clamp(0.0001, 1.0);
    final perShare = double.parse((clampedTotal / count).toStringAsFixed(6));
    double accumulated = 0.0;

    return List<NameShareEntry>.generate(count, (idx) {
      final isLast = idx == count - 1;
      final share = isLast
          ? (clampedTotal - accumulated).clamp(0.0, 1.0)
          : perShare;
      accumulated += share;

      return NameShareEntry(
        id: 'eq_${DateTime.now().microsecondsSinceEpoch}_$idx',
        name: cleaned[idx],
        roleLabel: roleLabel,
        shareFraction: share,
        inputMode: ShareInputMode.fraction,
        inputSummaryText: '১/${BanglaNumerals.toBangla(count)} অংশ',
      );
    });
  }

  static List<NameShareEntry> filterEntries(List<NameShareEntry> entries, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return entries;
    return entries.where((e) {
      return e.name.toLowerCase().contains(q) ||
          e.guardianName.toLowerCase().contains(q) ||
          e.roleLabel.toLowerCase().contains(q) ||
          e.dagNo.toLowerCase().contains(q);
    }).toList();
  }
}
