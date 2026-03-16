import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../supabase/supabase_client.dart';
import 'analytics_tables.dart';

/// Неблокирующая аналитика: любые ошибки записи гасим, UI не ломаем.
class AnalyticsService {
  AnalyticsService._();

  static const _prefsKeySessionId = 'analytics_session_id';
  static const _prefsKeySessionStartMs = 'analytics_session_start_ms';

  static String? _sessionId;
  static DateTime? _sessionStart;

  static String get sessionId => _sessionId ??= _generateSessionId();

  static Future<void> startSessionIfNeeded() async {
    if (_sessionStart != null) return;
    final prefs = await SharedPreferences.getInstance();
    final cachedSessionId = prefs.getString(_prefsKeySessionId);
    final cachedStartMs = prefs.getInt(_prefsKeySessionStartMs);
    if (cachedSessionId != null && cachedStartMs != null) {
      _sessionId = cachedSessionId;
      _sessionStart = DateTime.fromMillisecondsSinceEpoch(cachedStartMs);
      return;
    }

    _sessionId = _generateSessionId();
    _sessionStart = DateTime.now();
    await prefs.setString(_prefsKeySessionId, _sessionId!);
    await prefs.setInt(_prefsKeySessionStartMs, _sessionStart!.millisecondsSinceEpoch);

    // Пишем старт сессии (best-effort)
    unawaited(_insertSessionStart());
    unawaited(trackEvent('session_started'));
  }

  static Future<void> endSession() async {
    if (_sessionStart == null) return;
    final startedAt = _sessionStart!;
    final endedAt = DateTime.now();
    final durationMs = endedAt.difference(startedAt).inMilliseconds;

    try {
      final user = supabase.auth.currentUser;
      await supabase.from(AnalyticsTables.userSessions).insert({
        AnalyticsTables.colUserId: user?.id,
        AnalyticsTables.colSessionId: sessionId,
        AnalyticsTables.colStartedAt: startedAt.toIso8601String(),
        AnalyticsTables.colEndedAt: endedAt.toIso8601String(),
        AnalyticsTables.colDurationMs: durationMs,
        AnalyticsTables.colPlatform: _platform(),
        AnalyticsTables.colAppVersion: _appVersionSafe(),
      });
    } catch (e) {
      debugPrint('Analytics endSession failed: $e');
    } finally {
      unawaited(trackEvent('session_ended', properties: {'duration_ms': durationMs}));
      _sessionStart = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKeySessionId);
      await prefs.remove(_prefsKeySessionStartMs);
    }
  }

  static Future<void> trackEvent(
    String eventName, {
    String? projectId,
    Map<String, dynamic>? properties,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      await supabase.from(AnalyticsTables.userEvents).insert({
        AnalyticsTables.colUserId: user?.id,
        AnalyticsTables.colProjectId: projectId,
        AnalyticsTables.colSessionId: sessionId,
        AnalyticsTables.colEventName: eventName,
        AnalyticsTables.colEventProps: properties ?? <String, dynamic>{},
        AnalyticsTables.colCreatedAt: DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Analytics trackEvent failed ($eventName): $e');
    }
  }

  static Future<void> _insertSessionStart() async {
    try {
      final user = supabase.auth.currentUser;
      await supabase.from(AnalyticsTables.userSessions).insert({
        AnalyticsTables.colUserId: user?.id,
        AnalyticsTables.colSessionId: sessionId,
        AnalyticsTables.colStartedAt: _sessionStart?.toIso8601String(),
        AnalyticsTables.colPlatform: _platform(),
        AnalyticsTables.colAppVersion: _appVersionSafe(),
      });
    } catch (e) {
      debugPrint('Analytics startSession failed: $e');
    }
  }

  static String _platform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  static String _appVersionSafe() {
    // Пока без package_info_plus: версию можно прокинуть позже.
    return 'unknown';
  }

  static String _generateSessionId() {
    final rand = Random.secure();
    final r = rand.nextInt(1 << 32);
    return '${DateTime.now().millisecondsSinceEpoch}-$r';
  }
}

