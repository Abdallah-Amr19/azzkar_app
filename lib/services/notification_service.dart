// lib/services/notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import '../models/prayer_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const int _morningAzkarId = 1;
  static const int _eveningAzkarId = 2;
  static const int _qiyamId = 3;
  static const int _fajrId = 10;
  static const int _dhuhrId = 11;
  static const int _asrId = 12;
  static const int _maghribId = 13;
  static const int _ishaId = 14;

  static const String _azkarChannelId = 'azkar_channel';
  static const String _prayerChannelId = 'prayer_channel';
  static const String _qiyamChannelId = 'qiyam_channel';

  Future<void> initialize() async {
    if (kIsWeb) return;

    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createAndroidChannels();
  }

  static void _onNotificationTap(NotificationResponse response) {}

  Future<void> _createAndroidChannels() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _azkarChannelId,
        'azkar',
        importance: Importance.high,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _prayerChannelId,
        'prayer',
        importance: Importance.max,
      ),
    );
    await androidPlugin.createNotificationChannel(
      const AndroidNotificationChannel(
        _qiyamChannelId,
        'qiyam',
        importance: Importance.high,
      ),
    );
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

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

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }

    return false;
  }

  Future<void> scheduleMorningAzkar(TimeOfDay time) async {
    if (kIsWeb) return;
    await _notifications.cancel(_morningAzkarId);
    final scheduledTime = _nextTimeOccurrence(time.hour, time.minute);

    await _notifications.zonedSchedule(
      _morningAzkarId,
      'أذكار الصباح',
      'حان وقت أذكار الصباح، ابدأ يومك بذكر الله',
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _azkarChannelId,
          'azkar',
          importance: Importance.high,
          priority: Priority.high,
          color: const Color(0xFFC9A84C),
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
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'morning_azkar',
    );
  }

  Future<void> scheduleEveningAzkar(TimeOfDay time) async {
    if (kIsWeb) return;
    await _notifications.cancel(_eveningAzkarId);
    final scheduledTime = _nextTimeOccurrence(time.hour, time.minute);

    await _notifications.zonedSchedule(
      _eveningAzkarId,
      'أذكار المساء',
      'حان وقت أذكار المساء، اختم يومك بذكر الله',
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _azkarChannelId,
          'azkar',
          importance: Importance.high,
          priority: Priority.high,
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
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'evening_azkar',
    );
  }

  Future<void> schedulePrayerNotification({
    required String prayerId,
    required String prayerName,
    required DateTime prayerTime,
    required int minutesBefore,
  }) async {
    if (kIsWeb) return;
    final notifId = _getPrayerNotifId(prayerId);
    await _notifications.cancel(notifId);

    final notifTime = prayerTime.subtract(Duration(minutes: minutesBefore));
    if (notifTime.isBefore(DateTime.now())) return;

    final tzNotifTime = tz.TZDateTime.from(notifTime, tz.local);
    final title = minutesBefore > 0
        ? 'صلاة $prayerName بعد $minutesBefore دقيقة'
        : 'حان وقت صلاة $prayerName';

    await _notifications.zonedSchedule(
      notifId,
      title,
      'الوقت ${_formatTime(prayerTime)}',
      tzNotifTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _prayerChannelId,
          'prayer',
          importance: Importance.max,
          priority: Priority.max,
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
      payload: 'prayer_$prayerId',
    );
  }

  Future<void> scheduleQiyam(DateTime qiyamTime) async {
    if (kIsWeb) return;
    await _notifications.cancel(_qiyamId);
    if (qiyamTime.isBefore(DateTime.now())) return;

    final tzTime = tz.TZDateTime.from(qiyamTime, tz.local);

    await _notifications.zonedSchedule(
      _qiyamId,
      'وقت قيام الليل',
      'استيقظ وصل ركعتين، تنزل الرحمة في هذا الوقت',
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _qiyamChannelId,
          'qiyam',
          importance: Importance.high,
          priority: Priority.high,
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

  Future<void> scheduleAllReminders({
    required ReminderSettings settings,
    required PrayersDay prayers,
  }) async {
    if (kIsWeb) return;

    await requestPermissions();

    if (settings.morningAzkarEnabled) {
      await scheduleMorningAzkar(settings.morningAzkarTime);
    }
    if (settings.eveningAzkarEnabled) {
      await scheduleEveningAzkar(settings.eveningAzkarTime);
    }

    // Fajr
    if (settings.fajrEnabled) {
      await schedulePrayerNotification(
        prayerId: 'fajr',
        prayerName: prayers.fajr.arabicName,
        prayerTime: prayers.fajr.time,
        minutesBefore: settings.notifyMinutesBefore,
      );
    }
    // Dhuhr
    if (settings.dhuhrEnabled) {
      await schedulePrayerNotification(
        prayerId: 'dhuhr',
        prayerName: prayers.dhuhr.arabicName,
        prayerTime: prayers.dhuhr.time,
        minutesBefore: settings.notifyMinutesBefore,
      );
    }
    // Asr
    if (settings.asrEnabled) {
      await schedulePrayerNotification(
        prayerId: 'asr',
        prayerName: prayers.asr.arabicName,
        prayerTime: prayers.asr.time,
        minutesBefore: settings.notifyMinutesBefore,
      );
    }
    // Maghrib
    if (settings.maghribEnabled) {
      await schedulePrayerNotification(
        prayerId: 'maghrib',
        prayerName: prayers.maghrib.arabicName,
        prayerTime: prayers.maghrib.time,
        minutesBefore: settings.notifyMinutesBefore,
      );
    }
    // Isha
    if (settings.ishaEnabled) {
      await schedulePrayerNotification(
        prayerId: 'isha',
        prayerName: prayers.isha.arabicName,
        prayerTime: prayers.isha.time,
        minutesBefore: settings.notifyMinutesBefore,
      );
    }

    if (settings.qiyamEnabled) {
      await scheduleQiyam(prayers.lastThirdOfNight.time);
    }
  }

  Future<void> cancelAllNotifications() async {
    if (kIsWeb) return;
    await _notifications.cancelAll();
  }

  tz.TZDateTime _nextTimeOccurrence(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
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
