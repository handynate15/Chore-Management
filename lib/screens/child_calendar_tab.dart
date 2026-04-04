import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class ChildCalendarTab extends StatefulWidget {
  final AppUser child;
  final Color childColor;

  const ChildCalendarTab({
    super.key,
    required this.child,
    required this.childColor,
  });

  @override
  State<ChildCalendarTab> createState() => _ChildCalendarTabState();
}

class _ChildCalendarTabState extends State<ChildCalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text('My Calendar',
                style: Theme.of(context)
                    .textTheme
                    .headlineLarge
                    ?.copyWith(color: widget.childColor)),
          ),
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
              eventLoader: (day) =>
                  provider.getEventsForChild(widget.child.id, day),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                todayDecoration: BoxDecoration(
                  color: widget.childColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                    color: widget.childColor, fontWeight: FontWeight.w700),
                selectedDecoration: BoxDecoration(
                  color: widget.childColor,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: const TextStyle(color: Colors.white),
                markerDecoration: BoxDecoration(
                  color: widget.childColor,
                  shape: BoxShape.circle,
                ),
                markerSize: 5,
                markersMaxCount: 3,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: Theme.of(context).textTheme.titleMedium!,
                leftChevronIcon: const Icon(Icons.chevron_left,
                    size: 20, color: AppTheme.textSecondary),
                rightChevronIcon: const Icon(Icons.chevron_right,
                    size: 20, color: AppTheme.textSecondary),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: Theme.of(context).textTheme.bodySmall!,
                weekendStyle: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(color: AppTheme.textTertiary),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildEventsList(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, AppProvider provider) {
    final events =
        provider.getEventsForChild(widget.child.id, _selectedDay);

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📅', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            Text('Nothing scheduled',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        ...events.map((e) => _eventTile(context, e)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _eventTile(BuildContext context, CalendarEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: widget.childColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.childColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Center(child: Text(event.emoji, style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: Theme.of(context).textTheme.titleMedium),
                if (event.time != null)
                  Text(event.time!,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: widget.childColor)),
                if (event.description.isNotEmpty)
                  Text(event.description,
                      style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
