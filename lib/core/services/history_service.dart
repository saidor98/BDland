import 'package:shared_preferences/shared_preferences.dart';
import '../../features/history/models/calculation_history_item.dart';

class HistoryService {
  static const String _storageKey = 'bdland_pro_calculation_history_v1';

  HistoryService._();
  static final HistoryService instance = HistoryService._();

  Future<List<CalculationHistoryItem>> getAllItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listJson = prefs.getStringList(_storageKey) ?? [];
      final items = listJson
          .map((jsonStr) => CalculationHistoryItem.fromJson(jsonStr))
          .toList();
      // Sort newest first
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return items;
    } catch (_) {
      return [];
    }
  }

  Future<bool> saveItem(CalculationHistoryItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = await getAllItems();
      // Remove existing item with same id if any, prepend new item
      items.removeWhere((element) => element.id == item.id);
      items.insert(0, item);

      // Limit to last 200 items to keep storage healthy
      final limited = items.take(200).toList();
      final stringList = limited.map((e) => e.toJson()).toList();
      return await prefs.setStringList(_storageKey, stringList);
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final items = await getAllItems();
      items.removeWhere((element) => element.id == id);
      final stringList = items.map((e) => e.toJson()).toList();
      return await prefs.setStringList(_storageKey, stringList);
    } catch (_) {
      return false;
    }
  }

  Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_storageKey);
    } catch (_) {
      return false;
    }
  }
}
