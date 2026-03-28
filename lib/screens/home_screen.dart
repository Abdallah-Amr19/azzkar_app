// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import '../models/prayer_model.dart';
import '../services/prayer_service.dart';
import '../utils/app_theme.dart';
import '../data/azkar_data.dart';
import 'azkar_screen.dart';
import 'prayers_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String? initialRoute;
  const HomeScreen({super.key, this.initialRoute});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  PrayersDay? _prayers;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadPrayers();
    _handleInitialRoute();
  }

  void _handleInitialRoute() {
    if (widget.initialRoute == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (widget.initialRoute) {
        case 'morning_azkar':
          _navigateToAzkar('morning');
          break;
        case 'evening_azkar':
          _navigateToAzkar('evening');
          break;
        case 'after_prayer':
          _navigateToAzkar('after_prayer');
          break;
        case 'qiyam':
          setState(() => _currentIndex = 1);
          break;
      }
    });
  }

  void _navigateToAzkar(String categoryId) {
    final categories = AzkarData.getCategories();
    final category = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => categories.first,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AzkarDetailScreen(category: category),
      ),
    );
  }

  Future<void> _loadPrayers() async {
    final prayerService = PrayerService();
    await prayerService.loadSavedLocation();
    if (!prayerService.hasLocation) {
      prayerService.setDefaultEgyptLocation();
    }
    final prayers = prayerService.calculatePrayerTimes();
    if (mounted) {
      setState(() => _prayers = prayers);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(prayers: _prayers, pulseController: _pulseController),
          const PrayersScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgMid,
        border: const Border(
          top: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Text('🏠', style: TextStyle(fontSize: 22)),
            activeIcon: Text('🏠', style: TextStyle(fontSize: 24)),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Text('🕌', style: TextStyle(fontSize: 22)),
            activeIcon: Text('🕌', style: TextStyle(fontSize: 24)),
            label: 'الصلوات',
          ),
          BottomNavigationBarItem(
            icon: Text('⚙️', style: TextStyle(fontSize: 22)),
            activeIcon: Text('⚙️', style: TextStyle(fontSize: 24)),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
// Home Tab Content
// ═══════════════════════════════════════
class _HomeTab extends StatefulWidget {
  final PrayersDay? prayers;
  final AnimationController pulseController;

  const _HomeTab({required this.prayers, required this.pulseController});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  late Stream<DateTime> _clockStream;

  @override
  void initState() {
    super.initState();
    _clockStream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildDateTimeCard()),
          if (widget.prayers != null)
            SliverToBoxAdapter(child: _buildNextPrayerCard()),
          SliverToBoxAdapter(child: _buildAzkarGrid()),
          SliverToBoxAdapter(child: _buildAllPrayersRow()),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          Text(
            '✦  بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ  ✦',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.goldDim,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 800.ms),
          const SizedBox(height: 6),
          Text(
            'أذكاري',
            style: Theme.of(context).textTheme.displayLarge,
          ).animate().fadeIn(delay: 200.ms, duration: 800.ms),
          Text(
            'حصنك اليومي بذكر الله',
            style: Theme.of(context).textTheme.bodySmall,
          ).animate().fadeIn(delay: 400.ms, duration: 800.ms),
          const SizedBox(height: 10),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, AppTheme.goldDim, Colors.transparent],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: AppDecorations.cardDecoration,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Clock
            StreamBuilder<DateTime>(
              stream: _clockStream,
              builder: (context, snapshot) {
                final now = snapshot.data ?? DateTime.now();
                final timeStr = DateFormat('hh:mm:ss a', 'ar').format(now);
                return Text(
                  timeStr,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.goldLight,
                  ),
                );
              },
            ),
            // Date
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('EEEE، d MMMM yyyy', 'ar').format(DateTime.now()),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  _getHijriDate(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.goldDim,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.3, duration: 600.ms, delay: 300.ms).fadeIn();
  }

  String _getHijriDate() {
    try {
      final hijri = HijriCalendar.now();
      return '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} هـ';
    } catch (e) {
      return '';
    }
  }

  Widget _buildNextPrayerCard() {
    final prayers = widget.prayers!;
    final next = prayers.nextPrayer;
    if (next == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: AppDecorations.prayerCardDecoration,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Text(next.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الصلاة القادمة',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white60,
                    ),
                  ),
                  Text(
                    'صلاة ${next.arabicName}',
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    next.timeFormatted,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            StreamBuilder<DateTime>(
              stream: Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now()),
              builder: (context, _) {
                return AnimatedBuilder(
                  animation: widget.pulseController,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withOpacity(0.1 + widget.pulseController.value * 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        next.timeUntilFormatted,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.3, duration: 600.ms, delay: 500.ms).fadeIn();
  }

  Widget _buildAzkarGrid() {
    final categories = AzkarData.getCategories();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12, right: 4),
            child: Text(
              'الأذكار اليومية',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.goldLight,
              ),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              return _AzkarCategoryCard(
                category: categories[index],
                delay: Duration(milliseconds: 600 + index * 100),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAllPrayersRow() {
    if (widget.prayers == null) return const SizedBox.shrink();

    final prayers = widget.prayers!;
    final allPrayers = prayers.allPrayers;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'مواقيت الصلاة اليوم',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AppTheme.goldLight,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: AppDecorations.cardDecoration,
            child: Column(
              children: allPrayers
                  .map((prayer) => _buildPrayerRow(prayer, allPrayers.last == prayer))
                  .toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 900.ms, duration: 600.ms);
  }

  Widget _buildPrayerRow(PrayerTime prayer, bool isLast) {
    final isNext = widget.prayers?.nextPrayer?.id == prayer.id;
    final isPassed = prayer.isPassed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isNext ? AppTheme.green.withOpacity(0.2) : Colors.transparent,
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppTheme.borderColor),
              ),
        borderRadius: isNext ? BorderRadius.circular(12) : null,
      ),
      child: Row(
        children: [
          Text(prayer.emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'صلاة ${prayer.arabicName}',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                color: isNext
                    ? AppTheme.goldLight
                    : (isPassed ? AppTheme.textMuted : AppTheme.textMain),
                fontWeight: isNext ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          if (isNext)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.greenLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.greenLight.withOpacity(0.4)),
              ),
              child: Text(
                'التالية',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.greenLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Text(
            prayer.timeFormatted,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 18,
              color: isNext ? AppTheme.goldLight : AppTheme.textDim,
              fontWeight: isNext ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════
// Azkar Category Card
// ═══════════════════════════════════════
class _AzkarCategoryCard extends StatelessWidget {
  final dynamic category;
  final Duration delay;

  const _AzkarCategoryCard({required this.category, required this.delay});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AzkarDetailScreen(category: category),
          ),
        );
      },
      child: Container(
        decoration: AppDecorations.glowCardDecoration,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category.emoji,
              style: const TextStyle(fontSize: 36),
            ),
            const Spacer(),
            Text(
              category.title,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.goldLight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              category.subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: category.progress,
              backgroundColor: AppTheme.borderColor,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.gold),
              borderRadius: BorderRadius.circular(4),
              minHeight: 4,
            ),
            const SizedBox(height: 4),
            Text(
              '${category.totalCompleted}/${category.total} ذكر',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 11, color: AppTheme.goldDim),
            ),
          ],
        ),
      ),
    ).animate().scale(
          begin: const Offset(0.9, 0.9),
          duration: 400.ms,
          delay: delay,
        ).fadeIn(delay: delay);
  }
}
