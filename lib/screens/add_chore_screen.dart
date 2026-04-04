import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class AddChoreScreen extends StatefulWidget {
  final Chore? editChore;
  const AddChoreScreen({super.key, this.editChore});

  @override
  State<AddChoreScreen> createState() => _AddChoreScreenState();
}

class _AddChoreScreenState extends State<AddChoreScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();

  ChoreTimeSlot _timeSlot = ChoreTimeSlot.morning;
  RepeatFrequency _repeat = RepeatFrequency.daily;
  final Set<int> _repeatDays = {};
  final Set<String> _selectedChildIds = {};
  String _selectedEmoji = '✅';
  String? _selectedGroupId;

  final List<String> _commonChores = [
    'Make bed', 'Clean room', 'Do dishes', 'Take out trash',
    'Feed pets', 'Do homework', 'Brush teeth', 'Tidy bathroom',
    'Vacuum', 'Laundry', 'Set table', 'Unload dishwasher',
    'Water plants', 'Pick up toys', 'Wipe counters',
  ];

  final List<String> _choreEmojis = [
    '✅', '🛏️', '🧹', '🍽️', '🗑️', '🐾', '📚', '🦷',
    '🚿', '🧺', '🌱', '🧽', '💧', '🧸', '🪣',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editChore != null) {
      final c = widget.editChore!;
      _titleCtrl.text = c.title;
      _descCtrl.text = c.description;
      _timeSlot = c.timeSlot;
      _repeat = c.repeat;
      _repeatDays.addAll(c.repeatDays);
      _selectedChildIds.addAll(c.assignedChildIds);
      _selectedEmoji = c.emoji;
      _timeCtrl.text = c.specificTime ?? '';
      _selectedGroupId = c.choreGroupId;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final children = provider.children;
    final groups = provider.allChoreGroups;
    final isEdit = widget.editChore != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Chore' : 'Add Chore'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(isEdit ? 'Save' : 'Add',
                style: const TextStyle(
                    color: AppTheme.accent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick picks
            if (!isEdit) ...[
              _sectionLabel('Quick Pick'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _commonChores.map((name) => GestureDetector(
                  onTap: () => setState(() => _titleCtrl.text = name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _titleCtrl.text == name
                          ? AppTheme.accentLight
                          : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: _titleCtrl.text == name
                          ? Border.all(color: AppTheme.accent)
                          : null,
                    ),
                    child: Text(name,
                        style: TextStyle(
                            fontSize: 13,
                            color: _titleCtrl.text == name
                                ? AppTheme.accent
                                : AppTheme.textSecondary,
                            fontWeight: _titleCtrl.text == name
                                ? FontWeight.w600
                                : FontWeight.w400)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 20),
            ],

            // Emoji + Title
            _sectionLabel('Chore'),
            const SizedBox(height: 10),
            Row(
              children: [
                // Emoji picker
                GestureDetector(
                  onTap: () => _showEmojiPicker(),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Center(
                        child: Text(_selectedEmoji,
                            style: const TextStyle(fontSize: 28))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(hintText: 'Chore title'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(hintText: 'Description (optional)'),
              maxLines: 2,
            ),

            const SizedBox(height: 24),

            // Time slot
            _sectionLabel('Time of Day'),
            const SizedBox(height: 10),
            _buildTimeSlotPicker(),

            if (_timeSlot == ChoreTimeSlot.specific) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _timeCtrl,
                decoration: const InputDecoration(
                  hintText: 'Specific time (e.g. 8:30 AM)',
                  prefixIcon: Icon(Icons.access_time, size: 18),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Repeat
            _sectionLabel('Repeat'),
            const SizedBox(height: 10),
            _buildRepeatPicker(),

            if (_repeat == RepeatFrequency.custom) ...[
              const SizedBox(height: 12),
              _buildDayPicker(),
            ],

            const SizedBox(height: 24),

            // Assign children
            _sectionLabel('Assign To'),
            const SizedBox(height: 10),
            if (children.isEmpty)
              Text('No children added yet.',
                  style: Theme.of(context).textTheme.bodyMedium)
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: children.map((child) {
                  final selected = _selectedChildIds.contains(child.id);
                  final color = provider.getChildColor(child);
                  return GestureDetector(
                    onTap: () => setState(() {
                      if (selected) _selectedChildIds.remove(child.id);
                      else _selectedChildIds.add(child.id);
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withValues(alpha: 0.15)
                            : AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                        border: selected
                            ? Border.all(color: color, width: 1.5)
                            : Border.all(color: AppTheme.divider),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(child.emoji,
                              style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(child.name,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: selected ? color : AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 24),

            // Group
            _sectionLabel('Chore Group (Optional)'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedGroupId,
                  hint: const Text('No group'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(
                        value: null, child: Text('No group')),
                    ...groups.map((g) => DropdownMenuItem<String?>(
                        value: g.id, child: Text(g.name))),
                  ],
                  onChanged: (v) => setState(() => _selectedGroupId = v),
                ),
              ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(isEdit ? 'Save Changes' : 'Add Chore'),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
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

  Widget _buildTimeSlotPicker() {
    final slots = [
      (ChoreTimeSlot.morning, '☀️', 'Morning'),
      (ChoreTimeSlot.afternoon, '🌤️', 'Afternoon'),
      (ChoreTimeSlot.evening, '🌙', 'Evening'),
      (ChoreTimeSlot.specific, '🕐', 'Specific'),
    ];
    return Row(
      children: slots.map((s) {
        final selected = _timeSlot == s.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _timeSlot = s.$1),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppTheme.accentLight : AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(10),
                border: selected
                    ? Border.all(color: AppTheme.accent)
                    : Border.all(color: AppTheme.divider),
              ),
              child: Column(
                children: [
                  Text(s.$2, style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(s.$3,
                      style: TextStyle(
                          fontSize: 11,
                          color: selected ? AppTheme.accent : AppTheme.textSecondary,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRepeatPicker() {
    final options = [
      (RepeatFrequency.daily, 'Daily'),
      (RepeatFrequency.weekdays, 'Weekdays'),
      (RepeatFrequency.weekends, 'Weekends'),
      (RepeatFrequency.weekly, 'Weekly'),
      (RepeatFrequency.custom, 'Custom'),
      (RepeatFrequency.none, 'Once'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final selected = _repeat == o.$1;
        return GestureDetector(
          onTap: () => setState(() => _repeat = o.$1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? AppTheme.accentLight : AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: selected
                  ? Border.all(color: AppTheme.accent)
                  : Border.all(color: AppTheme.divider),
            ),
            child: Text(o.$2,
                style: TextStyle(
                    fontSize: 13,
                    color: selected ? AppTheme.accent : AppTheme.textSecondary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayPicker() {
    final days = [
      (1, 'M'), (2, 'T'), (3, 'W'), (4, 'T'), (5, 'F'), (6, 'S'), (7, 'S')
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: days.map((d) {
        final selected = _repeatDays.contains(d.$1);
        return GestureDetector(
          onTap: () => setState(() {
            if (selected) _repeatDays.remove(d.$1);
            else _repeatDays.add(d.$1);
          }),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: selected ? AppTheme.accent : AppTheme.surfaceVariant,
              shape: BoxShape.circle,
              border: selected ? null : Border.all(color: AppTheme.divider),
            ),
            child: Center(
              child: Text(d.$2,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppTheme.textSecondary)),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pick an Icon',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _choreEmojis.map((e) => GestureDetector(
                onTap: () {
                  setState(() => _selectedEmoji = e);
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: e == _selectedEmoji
                        ? AppTheme.accentLight
                        : AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: e == _selectedEmoji
                        ? Border.all(color: AppTheme.accent)
                        : null,
                  ),
                  child: Center(child: Text(e, style: const TextStyle(fontSize: 26))),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a chore title')),
      );
      return;
    }
    if (_selectedChildIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please assign at least one child')),
      );
      return;
    }

    final provider = context.read<AppProvider>();

    if (widget.editChore != null) {
      final c = widget.editChore!;
      c.title = _titleCtrl.text.trim();
      c.description = _descCtrl.text;
      c.timeSlotIndex = _timeSlot.index;
      c.specificTime = _timeSlot == ChoreTimeSlot.specific ? _timeCtrl.text : null;
      c.repeatIndex = _repeat.index;
      c.repeatDays = _repeatDays.toList();
      c.assignedChildIds = _selectedChildIds.toList();
      c.emoji = _selectedEmoji;
      c.choreGroupId = _selectedGroupId;
      await provider.updateChore(c);
    } else {
      await provider.addChore(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text,
        timeSlot: _timeSlot,
        specificTime: _timeSlot == ChoreTimeSlot.specific ? _timeCtrl.text : null,
        repeat: _repeat,
        repeatDays: _repeatDays.toList(),
        assignedChildIds: _selectedChildIds.toList(),
        choreGroupId: _selectedGroupId,
        emoji: _selectedEmoji,
      );
    }

    if (mounted) Navigator.pop(context);
  }
}
