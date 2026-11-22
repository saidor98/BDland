import 'dart:convert';

class CalculationHistoryItem {
  final String id;
  final String title;
  final String category; // 'জ্যামিতি', 'একক রূপান্তর', 'খতিয়ান', 'ফারায়েজ', 'মৌজা স্কেল'
  final DateTime timestamp;
  final String inputSummary;
  final String resultSummary;
  final String fullReportBangla;
  final String? notes;

  const CalculationHistoryItem({
    required this.id,
    required this.title,
    required this.category,
    required this.timestamp,
    required this.inputSummary,
    required this.resultSummary,
    required this.fullReportBangla,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'timestamp': timestamp.toIso8601String(),
      'inputSummary': inputSummary,
      'resultSummary': resultSummary,
      'fullReportBangla': fullReportBangla,
      'notes': notes,
    };
  }

  factory CalculationHistoryItem.fromMap(Map<String, dynamic> map) {
    return CalculationHistoryItem(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      inputSummary: map['inputSummary'] as String,
      resultSummary: map['resultSummary'] as String,
      fullReportBangla: map['fullReportBangla'] as String,
      notes: map['notes'] as String?,
    );
  }

  String toJson() => json.encode(toMap());

  factory CalculationHistoryItem.fromJson(String source) =>
      CalculationHistoryItem.fromMap(json.decode(source) as Map<String, dynamic>);
}
