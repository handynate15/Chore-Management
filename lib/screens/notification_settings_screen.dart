import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Per-child settings — keyed by childId
  final Map<String, _ChildNotifSettings> _settings = {};
  bool _parentSummaryEnabled = true;
  bool _approvalAlertsEnabled = true;
  bool _groupCompleteAlertsEnabled = true;
  bool _permissionGranted = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final provider = context.read<AppProvider>();
    final children = provider.children;

    // Initialize default settings for each child
    for (final child in children) {
      _settings[child.id] = _ChildNotifSettings(
        morningEnabled: true,
        afternoonEnabled: true,
        eveningEnabled: true,
        morningTime: const TimeOfDay(hour: 8, minute: 0),
        afternoonTime: const TimeOfDay(hour: 14, minute: 0),
        eveningTime: const TimeOfDay(hour: 19, minute: 0),
      );
    }

    // Check notification permissions
    if (!kIsWeb) {
      _permissionGranted = await provider.notificationService.requestPermissions();
    } else {
      _permissionGranted = false;
    }

    setState(() => _loading = false);
  }

  Future<void> _saveAndApply() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications are not supported in web preview — they work on real devices.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final provider = context.read<AppProvider>();

    for (final entry in _settings.entries) {
      final s = entry.value;
      await provider.setupRemindersForChild(
        childId: entry.key,
        morningEnabled: s.morningEnabled,
        afternoonEnabled: s.afternoonEnabled,
        eveningEnabled: s.eveningEnabled,
        morningHour: s.morningTime.hour,
        morningMinute: s.morningTime.minute,
        afternoonHour: s.afternoonTime.hour,
        afternoonMinute: s.afternoonTime.minute,
        eveningHour: s.eveningTime.hour,
        eveningMinute: s.eveningTime.minute,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Notification settings saved!'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final children = provider.children;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _saveAndApply,
            child: const Text('Save',
                style: TextStyle(
                    color: AppTheme.accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Permission banner
                  if (!_permissionGranted && !kIsWeb)
                    _permissionBanner(context, provider),

                  if (kIsWeb)
                    _webNotice(context),

                  const SizedBox(height: 8),

                  // Parent alerts section
                  _sectionLabel('Parent Alerts'),
                  const SizedBox(height: 12),
                  _parentAlertsCard(context),

                  const SizedBox(height: 28),

                  // Per-child reminders
                  _sectionLabel('Child Reminders'),
                  const SizedBox(height: 4),
                  Text(
                    'Set daily reminders for each child\'s chore slots.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),

                  if (children.isEmpty)
                    Center(
                      child: Text('No children added yet.',
                          style: Theme.of(context).textTheme.bodyMedium),
                    )
                  else
                    ...children.map((child) {
                      final s = _settings[child.id];
                      if (s == null) return const SizedBox.shrink();
                      return _childReminderCard(context, provider, child, s);
                    }),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveAndApply,
                      icon: const Icon(Icons.notifications_active_outlined,
                          size: 18),
                      label: const Text('Apply All Settings'),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _permissionBanner(BuildContext context, AppProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_off_outlined,
              color: AppTheme.warning, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notifications not enabled',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppTheme.warning)),
                const SizedBox(height: 2),
                Text(
                    'Tap to allow notifications so reminders and alerts work.',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final granted =
                  await provider.notificationService.requestPermissions();
              setState(() => _permissionGranted = granted);
            },
            child: const Text('Enable',
                style: TextStyle(color: AppTheme.warning)),
          ),
        ],
      ),
    );
  }

  Widget _webNotice(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.accentLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppTheme.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Push notifications work on real iOS/Android devices. Configure your preferred times here.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.accent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _parentAlertsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          _toggleRow(
            context,
            icon: Icons.approval_rounded,
            iconColor: AppTheme.warning,
            title: 'Chore Submitted',
            subtitle: 'Alert when a child submits a chore for approval',
            value: _approvalAlertsEnabled,
            onChanged: (v) => setState(() => _approvalAlertsEnabled = v),
          ),
          const Divider(height: 1, color: AppTheme.divider),
          _toggleRow(
            context,
            icon: Icons.task_alt_rounded,
            iconColor: AppTheme.success,
            title: 'Group Completed',
            subtitle: 'Alert when all chores in a group are done',
            value: _groupCompleteAlertsEnabled,
            onChanged: (v) => setState(() => _groupCompleteAlertsEnabled = v),
          ),
          const Divider(height: 1, color: AppTheme.divider),
          _toggleRow(
            context,
            icon: Icons.summarize_rounded,
            iconColor: AppTheme.accent,
            title: 'Daily Summary',
            subtitle: 'Morning overview of today\'s family chores (8:00 AM)',
            value: _parentSummaryEnabled,
            onChanged: (v) => setState(() => _parentSummaryEnabled = v),
          ),
        ],
      ),
    );
  }

  Widget _childReminderCard(BuildContext context, AppProvider provider,
      AppUser child, _ChildNotifSettings s) {
    final color = provider.getChildColor(child);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          // Child header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                      child: Text(child.emoji,
                          style: const TextStyle(fontSize: 19))),
                ),
                const SizedBox(width: 12),
                Text(child.name,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(color: color)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.divider),

          // Morning
          _timeSlotRow(
            context,
            emoji: '☀️',
            label: 'Morning',
            enabled: s.morningEnabled,
            time: s.morningTime,
            color: color,
            onToggle: (v) => setState(() => s.morningEnabled = v),
            onTimeTap: () => _pickTime(context, s.morningTime, (t) {
              setState(() => s.morningTime = t);
            }),
          ),
          const Divider(height: 1, color: AppTheme.divider),

          // Afternoon
          _timeSlotRow(
            context,
            emoji: '🌤️',
            label: 'Afternoon',
            enabled: s.afternoonEnabled,
            time: s.afternoonTime,
            color: color,
            onToggle: (v) => setState(() => s.afternoonEnabled = v),
            onTimeTap: () => _pickTime(context, s.afternoonTime, (t) {
              setState(() => s.afternoonTime = t);
            }),
          ),
          const Divider(height: 1, color: AppTheme.divider),

          // Evening
          _timeSlotRow(
            context,
            emoji: '🌙',
            label: 'Evening',
            enabled: s.eveningEnabled,
            time: s.eveningTime,
            color: color,
            onToggle: (v) => setState(() => s.eveningEnabled = v),
            onTimeTap: () => _pickTime(context, s.eveningTime, (t) {
              setState(() => s.eveningTime = t);
            }),
          ),
        ],
      ),
    );
  }

  Widget _timeSlotRow(
    BuildContext context, {
    required String emoji,
    required String label,
    required bool enabled,
    required TimeOfDay time,
    required Color color,
    required ValueChanged<bool> onToggle,
    required VoidCallback onTimeTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          if (enabled)
            GestureDetector(
              onTap: onTimeTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _formatTime(time),
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ),
            ),
          const SizedBox(width: 10),
          Switch(
            value: enabled,
            onChanged: onToggle,
            activeColor: color,
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accent,
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, TimeOfDay current,
      ValueChanged<TimeOfDay> onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: AppTheme.accent,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) onPicked(picked);
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppTheme.textTertiary,
          letterSpacing: 1.2),
    );
  }
}

class _ChildNotifSettings {
  bool morningEnabled;
  bool afternoonEnabled;
  bool eveningEnabled;
  TimeOfDay morningTime;
  TimeOfDay afternoonTime;
  TimeOfDay eveningTime;

  _ChildNotifSettings({
    required this.morningEnabled,
    required this.afternoonEnabled,
    required this.eveningEnabled,
    required this.morningTime,
    required this.afternoonTime,
    required this.eveningTime,
  });
}
