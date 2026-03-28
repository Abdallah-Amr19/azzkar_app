class Zikr {
  final String id;
  final String text;
  final String? source;
  final String? virtue;
  final int count;

  int _completedCount = 0;

  Zikr({
    required this.id,
    required this.text,
    this.source,
    this.virtue,
    this.count = 1,
  });

  bool get isCompleted => _completedCount >= count;
  int get completedCount => _completedCount;
  int get currentCount => _completedCount;

  void increment() {
    if (!isCompleted) {
      _completedCount++;
    }
  }

  void reset() {
    _completedCount = 0;
  }
}

class AzkarCategory {
  final String id;
  final String title;
  final String subtitle;
  final String emoji;
  final String notificationTitle;
  final String notificationBody;
  final List<Zikr> azkar;

  AzkarCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.notificationTitle,
    required this.notificationBody,
    required this.azkar,
  });

  int get total => azkar.length;
  int get totalCompleted => azkar.where((z) => z.isCompleted).length;
  double get progress => total == 0 ? 0.0 : totalCompleted / total;
  bool get isFullyCompleted => totalCompleted == total;

  void resetAll() {
    for (final item in azkar) {
      item.reset();
    }
  }
}
