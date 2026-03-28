// lib/services/notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/prayer_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Notification IDs
  static const int _morningAzkarId = 1;
  static const int _eveningAzkarId = 2;
  static const int _qiyamId = 3;
  static const int _fajrId = 10;
  static const int _dhuhrId = 11;
  static const int _asrId = 12;
  static const int _maghribId = 13;
  static const int _ishaId = 14;

  // Notification channel IDs
  static const String _azkarChannelId = 'azkar_channel';
  static const String _prayerChannelId = 'prayer_channel';
  static const String _qiyamChannelId = 'qiyam_channel';

  Future<void> initialize() async {
    tz.initializeTimeZones();

    // Android settings
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
    );

    // Create notification channels (Android 8+)
    await _createChannels();
  }

  Future<void> _createChannels() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin == null) return;

    // Azkar channel
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _azkarChannelId,
        'أذكار الصباح والمساء',
        description: 'تذكير بأذكار الصباح والمساء',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color.fromARGB(255, 201, 168, 76),
      ),
    );

    // Prayer channel
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _prayerChannelId,
        'مواقيت الصلاة',
        description: 'تذكير بمواقيت الصلوات الخمس',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color.fromARGB(255, 46, 107, 62),
      ),
    );

    // Qiyam channel
    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _qiyamChannelId,
        'قيام الليل',
        description: 'تذكير بوقت قيام الليل',
        importance: Importance.high,
        playSound: true,
      ),
    );
  }

  // ═══════════════════════════════════════
  // Request permissions
  // ═══════════════════════════════════════
  Future<bool> requestPermissions() async {
    // Android 13+
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    // iOS
    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final granted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  // ═══════════════════════════════════════
  // Schedule Morning Azkar
  // ═══════════════════════════════════════
  Future<void> scheduleMorningAzkar(TimeOfDay time) async {
    await _notifications.cancel(_morningAzkarId);

    final scheduledTime = _nextTimeOccurrence(time.hour, time.minute);

    await _notifications.zonedSchedule(
      _morningAzkarId,
      '🌅 أذكار الصباح',
      'حان وقت أذكار الصباح، ابدأ يومك بذكر الله ✨',
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _azkarChannelId,
          'أذكار الصباح والمساء',
          channelDescription: 'تذكير بأذكار الصباح والمساء',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: const BigTextStyleInformation(
            'حان وقت أذكار الصباح\n\n«أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ للهِ وَالْحَمْدُ للهِ»\n\nاضغط للبدء في الأذكار',
            contentTitle: '🌅 أذكار الصباح',
            summaryText: 'أذكاري',
          ),
          color: const Color.fromARGB(255, 201, 168, 76),
          largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          actions: [
            AndroidNotificationAction(
              'open_morning',
              '📖 فتح الأذكار',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'morning_azkar',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'morning_azkar',
    );
  }

  // ═══════════════════════════════════════
  // Schedule Evening Azkar
  // ═══════════════════════════════════════
  Future<void> scheduleEveningAzkar(TimeOfDay time) async {
    await _notifications.cancel(_eveningAzkarId);

    final scheduledTime = _nextTimeOccurrence(time.hour, time.minute);

    await _notifications.zonedSchedule(
      _eveningAzkarId,
      '🌇 أذكار المساء',
      'حان وقت أذكار المساء، اختم يومك بذكر الله 🌟',
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _azkarChannelId,
          'أذكار الصباح والمساء',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: const BigTextStyleInformation(
            'حان وقت أذكار المساء\n\n«أَمْسَيْنَا وَأَمْسَى الْمُلْكُ للهِ وَالْحَمْدُ للهِ»\n\nاضغط للبدء في الأذكار',
            contentTitle: '🌇 أذكار المساء',
          ),
          color: const Color.fromARGB(255, 255, 140, 0),
          actions: [
            AndroidNotificationAction(
              'open_evening',
              '📖 فتح الأذكار',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          categoryIdentifier: 'evening_azkar',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'evening_azkar',
    );
  }

  // ═══════════════════════════════════════
  // Schedule Prayer Notifications
  // ═══════════════════════════════════════
  Future<void> schedulePrayerNotification({
    required String prayerId,
    required String prayerName,
    required DateTime prayerTime,
    required int minutesBefore,
  }) async {
    final notifId = _getPrayerNotifId(prayerId);
    await _notifications.cancel(notifId);

    final notifTime = prayerTime.subtract(Duration(minutes: minutesBefore));
    if (notifTime.isBefore(DateTime.now())) return;

    final tzNotifTime = tz.TZDateTime.from(notifTime, tz.local);

    final String title;
    final String body;
    final String payload;

    if (minutesBefore > 0) {
      title = '🕌 $prayerName بعد $minutesBefore دقيقة';
      body = 'استعد لصلاة $prayerName، الوقت ${_formatTime(prayerTime)}';
      payload = 'prayer_$prayerId';
    } else {
      title = '🕌 حان وقت صلاة $prayerName';
      body = 'الآن ${_formatTime(prayerTime)} - حي على الصلاة';
      payload = 'prayer_$prayerId';
    }

    await _notifications.zonedSchedule(
      notifId,
      title,
      body,
      tzNotifTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _prayerChannelId,
          'مواقيت الصلاة',
          importance: Importance.max,
          priority: Priority.max,
          fullScreenIntent: true,
          styleInformation: BigTextStyleInformation(
            '$body\n\nاضغط لفتح أذكار ما بعد الصلاة',
          ),
          color: const Color.fromARGB(255, 46, 107, 62),
          actions: [
            const AndroidNotificationAction(
              'open_after_prayer',
              '🤲 أذكار بعد الصلاة',
              showsUserInterface: true,
            ),
          ],
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // ═══════════════════════════════════════
  // Schedule Qiyam Al-Layl
  // ═══════════════════════════════════════
  Future<void> scheduleQiyam(DateTime qiyamTime) async {
    await _notifications.cancel(_qiyamId);

    if (qiyamTime.isBefore(DateTime.now())) return;

    final tzTime = tz.TZDateTime.from(qiyamTime, tz.local);

    await _notifications.zonedSchedule(
      _qiyamId,
      '🌌 وقت قيام الليل',
      'استيقظ وصلِّ ركعتين، تنزّل الرحمة في هذا الوقت 💫',
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _qiyamChannelId,
          'قيام الليل',
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: const BigTextStyleInformation(
            'وقت قيام الليل - الثلث الأخير من الليل\n\n«يَتَنَزَّلُ رَبُّنَا تَبَارَكَ وَتَعَالَى كُلَّ لَيْلَةٍ إِلَى السَّمَاءِ الدُّنْيَا»\n\nاستيقظ وصلِّ وادعُ الله',
            contentTitle: '🌌 وقت قيام الليل',
          ),
          color: const Color.fromARGB(255, 70, 50, 150),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'qiyam',
    );
  }

  // ═══════════════════════════════════════
  // Schedule all reminders for a day
  // ═══════════════════════════════════════
  Future<void> scheduleAllReminders({
    required ReminderSettings settings,
    required PrayersDay prayers,
  }) async {
    // Morning azkar
    if (settings.morningAzkarEnabled) {
      await scheduleMorningAzkar(settings.morningAzkarTime);
    }

    // Evening azkar
    if (settings.eveningAzkarEnabled) {
      await scheduleEveningAzkar(settings.eveningAzkarTime);
    }

    // Prayers
    final prayerMap = {
      'fajr': (prayers.fajr, settings.fajrEnabled),
      'dhuhr': (prayers.dhuhr, settings.dhuhrEnabled),
      'asr': (prayers.asr, settings.asrEnabled),
      'maghrib': (prayers.maghrib, settings.maghribEnabled),
      'isha': (prayers.isha, settings.ishaEnabled),
    };

    for (final entry in prayerMap.entries) {
      final prayer = entry.value.$1;
      final enabled = entry.value.$2;
      if (enabled) {
        await schedulePrayerNotification(
          prayerId: entry.key,
          prayerName: prayer.arabicName,
          prayerTime: prayer.time,
          minutesBefore: settings.notifyMinutesBefore,
        );
      }
    }

    // Qiyam
    if (settings.qiyamEnabled) {
      await scheduleQiyam(prayers.lastThirdOfNight.time);
    }
  }

  // ═══════════════════════════════════════
  // Cancel notifications
  // ═══════════════════════════════════════
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelMorningAzkar() async {
    await _notifications.cancel(_morningAzkarId);
  }

  Future<void> cancelEveningAzkar() async {
    await _notifications.cancel(_eveningAzkarId);
  }

  Future<void> cancelQiyam() async {
    await _notifications.cancel(_qiyamId);
  }

  Future<void> cancelPrayerNotification(String prayerId) async {
    await _notifications.cancel(_getPrayerNotifId(prayerId));
  }

  // ═══════════════════════════════════════
  // Helpers
  // ═══════════════════════════════════════
  tz.TZDateTime _nextTimeOccurrence(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  int _getPrayerNotifId(String prayerId) {
    switch (prayerId) {
      case 'fajr':
        return _fajrId;
      case 'dhuhr':
        return _dhuhrId;
      case 'asr':
        return _asrId;
      case 'maghrib':
        return _maghribId;
      case 'isha':
        return _ishaId;
      default:
        return 99;
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'م' : 'ص';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:$minute $period';
  }
}

// Handle notification tap (foreground)
@pragma('vm:entry-point')
void _onNotificationTap(NotificationResponse response) {
  _handleNotificationPayload(response.payload);
}

// Handle notification tap (background)
@pragma('vm:entry-point')
void _onBackgroundNotificationTap(NotificationResponse response) {
  _handleNotificationPayload(response.payload);
}

void _handleNotificationPayload(String? payload) {
  if (payload == null) return;
  // Navigation is handled in main.dart via notificationAppLaunchDetails
  // or via a global stream
}
