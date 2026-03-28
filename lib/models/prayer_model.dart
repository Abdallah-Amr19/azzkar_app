import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrayerTime {
  final String id;
  final String name;
  final String arabicName;
  final String emoji;
  final DateTime time;
  final bool notificationEnabled;

  PrayerTime({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.emoji,
    required this.time,
    this.notificationEnabled = true,
  });

  String get timeFormatted {
    return DateFormat('hh:mm a', 'ar').format(time);
  }

  String get timeUntilFormatted {
    final now = DateTime.now();
    final diff = time.difference(now);
    if (diff.isNegative) return 'انتهى';

    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}س ${minutes}د';
    }
    if (minutes > 0) {
      return '${minutes} دقيقة';
    }
    return 'قريباً';
  }

  bool get isPassed => time.isBefore(DateTime.now());
}

class PrayersDay {
  final PrayerTime fajr;
  final PrayerTime sunrise;
  final PrayerTime dhuhr;
  final PrayerTime asr;
  final PrayerTime maghrib;
  final PrayerTime isha;
  final PrayerTime lastThirdOfNight;

  PrayersDay({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.lastThirdOfNight,
  });

  List<PrayerTime> get allPrayers => [fajr, sunrise, dhuhr, asr, maghrib, isha];

  PrayerTime? get nextPrayer {
    final now = DateTime.now();
    for (final prayer in allPrayers) {
      if (prayer.time.isAfter(now)) {
        return prayer;
      }
    }
    return null;
  }

  PrayerTime? get currentPrayer {
    final now = DateTime.now();
    for (final prayer in allPrayers.reversed) {
      if (!prayer.time.isAfter(now)) {
        return prayer;
      }
    }
    return null;
  }
}

class ReminderSettings {
  bool morningAzkarEnabled;
  bool eveningAzkarEnabled;
  bool qiyamEnabled;
  bool fajrEnabled;
  bool dhuhrEnabled;
  bool asrEnabled;
  bool maghribEnabled;
  bool ishaEnabled;
  int notifyMinutesBefore;
  TimeOfDay morningAzkarTime;
  TimeOfDay eveningAzkarTime;

  ReminderSettings({
    this.morningAzkarEnabled = true,
    this.eveningAzkarEnabled = true,
    this.qiyamEnabled = true,
    this.fajrEnabled = true,
    this.dhuhrEnabled = true,
    this.asrEnabled = true,
    this.maghribEnabled = true,
    this.ishaEnabled = true,
    this.notifyMinutesBefore = 30,
    TimeOfDay? morningAzkarTime,
    TimeOfDay? eveningAzkarTime,
  })  : morningAzkarTime =
            morningAzkarTime ?? const TimeOfDay(hour: 6, minute: 0),
        eveningAzkarTime =
            eveningAzkarTime ?? const TimeOfDay(hour: 18, minute: 0);

  Map<String, dynamic> toJson() {
    return {
      'morningAzkarEnabled': morningAzkarEnabled,
      'eveningAzkarEnabled': eveningAzkarEnabled,
      'qiyamEnabled': qiyamEnabled,
      'fajrEnabled': fajrEnabled,
      'dhuhrEnabled': dhuhrEnabled,
      'asrEnabled': asrEnabled,
      'maghribEnabled': maghribEnabled,
      'ishaEnabled': ishaEnabled,
      'notifyMinutesBefore': notifyMinutesBefore,
      'morningAzkarTime': '${morningAzkarTime.hour}:${morningAzkarTime.minute}',
      'eveningAzkarTime': '${eveningAzkarTime.hour}:${eveningAzkarTime.minute}',
    };
  }

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    TimeOfDay parse(String value) {
      final parts = value.split(':');
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }

    return ReminderSettings(
      morningAzkarEnabled: json['morningAzkarEnabled'] ?? true,
      eveningAzkarEnabled: json['eveningAzkarEnabled'] ?? true,
      qiyamEnabled: json['qiyamEnabled'] ?? true,
      fajrEnabled: json['fajrEnabled'] ?? true,
      dhuhrEnabled: json['dhuhrEnabled'] ?? true,
      asrEnabled: json['asrEnabled'] ?? true,
      maghribEnabled: json['maghribEnabled'] ?? true,
      ishaEnabled: json['ishaEnabled'] ?? true,
      notifyMinutesBefore: json['notifyMinutesBefore'] ?? 30,
      morningAzkarTime: json['morningAzkarTime'] != null
          ? parse(json['morningAzkarTime'] as String)
          : const TimeOfDay(hour: 6, minute: 0),
      eveningAzkarTime: json['eveningAzkarTime'] != null
          ? parse(json['eveningAzkarTime'] as String)
          : const TimeOfDay(hour: 18, minute: 0),
    );
  }
}
