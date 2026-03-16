import 'package:flutter/widgets.dart';

import 'analytics_service.dart';

/// Трекер жизненного цикла приложения для записи сессий.
class SessionTracker with WidgetsBindingObserver {
  static final SessionTracker instance = SessionTracker._();
  SessionTracker._();

  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    await AnalyticsService.startSessionIfNeeded();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Best-effort: окончание сессии при уходе в фон.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      AnalyticsService.endSession();
    }
    if (state == AppLifecycleState.resumed) {
      AnalyticsService.startSessionIfNeeded();
    }
  }
}

