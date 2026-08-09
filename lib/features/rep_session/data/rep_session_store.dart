import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/rep_profile_model.dart';

class RepSessionStore {
  RepSessionStore._();
  static final RepSessionStore instance = RepSessionStore._();

  static const _repsKey = 'rep_session_saved_reps';
  static const _activeRepKey = 'rep_session_active_rep_id';

  Future<List<RepProfileModel>> getSavedReps() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_repsKey) ?? const [];
    final reps = raw
        .map((e) =>
            RepProfileModel.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    reps.sort((a, b) => b.lastLoginAt.compareTo(a.lastLoginAt));
    return reps;
  }

  Future<void> saveRep(RepProfileModel rep) async {
    final prefs = await SharedPreferences.getInstance();
    final reps = await getSavedReps();
    reps.removeWhere((r) => r.id == rep.id);
    reps.add(rep);
    await prefs.setStringList(
      _repsKey,
      reps.map((r) => jsonEncode(r.toJson())).toList(),
    );
  }

  Future<void> removeRep(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final reps = await getSavedReps();
    reps.removeWhere((r) => r.id == id);
    await prefs.setStringList(
      _repsKey,
      reps.map((r) => jsonEncode(r.toJson())).toList(),
    );
    final activeId = prefs.getString(_activeRepKey);
    if (activeId == id) await prefs.remove(_activeRepKey);
  }

  Future<void> setActiveRep(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeRepKey, id);
  }

  Future<String?> getActiveRepId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_activeRepKey);
  }

  /// Resolves the full profile of whoever is currently logged in on this
  /// device, or null if no one has signed in yet (fresh install, or the
  /// active rep was deleted).
  Future<RepProfileModel?> getActiveRep() async {
    final activeId = await getActiveRepId();
    if (activeId == null) return null;
    final reps = await getSavedReps();
    for (final rep in reps) {
      if (rep.id == activeId) return rep;
    }
    return null;
  }

  Future<void> clearActiveRep() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeRepKey);
  }
}
