// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prayer_model.dart';
import '../services/notification_service.dart';
import '../services/prayer_service.dart';
import '../utils/app_theme.dart';
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ReminderSettings _settings = ReminderSettings();
  bool _loading = true;
  bool _notifPermission = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('reminder_settings');
    if (json != null) {
      _settings = ReminderSettings.fromJson(jsonDecode(json));
    }

    // Check notification permission
    final notifPlugin = NotificationService();
    _notifPermission = true; // Assume granted if already set up

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'reminder_settings',
      jsonEncode(_settings.toJson()),
    );

    // Re-schedule notifications
    final prayerService = PrayerService();
    await prayerService.loadSavedLocation();
    if (!prayerService.hasLocation) prayerService.setDefaultEgyptLocation();

    final prayers = prayerService.calculatePrayerTimes();
    if (prayers != null) {
      await NotificationService().scheduleAllReminders(
        settings: _settings,
        prayers: prayers,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            '✅ تم حفظ الإعدادات وجدولة التنبيهات',
            textAlign: TextAlign.right,
          ),
          backgroundColor: AppTheme.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Future<void> _requestNotifPermission() async {
    final granted = await NotificationService().requestPermissions();
    setState(() => _notifPermission = granted);
    if (!granted && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.bgCard,
          title: const Text(
            'إذن الإشعارات',
            style: TextStyle(color: AppTheme.goldLight, fontFamily: 'Amiri'),
          ),
          content: const Text(
            'يرجى تفعيل إذن الإشعارات من إعدادات الهاتف حتى يتمكن التطبيق من تذكيرك',
            style: TextStyle(color: AppTheme.textDim),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('حسناً', style: TextStyle(color: AppTheme.gold)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _pickTime(
    BuildContext context, {
    required TimeOfDay current,
    required void Function(TimeOfDay) onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.gold,
              surface: AppTheme.bgCard,
              onSurface: AppTheme.textMain,
            ),
            dialogBackgroundColor: AppTheme.bgCard,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onPicked(TimeOfDay(hour: picked.hour, minute: picked.minute));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: const Text('⚙️ الإعدادات'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Permission card
                if (!_notifPermission) _buildPermissionCard(),
                if (!_notifPermission) const SizedBox(height: 12),

                // Minutes before prayer
                _buildMinutesCard(),
                const SizedBox(height: 16),

                // Morning azkar
                _buildReminderSection(
                  emoji: '🌅',
                  title: 'أذكار الصباح',
                  enabled: _settings.morningAzkarEnabled,
                  time: _settings.morningAzkarTime,
                  onToggle: (val) => setState(() {
                    _settings.morningAzkarEnabled = val;
                  }),
                  onTimeTap: () => _pickTime(
                    context,
                    current: _settings.morningAzkarTime,
                    onPicked: (t) => setState(() {
                      _settings.morningAzkarTime = t;
                    }),
                  ),
                ),
                const SizedBox(height: 12),

                // Evening azkar
                _buildReminderSection(
                  emoji: '🌇',
                  title: 'أذكار المساء',
                  enabled: _settings.eveningAzkarEnabled,
                  time: _settings.eveningAzkarTime,
                  onToggle: (val) => setState(() {
                    _settings.eveningAzkarEnabled = val;
                  }),
                  onTimeTap: () => _pickTime(
                    context,
                    current: _settings.eveningAzkarTime,
                    onPicked: (t) => setState(() {
                      _settings.eveningAzkarTime = t;
                    }),
                  ),
                ),
                const SizedBox(height: 12),

                // Qiyam
                _buildSimpleToggle(
                  emoji: '🌌',
                  title: 'قيام الليل',
                  subtitle: 'تنبيه في الثلث الأخير من الليل',
                  value: _settings.qiyamEnabled,
                  onToggle: (val) =>
                      setState(() => _settings.qiyamEnabled = val),
                ),
                const SizedBox(height: 16),

                // Prayers section
                _buildPrayerToggles(),
                const SizedBox(height: 24),

                // Save button
                ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.gold,
                    foregroundColor: AppTheme.bgDeep,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '💾 حفظ وجدولة التنبيهات',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildPermissionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Text('🔔', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'يحتاج التطبيق إذن الإشعارات للتذكير',
              style: TextStyle(color: Colors.orange),
            ),
          ),
          ElevatedButton(
            onPressed: _requestNotifPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('تفعيل', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildMinutesCard() {
    return Container(
      decoration: AppDecorations.cardDecoration,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⏰ التنبيه قبل الصلاة',
            style: TextStyle(
              color: AppTheme.goldLight,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'تنبيه قبل الصلاة بـ ${_settings.notifyMinutesBefore} دقيقة',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Slider(
            value: _settings.notifyMinutesBefore.toDouble(),
            min: 0,
            max: 30,
            divisions: 6,
            label: '${_settings.notifyMinutesBefore} دقيقة',
            onChanged: (val) => setState(() {
              _settings.notifyMinutesBefore = val.round();
            }),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('عند الأذان',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
              Text('30 دقيقة',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSection({
    required String emoji,
    required String title,
    required bool enabled,
    required TimeOfDay time,
    required void Function(bool) onToggle,
    required VoidCallback onTimeTap,
  }) {
    return Container(
      decoration: AppDecorations.cardDecoration,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppTheme.textMain,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'تنبيه يومي',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: onToggle,
                ),
              ],
            ),
          ),
          if (enabled) ...[
            const Divider(height: 1, color: AppTheme.borderColor),
            InkWell(
              onTap: onTimeTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.access_time,
                        color: AppTheme.gold, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'وقت التنبيه',
                      style: TextStyle(color: AppTheme.textDim),
                    ),
                    const Spacer(),
                    Text(
                      time.format(context),
                      style: const TextStyle(
                        color: AppTheme.goldLight,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_left,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleToggle({
    required String emoji,
    required String title,
    required String subtitle,
    required bool value,
    required void Function(bool) onToggle,
  }) {
    return Container(
      decoration: AppDecorations.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textMain,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Switch(value: value, onChanged: onToggle),
        ],
      ),
    );
  }

  Widget _buildPrayerToggles() {
    final prayers = [
      (
        'fajr',
        '🌄',
        'الفجر',
        _settings.fajrEnabled,
        (v) => _settings.fajrEnabled = v
      ),
      (
        'dhuhr',
        '☀️',
        'الظهر',
        _settings.dhuhrEnabled,
        (v) => _settings.dhuhrEnabled = v
      ),
      (
        'asr',
        '🌤️',
        'العصر',
        _settings.asrEnabled,
        (v) => _settings.asrEnabled = v
      ),
      (
        'maghrib',
        '🌇',
        'المغرب',
        _settings.maghribEnabled,
        (v) => _settings.maghribEnabled = v
      ),
      (
        'isha',
        '🌙',
        'العشاء',
        _settings.ishaEnabled,
        (v) => _settings.ishaEnabled = v
      ),
    ];

    return Container(
      decoration: AppDecorations.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '🕌 تنبيهات الصلوات الخمس',
              style: TextStyle(
                color: AppTheme.goldLight,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ...prayers.asMap().entries.map((entry) {
            final i = entry.key;
            final (id, emoji, name, enabled, setter) = entry.value;
            final isLast = i == prayers.length - 1;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppTheme.borderColor),
                      ),
              ),
              child: Row(
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Text(
                    'صلاة $name',
                    style: const TextStyle(
                      color: AppTheme.textMain,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                    value: enabled,
                    onChanged: (val) => setState(() => setter(val)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
