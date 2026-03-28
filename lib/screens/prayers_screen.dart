// lib/screens/prayers_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/prayer_model.dart';
import '../services/prayer_service.dart';
import '../utils/app_theme.dart';

class PrayersScreen extends StatefulWidget {
  const PrayersScreen({super.key});

  @override
  State<PrayersScreen> createState() => _PrayersScreenState();
}

class _PrayersScreenState extends State<PrayersScreen> {
  PrayersDay? _prayers;
  bool _loading = true;
  String _locationName = '';

  @override
  void initState() {
    super.initState();
    _loadPrayers();
  }

  Future<void> _loadPrayers() async {
    final service = PrayerService();
    await service.loadSavedLocation();

    if (!service.hasLocation) {
      service.setDefaultEgyptLocation();
    }

    final prayers = service.calculatePrayerTimes();
    if (mounted) {
      setState(() {
        _prayers = prayers;
        _locationName = service.locationName;
        _loading = false;
      });
    }
  }

  Future<void> _updateLocation() async {
    setState(() => _loading = true);
    final service = PrayerService();
    final success = await service.determineLocation();
    if (!success) {
      service.setDefaultEgyptLocation();
    }
    await _loadPrayers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: const Text('🕌 مواقيت الصلاة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _updateLocation,
            tooltip: 'تحديث الموقع',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.gold),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_prayers == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📍', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 16),
            const Text(
              'يحتاج التطبيق إذن الموقع\nلحساب مواقيت الصلاة',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textDim),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _updateLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: AppTheme.bgDeep,
              ),
              child: const Text('تحديد الموقع'),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Location info
        _buildLocationCard(),
        const SizedBox(height: 16),

        // Next prayer highlight
        if (_prayers!.nextPrayer != null) _buildNextPrayerHighlight(),
        const SizedBox(height: 16),

        // All prayers
        _buildPrayersCard(),
        const SizedBox(height: 16),

        // Qiyam card
        _buildQiyamCard(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLocationCard() {
    return Container(
      decoration: AppDecorations.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('📍', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'موقعك الحالي',
                  style: TextStyle(
                    color: AppTheme.goldLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _locationName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _updateLocation,
            child: const Text(
              'تحديث',
              style: TextStyle(color: AppTheme.gold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextPrayerHighlight() {
    final next = _prayers!.nextPrayer!;
    return Container(
      decoration: AppDecorations.prayerCardDecoration,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Text(next.emoji, style: const TextStyle(fontSize: 50)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'الصلاة القادمة',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
                Text(
                  'صلاة ${next.arabicName}',
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  next.timeFormatted,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  next.timeUntilFormatted,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildPrayersCard() {
    final prayers = [
      _prayers!.fajr,
      _prayers!.sunrise,
      _prayers!.dhuhr,
      _prayers!.asr,
      _prayers!.maghrib,
      _prayers!.isha,
    ];

    return Container(
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'الصلوات الخمس',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.goldLight,
              ),
            ),
          ),
          ...prayers.asMap().entries.map((entry) {
            final i = entry.key;
            final prayer = entry.value;
            final isLast = i == prayers.length - 1;
            final isNext = _prayers!.nextPrayer?.id == prayer.id;
            final isCurrent = _prayers!.currentPrayer?.id == prayer.id;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isNext
                    ? AppTheme.green.withOpacity(0.15)
                    : isCurrent
                        ? AppTheme.gold.withOpacity(0.05)
                        : Colors.transparent,
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppTheme.borderColor),
                      ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isNext
                          ? AppTheme.green.withOpacity(0.3)
                          : AppTheme.bgCard2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        prayer.emoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'صلاة ${prayer.arabicName}',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 18,
                                fontWeight:
                                    isNext ? FontWeight.w700 : FontWeight.w400,
                                color: isNext
                                    ? AppTheme.goldLight
                                    : prayer.isPassed
                                        ? AppTheme.textMuted
                                        : AppTheme.textMain,
                              ),
                            ),
                            if (isNext) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.greenLight.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppTheme.greenLight.withOpacity(0.4),
                                  ),
                                ),
                                child: const Text(
                                  'التالية',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.greenLight,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (isNext)
                          Text(
                            prayer.timeUntilFormatted,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.greenLight,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    prayer.timeFormatted,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isNext ? AppTheme.goldLight : AppTheme.textDim,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 600.ms);
  }

  Widget _buildQiyamCard() {
    final qiyam = _prayers!.lastThirdOfNight;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1040),
            const Color(0xFF0D0820),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6040C0).withOpacity(0.4),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF3020A0).withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Text('🌌', style: TextStyle(fontSize: 30)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'قيام الليل',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'الثلث الأخير من الليل',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '«يَتَنَزَّلُ رَبُّنَا كُلَّ لَيْلَةٍ إِلَى السَّمَاءِ الدُّنْيَا»',
                  style: const TextStyle(
                    fontFamily: 'ScheherazadeNew',
                    fontSize: 13,
                    color: Color(0xFF9080D0),
                  ),
                ),
              ],
            ),
          ),
          Text(
            qiyam.timeFormatted,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFFB0A0E8),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 600.ms);
  }
}
