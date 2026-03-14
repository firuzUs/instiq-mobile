# InstIQ Mobile — настройка и запуск

## 0. Что уже сделано

- **Тема и UI:** тёмная/светлая тема, цвета и типографика по MOBILE_UI_SPEC, Glass Card, градиентные кнопки.
- **Навигация:** go_router, нижние табы (Дашборд, Контент, Тренды, Статистика, Профиль), экран чата AI-стратега.
- **Авторизация:** экран входа/регистрации (Email, Google, Apple), валидация, восстановление пароля. После входа — дашборд.
- **Supabase:** инициализация, профиль, проекты, контент-план (content_calendar), история чата (strategy_chat_messages), онбординг (проверка шагов по БД).
- **Контент-план:** загрузка по неделе, карточки по дням, лайк (is_liked), кнопка «Создать контент» (модалка-заглушка).
- **AI-стратег:** загрузка истории, отправка сообщения, вызов Edge Function `strategy-chat`, сохранение сообщений в БД.
- **Профиль:** выход, отображение email. Подписка и промокоды — заглушки.

## Что осталось доделать

- **Платежи (RevenueCat):** добавить `purchases_flutter`, настроить продукты в App Store Connect / Google Play, после оплаты обновлять `profiles.subscription_tier` и `subscription_expires_at` (webhook или вручную).
- **Пуш-уведомления:** `flutter_local_notifications` + напоминания за X минут до `planned_time` из `content_calendar`; позже FCM для серверных пушей.
- **Онбординг по шагам:** экраны/флоу для шагов 1–4 (профиль, ДНК автора, первый контент, тренды) с сохранением в БД.
- **Генерация контента:** вызов `generate-content` с параметрами (niche, count, type, weekStart, projectId), вставка результатов в `content_calendar`.
- **Тренды:** загрузка из API/таблиц (saved_trends, trend_cores), карточки, сохранение.
- **Мультипроект:** выбор текущего проекта в хедере дашборда (dropdown), обновление `currentProjectIdProvider`.
- **Deep links:** см. ниже.

---

## 1. Сгенерировать платформенные папки

Если в проекте нет папок `android/` и `ios/`, выполни в корне проекта:

```bash
flutter create .
```

Так Flutter создаст нужные файлы для Android и iOS (и при необходимости перезапишет `pubspec.yaml` — зависимости из текущего `pubspec.yaml` нужно будет сохранить).

## 2. Deep Links для OAuth (Google / Apple)

### iOS — `ios/Runner/Info.plist`

Добавь внутри `<dict>`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.instiq.app</string>
    </array>
    <key>CFBundleURLName</key>
    <string>com.instiq.app</string>
  </dict>
</array>
```

### Android — `android/app/src/main/AndroidManifest.xml`

Внутри `<activity>` (обычно `MainActivity`) добавь:

```xml
<intent-filter>
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="com.instiq.app" android:host="callback" />
</intent-filter>
```

В Supabase Dashboard → Authentication → URL Configuration добавь redirect URL: `com.instiq.app://callback`.

## 3. Зависимости

После `flutter create .` проверь, что в `pubspec.yaml` есть все пакеты из текущей версии (supabase_flutter, go_router, flutter_riverpod и т.д.). При необходимости скопируй блок `dependencies` из этого файла.

## 4. Запуск

```bash
flutter pub get
flutter run
```

Для выбора устройства: `flutter run -d chrome` или `flutter run -d <id>` (после `flutter devices`).
