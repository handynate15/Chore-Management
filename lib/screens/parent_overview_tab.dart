import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class ParentOverviewTab extends StatelessWidget {
  const ParentOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final children = provider.children;
    final rates = provider.getCompletionRatesForToday();
    final today = DateTime.now();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Good ${_greeting()}',
                              style: Theme.of(context).textTheme.bodyMedium),
                          Text(provider.currentUser?.name ?? '',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      _dateChip(context, today),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Summary cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildSummaryRow(context, provider),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
              child: Text("Today's Overview",
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
          ),

          // Children cards
          if (children.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _emptyChildrenCard(context),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final child = children[index];
                    final rate = rates[child.id] ?? 0.0;
                    final instances = provider.getInstancesForChild(child.id, today);
                    return _childCard(context, provider, child, rate, instances);
                  },
                  childCount: children.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, AppProvider provider) {
    final children = provider.children;
    final today = DateTime.now();
    int totalChores = 0, completedChores = 0, pendingApprovals = 0;

    for (final child in children) {
      final instances = provider.getInstancesForChild(child.id, today);
      totalChores += instances.length;
      completedChores +=
          instances.where((i) => i.statusIndex == ChoreStatus.approved.index).length;
    }
    pendingApprovals = provider.getPendingApprovals().length;

    return Row(
      children: [
        Expanded(child: _summaryCard(context, '$completedChores/$totalChores', 'Done Today', Icons.check_circle_outline, AppTheme.success)),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard(context, '$pendingApprovals', 'Awaiting Review', Icons.hourglass_empty_rounded, AppTheme.warning)),
        const SizedBox(width: 12),
        Expanded(child: _summaryCard(context, '${children.length}', 'Kids', Icons.people_outline_rounded, AppTheme.accent)),
      ],
    );
  }

  Widget _summaryCard(BuildContext context, String value, String label,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: color.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _childCard(BuildContext context, AppProvider provider, AppUser child,
      double rate, List<ChoreInstance> instances) {
    final color = provider.getChildColor(child);
    final approved = instances.where((i) => i.statusIndex == ChoreStatus.approved.index).length;
    final submitted = instances.where((i) => i.statusIndex == ChoreStatus.submitted.index).length;
    final pending = instances.where((i) => i.statusIndex == ChoreStatus.pending.index).length;
    final denied = instances.where((i) => i.statusIndex == ChoreStatus.denied.index).length;

    // Group by time slot
    final morningChores = _getSlotInstances(instances, provider, ChoreTimeSlot.morning);
    final afternoonChores = _getSlotInstances(instances, provider, ChoreTimeSlot.afternoon);
    final eveningChores = _getSlotInstances(instances, provider, ChoreTimeSlot.evening);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                      child: Text(child.emoji,
                          style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text('${instances.length} chores today',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                // Progress indicator
                SizedBox(
                  width: 44,
                  height: 44,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: rate,
                        strokeWidth: 3.5,
                        backgroundColor: color.withValues(alpha: 0.15),
                        color: color,
                      ),
                      Center(
                        child: Text(
                          '${(rate * 100).round()}%',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Time slot rows
          if (instances.isNotEmpty) ...[
            const Divider(height: 1, color: AppTheme.divider),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  if (morningChores.isNotEmpty)
                    _slotRow(context, provider, '☀️ Morning', morningChores, color),
                  if (afternoonChores.isNotEmpty)
                    _slotRow(context, provider, '🌤️ Afternoon', afternoonChores, color),
                  if (eveningChores.isNotEmpty)
                    _slotRow(context, provider, '🌙 Evening', eveningChores, color),
                ],
              ),
            ),
          ],

          // Status badges
          if (instances.isNotEmpty) ...[
            const Divider(height: 1, color: AppTheme.divider),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  if (approved > 0) _statusBadge(context, '$approved done', AppTheme.success),
                  if (submitted > 0) ...[
                    const SizedBox(width: 8),
                    _statusBadge(context, '$submitted review', AppTheme.warning),
                  ],
                  if (denied > 0) ...[
                    const SizedBox(width: 8),
                    _statusBadge(context, '$denied redo', AppTheme.error),
                  ],
                  if (pending > 0) ...[
                    const SizedBox(width: 8),
                    _statusBadge(context, '$pending pending', AppTheme.textTertiary),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<ChoreInstance> _getSlotInstances(List<ChoreInstance> instances,
      AppProvider provider, ChoreTimeSlot slot) {
    return instances.where((i) {
      final chore = provider.getChoreById(i.choreId);
      return chore?.timeSlot == slot;
    }).toList();
  }

  Widget _slotRow(BuildContext context, AppProvider provider, String label,
      List<ChoreInstance> instances, Color color) {
    final approved = instances.where((i) => i.statusIndex == ChoreStatus.approved.index).length;
    final total = instances.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.w500)),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? approved / total : 0,
                backgroundColor: color.withValues(alpha: 0.1),
                color: color,
                minHeight: 5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$approved/$total',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  )),
        ],
      ),
    );
  }

  Widget _statusBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _emptyChildrenCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.accentLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text('No kids added yet',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Go to Settings to add your children.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _dateChip(BuildContext context, DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${months[date.month - 1]} ${date.day}',
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: AppTheme.textSecondary),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning,';
    if (hour < 17) return 'Afternoon,';
    return 'Evening,';
  }
}
