import 'package:shared_preferences/shared_preferences.dart';

class PinnedToolsService {
  static const String _pinnedKey = 'bdland_pro_pinned_tools_v1';

  PinnedToolsService._();
  static final PinnedToolsService instance = PinnedToolsService._();

  Future<Set<String>> getPinnedToolIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_pinnedKey) ?? [];
      return list.toSet();
    } catch (_) {
      return {};
    }
  }

  Future<bool> togglePin(String toolId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final set = (prefs.getStringList(_pinnedKey) ?? []).toSet();
      if (set.contains(toolId)) {
        set.remove(toolId);
      } else {
        set.add(toolId);
      }
      return await prefs.setStringList(_pinnedKey, set.toList());
    } catch (_) {
      return false;
    }
  }

  Future<bool> isPinned(String toolId) async {
    final set = await getPinnedToolIds();
    return set.contains(toolId);
  }
}
