import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class ParentCalendarTab extends StatefulWidget {
  const ParentCalendarTab({super.key});

  @override
  State<ParentCalendarTab> createState() => _ParentCalendarTabState();
}

class _ParentCalendarTabState extends State<ParentCalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Calendar', style: Theme.of(context).textTheme.headlineLarge),
                ElevatedButton.icon(
                  onPressed: () => _showAddEventDialog(context, provider),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Event'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Calendar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.divider),
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              },
              eventLoader: (day) => provider.getEventsForDate(day),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700),
                selectedDecoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(color: Colors.white),
                markerDecoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
                markerSize: 5,
                markersMaxCount: 3,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: Theme.of(context).textTheme.titleMedium!,
                leftChevronIcon: const Icon(Icons.chevron_left, size: 20, color: AppTheme.textSecondary),
                rightChevronIcon: const Icon(Icons.chevron_right, size: 20, color: AppTheme.textSecondary),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: Theme.of(context).textTheme.bodySmall!,
                weekendStyle: Theme.of(context).textTheme.bodySmall!.copyWith(color: AppTheme.textTertiary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Events for selected day
          Expanded(
            child: _buildEventsList(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, AppProvider provider) {
    final events = provider.getEventsForDate(_selectedDay);

    if (events.isEmpty) {
      return Center(
        child: Text('No events on this day',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textTertiary)),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Text(_formatDate(_selectedDay),
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppTheme.textTertiary, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...events.map((e) => _eventCard(context, provider, e)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _eventCard(BuildContext context, AppProvider provider, CalendarEvent event) {
    final assignedChildren = event.isAllFamily
        ? provider.children
        : provider.children.where((c) => event.assignedChildIds.contains(c.id)).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.accentLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(event.emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title, style: Theme.of(context).textTheme.titleMedium),
                if (event.time != null) ...[
                  const SizedBox(height: 2),
                  Text(event.time!, style: Theme.of(context).textTheme.bodySmall),
                ],
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(event.description, style: Theme.of(context).textTheme.bodySmall),
                ],
                const SizedBox(height: 6),
                // Who it's for
                Row(
                  children: event.isAllFamily
                      ? [
                          const Icon(Icons.people_outline, size: 14, color: AppTheme.textTertiary),
                          const SizedBox(width: 4),
                          Text('All family',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppTheme.textTertiary)),
                        ]
                      : assignedChildren.map((c) => Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: provider.getChildColor(c).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('${c.emoji} ${c.name}',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: provider.getChildColor(c),
                                    fontWeight: FontWeight.w500)),
                          )).toList(),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.textTertiary),
            onPressed: () => provider.deleteEvent(event.id),
          ),
        ],
      ),
    );
  }

  void _showAddEventDialog(BuildContext context, AppProvider provider) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    String selectedEmoji = '📅';
    DateTime selectedDate = _selectedDay;
    final children = provider.children;
    final selectedChildIds = <String>{};
    bool allFamily = true;

    final emojis = ['📅', '🎉', '⚽', '🎓', '🏥', '🎸', '🎨', '🍕', '🎬', '🌟'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Event',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 20),
                // Emoji + title
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        final idx = emojis.indexOf(selectedEmoji);
                        setModalState(() => selectedEmoji = emojis[(idx + 1) % emojis.length]);
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(child: Text(selectedEmoji, style: const TextStyle(fontSize: 26))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(hintText: 'Event title'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(hintText: 'Description (optional)'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setModalState(() => selectedDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.divider),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondary),
                              const SizedBox(width: 8),
                              Text(_formatDate(selectedDate),
                                  style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: timeCtrl,
                        decoration: const InputDecoration(hintText: 'Time (HH:MM)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('For:', style: Theme.of(context).textTheme.titleMedium),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('All family'),
                  value: allFamily,
                  onChanged: (v) => setModalState(() => allFamily = v),
                  activeThumbColor: AppTheme.accent,
                ),
                if (!allFamily)
                  ...children.map((c) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${c.emoji} ${c.name}'),
                        value: selectedChildIds.contains(c.id),
                        onChanged: (v) => setModalState(() {
                          if (v == true) selectedChildIds.add(c.id);
                          else selectedChildIds.remove(c.id);
                        }),
                      )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.isEmpty) return;
                      await provider.addEvent(
                        title: titleCtrl.text,
                        description: descCtrl.text,
                        date: selectedDate,
                        time: timeCtrl.text.isNotEmpty ? timeCtrl.text : null,
                        assignedChildIds: allFamily ? [] : selectedChildIds.toList(),
                        emoji: selectedEmoji,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Add Event'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
