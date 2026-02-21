import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/member.dart';
import '../models/training_session.dart';

class StorageService {
  static const String _membersKey = 'members_v1';
  static const String _historyKey = 'session_history_v1';
  static const String _activeSessionKey = 'active_session_temp';

  // Members are saved locally
  static Future<List<Member>> loadMembers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_membersKey);
      
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        return jsonList.map((m) => Member.fromJson(m)).toList();
      }
      return [];
    } catch (e) {
      print('Error loading members: $e');
      return [];
    }
  }

  static Future<void> saveMembers(List<Member> members) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = members.map((m) => m.toJson()).toList();
      await prefs.setString(_membersKey, jsonEncode(jsonList));
    } catch (e) {
      print('Error saving members: $e');
      rethrow;
    }
  }

  // Session history is saved locally
  static Future<List<TrainingSession>> loadSessionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_historyKey);
      
      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        return jsonList.map((s) => TrainingSession.fromJson(s)).toList();
      }
      return [];
    } catch (e) {
      print('Error loading session history: $e');
      return [];
    }
  }

  static Future<void> saveSessionHistory(List<TrainingSession> sessions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = sessions.map((s) => s.toJson()).toList();
      await prefs.setString(_historyKey, jsonEncode(jsonList));
    } catch (e) {
      print('Error saving session history: $e');
      rethrow;
    }
  }

  // Temporary active session storage (for crash recovery)
  static Future<void> saveActiveSession(TrainingSession session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_activeSessionKey, jsonEncode(session.toJson()));
      print('Active session saved temporarily');
    } catch (e) {
      print('Error saving active session: $e');
      rethrow;
    }
  }

  static Future<TrainingSession?> loadActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_activeSessionKey);
      
      if (data != null) {
        return TrainingSession.fromJson(jsonDecode(data));
      }
      return null;
    } catch (e) {
      print('Error loading active session: $e');
      return null;
    }
  }

  static Future<void> clearActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activeSessionKey);
      print('Temporary active session cleared');
    } catch (e) {
      print('Error clearing active session: $e');
    }
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_membersKey);
    await prefs.remove(_historyKey);
    await prefs.remove(_activeSessionKey);
  }
}