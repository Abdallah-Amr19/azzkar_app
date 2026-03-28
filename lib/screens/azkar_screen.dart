// lib/screens/azkar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/zikr_model.dart';
import '../utils/app_theme.dart';

class AzkarDetailScreen extends StatefulWidget {
  final AzkarCategory category;

  const AzkarDetailScreen({super.key, required this.category});

  @override
  State<AzkarDetailScreen> createState() => _AzkarDetailScreenState();
}

class _AzkarDetailScreenState extends State<AzkarDetailScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _tapController;
  late AnimationController _completeController;
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _completeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    // Reset azkar on open
    widget.category.resetAll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tapController.dispose();
    _completeController.dispose();
    super.dispose();
  }

  void _onTap() {
    final currentZikr = widget.category.azkar[_currentPage];
    if (currentZikr.isCompleted) return;

    HapticFeedback.lightImpact();
    currentZikr.increment();

    _tapController.forward().then((_) => _tapController.reverse());

    setState(() {});

    // Auto-advance to next when completed
    if (currentZikr.isCompleted) {
      HapticFeedback.mediumImpact();
      _completeController.forward().then((_) {
        _completeController.reset();
        // If all completed
        if (widget.category.isFullyCompleted) {
          setState(() => _showCompleted = true);
          return;
        }
        // Go to next
        final nextIndex = _currentPage + 1;
        if (nextIndex < widget.category.azkar.length) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _pageController.animateToPage(
                nextIndex,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showCompleted) return _buildCompletedScreen();

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildProgressBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: widget.category.azkar.length,
                itemBuilder: (context, index) {
                  return _buildZikrCard(widget.category.azkar[index], index);
                },
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppTheme.gold),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '${widget.category.emoji} ${widget.category.title}',
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.goldLight,
                  ),
                ),
                Text(
                  '${_currentPage + 1} / ${widget.category.azkar.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textMuted),
            onPressed: () {
              setState(() {
                widget.category.resetAll();
                _pageController.jumpToPage(0);
                _currentPage = 0;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'تم إكمال ${widget.category.totalCompleted} من ${widget.category.total}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.goldDim),
              ),
              Text(
                '${(widget.category.progress * 100).toInt()}%',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.gold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: widget.category.progress,
            backgroundColor: AppTheme.borderColor,
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.gold),
            borderRadius: BorderRadius.circular(6),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildZikrCard(Zikr zikr, int index) {
    final isCompleted = zikr.isCompleted;

    return GestureDetector(
      onTap: _onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Column(
          children: [
            // Zikr text card
            Expanded(
              child: AnimatedBuilder(
                animation: _tapController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: index == _currentPage
                        ? 1.0 - (_tapController.value * 0.02)
                        : 1.0,
                    child: child,
                  );
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isCompleted
                          ? [
                              AppTheme.green.withOpacity(0.3),
                              AppTheme.bgCard2,
                            ]
                          : [AppTheme.bgCard, AppTheme.bgCard2],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isCompleted
                          ? AppTheme.greenLight.withOpacity(0.5)
                          : AppTheme.borderBright,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isCompleted
                            ? AppTheme.green.withOpacity(0.2)
                            : AppTheme.gold.withOpacity(0.05),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Source badge
                      if (zikr.source != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.goldDim.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppTheme.goldDim.withOpacity(0.4),
                            ),
                          ),
                          child: Text(
                            zikr.source!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.goldDim,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Main text
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            zikr.text,
                            style: const TextStyle(
                              fontFamily: 'ScheherazadeNew',
                              fontSize: 22,
                              color: AppTheme.textMain,
                              height: 2.2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),

                      // Virtue
                      if (zikr.virtue != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.gold.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.gold.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Text('✨', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  zikr.virtue!,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                    color: AppTheme.goldDim,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Counter button
            _buildCounterButton(zikr, index),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterButton(Zikr zikr, int index) {
    final isActive = index == _currentPage;
    final isCompleted = zikr.isCompleted;

    return GestureDetector(
      onTap: isActive ? _onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCompleted
                ? [AppTheme.green, AppTheme.greenLight]
                : [AppTheme.gold.withOpacity(0.8), AppTheme.goldLight],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isCompleted ? AppTheme.green : AppTheme.gold)
                  .withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            if (isCompleted)
              const Text(
                '✓ تم',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Amiri',
                ),
              )
            else ...[
              Text(
                '${zikr.currentCount}',
                style: const TextStyle(
                  color: AppTheme.bgDeep,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Amiri',
                ),
              ),
              Text(
                'من ${zikr.count} — اضغط للعد',
                style: const TextStyle(
                  color: AppTheme.bgDeep,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous
          _NavButton(
            label: '← السابق',
            onTap: _currentPage > 0
                ? () => _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut)
                : null,
          ),

          // Dots
          Row(
            children: List.generate(
              widget.category.azkar.length.clamp(0, 10),
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _currentPage ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _currentPage
                      ? AppTheme.gold
                      : widget.category.azkar[i].isCompleted
                          ? AppTheme.greenLight.withOpacity(0.5)
                          : AppTheme.textMuted,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),

          // Next
          _NavButton(
            label: 'التالي →',
            onTap: _currentPage < widget.category.azkar.length - 1
                ? () => _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedScreen() {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 80))
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'أحسنت!',
              style: Theme.of(context).textTheme.displayLarge,
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 8),
            Text(
              'لقد أتممت ${widget.category.title}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textDim,
              ),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 12),
            Text(
              '«وَالذَّاكِرِينَ اللَّهَ كَثِيرًا وَالذَّاكِرَاتِ\nأَعَدَّ اللَّهُ لَهُم مَّغْفِرَةً وَأَجْرًا عَظِيمًا»',
              style: const TextStyle(
                fontFamily: 'ScheherazadeNew',
                fontSize: 18,
                color: AppTheme.goldDim,
                height: 2.0,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 700.ms),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: AppTheme.bgDeep,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'العودة للرئيسية',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ).animate().fadeIn(delay: 900.ms),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _NavButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: onTap != null
              ? AppTheme.bgCard
              : AppTheme.bgCard.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onTap != null ? AppTheme.borderColor : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: onTap != null ? AppTheme.gold : AppTheme.textMuted,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
