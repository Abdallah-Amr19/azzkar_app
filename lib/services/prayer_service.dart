// lib/services/prayer_service.dart
import 'package:adhan/adhan.dart' as adhan;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_model.dart';

class PrayerService {
  static final PrayerService _instance = PrayerService._internal();
  factory PrayerService() => _instance;
  PrayerService._internal();

  static const String _latKey = 'saved_latitude';
  static const String _lngKey = 'saved_longitude';

  double? _latitude;
  double? _longitude;

  // ═══════════════════════════════════════
  // Location
  // ═══════════════════════════════════════
  Future<bool> determineLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
      ),
    );

    _latitude = position.latitude;
    _longitude = position.longitude;

    // Save for offline use
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latKey, _latitude!);
    await prefs.setDouble(_lngKey, _longitude!);

    return true;
  }

  Future<void> loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    _latitude = prefs.getDouble(_latKey);
    _longitude = prefs.getDouble(_lngKey);
  }

  bool get hasLocation => _latitude != null && _longitude != null;

  // ═══════════════════════════════════════
  // Calculate prayer times
  // ═══════════════════════════════════════
  PrayersDay? calculatePrayerTimes({DateTime? date}) {
    if (!hasLocation) return null;

    final targetDate = date ?? DateTime.now();

    final coordinates = adhan.Coordinates(_latitude!, _longitude!);
    final dateComponents = adhan.DateComponents.from(targetDate);

    // Use Egyptian General Authority of Survey calculation method for Egypt
    final params = adhan.CalculationMethod.egyptian.getParameters();
    params.madhab = adhan.Madhab.shafi;

    final prayerTimes = adhan.PrayerTimes(
      coordinates,
      dateComponents,
      params,
    );

    // Calculate last third of night (Qiyam al-Layl)
    final nextDay = targetDate.add(const Duration(days: 1));
    final nextDayComponents = adhan.DateComponents.from(nextDay);
    final nextDayPrayers = adhan.PrayerTimes(
      coordinates,
      nextDayComponents,
      params,
    );

    final nightStart = prayerTimes.maghrib;
    final nightEnd = nextDayPrayers.fajr;
    final nightDuration = nightEnd.difference(nightStart);
    final lastThirdStart = nightStart.add(
      Duration(
        seconds: (nightDuration.inSeconds * 2 / 3).round(),
      ),
    );

    return PrayersDay(
      fajr: PrayerTime(
        id: 'fajr',
        name: 'Fajr',
        arabicName: 'الفجر',
        emoji: '🌄',
        time: prayerTimes.fajr,
      ),
      sunrise: PrayerTime(
        id: 'sunrise',
        name: 'Sunrise',
        arabicName: 'الشروق',
        emoji: '🌅',
        time: prayerTimes.sunrise,
        notificationEnabled: false,
      ),
      dhuhr: PrayerTime(
        id: 'dhuhr',
        name: 'Dhuhr',
        arabicName: 'الظهر',
        emoji: '☀️',
        time: prayerTimes.dhuhr,
      ),
      asr: PrayerTime(
        id: 'asr',
        name: 'Asr',
        arabicName: 'العصر',
        emoji: '🌤️',
        time: prayerTimes.asr,
      ),
      maghrib: PrayerTime(
        id: 'maghrib',
        name: 'Maghrib',
        arabicName: 'المغرب',
        emoji: '🌇',
        time: prayerTimes.maghrib,
      ),
      isha: PrayerTime(
        id: 'isha',
        name: 'Isha',
        arabicName: 'العشاء',
        emoji: '🌙',
        time: prayerTimes.isha,
      ),
      lastThirdOfNight: PrayerTime(
        id: 'qiyam',
        name: 'Qiyam',
        arabicName: 'قيام الليل',
        emoji: '🌌',
        time: lastThirdStart,
      ),
    );
  }

  String get locationName {
    if (!hasLocation) return 'غير محدد';
    return 'خط العرض: ${_latitude!.toStringAsFixed(2)}°، خط الطول: ${_longitude!.toStringAsFixed(2)}°';
  }

  // For Egypt default (Minya)
  void setDefaultEgyptLocation() {
    _latitude = 28.0871; // Minya, Egypt
    _longitude = 30.7618;
  }
}
