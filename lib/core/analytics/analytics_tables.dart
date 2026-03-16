/// Настройки таблиц/полей для аналитики Supabase.
///
/// Важно: схема может отличаться от окружения к окружению.
/// Поэтому в `AnalyticsService` вставки обёрнуты в try/catch и не должны ронять UI.
class AnalyticsTables {
  AnalyticsTables._();

  static const String userEvents = 'user_events';
  static const String userSessions = 'user_sessions_analytics';

  // Common columns (постарайся придерживаться существующей схемы на бэке)
  static const String colUserId = 'user_id';
  static const String colProjectId = 'project_id';
  static const String colSessionId = 'session_id';

  // Events
  static const String colEventName = 'event_name';
  static const String colEventProps = 'properties'; // jsonb
  static const String colCreatedAt = 'created_at';

  // Sessions
  static const String colStartedAt = 'started_at';
  static const String colEndedAt = 'ended_at';
  static const String colDurationMs = 'duration_ms';
  static const String colPlatform = 'platform';
  static const String colAppVersion = 'app_version';
}

