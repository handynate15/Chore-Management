import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import 'add_chore_screen.dart';

class ParentChoresTab extends StatefulWidget {
  const ParentChoresTab({super.key});

  @override
  State<ParentChoresTab> createState() => _ParentChoresTabState();
}

class _ParentChoresTabState extends State<ParentChoresTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Chores', style: Theme.of(context).textTheme.headlineLarge),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AddChoreScreen())),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    textStyle: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tab bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppTheme.textPrimary,
                unselectedLabelColor: AppTheme.textTertiary,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [
                  Tab(text: 'Chores'),
                  Tab(text: 'Groups'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ChoresList(provider: provider),
                _GroupsList(provider: provider),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoresList extends StatelessWidget {
  final AppProvider provider;
  const _ChoresList({required this.provider});

  @override
  Widget build(BuildContext context) {
    final chores = provider.allChores;

    if (chores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('✅', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('No chores yet', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Tap + Add to create your first chore',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    // Group by time slot
    final slots = ChoreTimeSlot.values;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        ...slots.expand((slot) {
          final slotChores = chores.where((c) => c.timeSlot == slot).toList();
          if (slotChores.isEmpty) return <Widget>[];
          return [
            _slotHeader(context, slot),
            ...slotChores.map((c) => _choreCard(context, provider, c)),
            const SizedBox(height: 8),
          ];
        }),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _slotHeader(BuildContext context, ChoreTimeSlot slot) {
    final labels = {
      ChoreTimeSlot.morning: '☀️ Morning',
      ChoreTimeSlot.afternoon: '🌤️ Afternoon',
      ChoreTimeSlot.evening: '🌙 Evening',
      ChoreTimeSlot.specific: '🕐 Specific Time',
    };
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(labels[slot] ?? '',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textTertiary,
                letterSpacing: 1.0,
              )),
    );
  }

  Widget _choreCard(BuildContext context, AppProvider provider, Chore chore) {
    final assignedChildren = provider.children
        .where((c) => chore.assignedChildIds.contains(c.id))
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Text(chore.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(chore.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _repeatChip(context, chore.repeat),
                    const SizedBox(width: 8),
                    // Child avatars
                    ...assignedChildren.take(3).map((child) => Container(
                          margin: const EdgeInsets.only(right: 4),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: provider
                                .getChildColor(child)
                                .withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(child.emoji,
                                style: const TextStyle(fontSize: 11)),
                          ),
                        )),
                    if (assignedChildren.length > 3)
                      Text('+${assignedChildren.length - 3}',
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: AppTheme.textTertiary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) async {
              if (val == 'delete') {
                await provider.deleteChore(chore.id);
              } else if (val == 'edit') {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AddChoreScreen(editChore: chore)));
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              const PopupMenuItem(
                  value: 'delete',
                  child:
                      Text('Delete', style: TextStyle(color: AppTheme.error))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _repeatChip(BuildContext context, RepeatFrequency freq) {
    final labels = {
      RepeatFrequency.none: 'Once',
      RepeatFrequency.daily: 'Daily',
      RepeatFrequency.weekdays: 'Weekdays',
      RepeatFrequency.weekends: 'Weekends',
      RepeatFrequency.weekly: 'Weekly',
      RepeatFrequency.custom: 'Custom',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accentLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(labels[freq] ?? '',
          style: const TextStyle(
              fontSize: 10,
              color: AppTheme.accent,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _GroupsList extends StatelessWidget {
  final AppProvider provider;
  const _GroupsList({required this.provider});

  @override
  Widget build(BuildContext context) {
    final groups = provider.allChoreGroups;

    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🗂️', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text('No chore groups yet',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                  'Groups let you bundle chores and unlock rewards when all are completed.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _showAddGroupDialog(context, provider),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Group'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => _showAddGroupDialog(context, provider),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Group'),
          ),
        ),
        ...groups.map((g) => _groupCard(context, provider, g)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _groupCard(BuildContext context, AppProvider provider, ChoreGroup group) {
    final chores = group.choreIds
        .map((id) => provider.getChoreById(id))
        .where((c) => c != null)
        .toList();
    final rewards = provider.allRewards
        .where((r) => r.choreGroupId == group.id)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(group.name,
                    style: Theme.of(context).textTheme.headlineSmall),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    size: 18, color: AppTheme.textTertiary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                onSelected: (val) async {
                  if (val == 'delete') {
                    await provider.deleteChoreGroup(group.id);
                  } else if (val == 'addReward') {
                    _showAddRewardDialog(context, provider, group);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'addReward', child: Text('Add Reward')),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: TextStyle(color: AppTheme.error))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: chores.map((c) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${c!.emoji} ${c.title}',
                    style: Theme.of(context).textTheme.bodySmall),
              );
            }).toList(),
          ),
          if (rewards.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppTheme.divider, height: 1),
            const SizedBox(height: 10),
            Text('Unlocks:',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.textTertiary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: rewards.map((r) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(r.emoji),
                      const SizedBox(width: 5),
                      Text(r.title,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppTheme.warning)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddGroupDialog(BuildContext context, AppProvider provider) {
    final nameCtrl = TextEditingController();
    final chores = provider.allChores;
    final children = provider.children;
    final selectedChoreIds = <String>{};
    final selectedChildIds = <String>{};
    var selectedSlot = ChoreTimeSlot.morning;

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
                Text('New Chore Group',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(hintText: 'Group name (e.g. Morning Routine)'),
                ),
                const SizedBox(height: 16),
                Text('Chores',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...chores.map((c) => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${c.emoji} ${c.title}'),
                      value: selectedChoreIds.contains(c.id),
                      onChanged: (v) => setModalState(() {
                        if (v == true) selectedChoreIds.add(c.id);
                        else selectedChoreIds.remove(c.id);
                      }),
                    )),
                const SizedBox(height: 8),
                Text('Assign to Children',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
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
                      if (nameCtrl.text.isEmpty) return;
                      await provider.addChoreGroup(
                        name: nameCtrl.text,
                        timeSlot: selectedSlot,
                        choreIds: selectedChoreIds.toList(),
                        assignedChildIds: selectedChildIds.toList(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Create Group'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddRewardDialog(
      BuildContext context, AppProvider provider, ChoreGroup group) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedEmoji = '🏆';
    final children = provider.children;
    final selectedChildIds = <String>{};

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
                Text('Add Reward to "${group.name}"',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('This reward unlocks when all group chores are approved.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 20),
                // Emoji picker
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        final emojis = ['🏆', '🎮', '📱', '🎬', '🍕', '🎉', '⭐', '🌟'];
                        setModalState(() {
                          final idx = emojis.indexOf(selectedEmoji);
                          selectedEmoji = emojis[(idx + 1) % emojis.length];
                        });
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                            child: Text(selectedEmoji,
                                style: const TextStyle(fontSize: 26))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(hintText: 'Reward title (e.g. 30 min screen time)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(hintText: 'Description (optional)'),
                ),
                const SizedBox(height: 16),
                Text('Assign to Children',
                    style: Theme.of(context).textTheme.titleMedium),
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
                      await provider.addReward(
                        title: titleCtrl.text,
                        description: descCtrl.text,
                        emoji: selectedEmoji,
                        choreGroupId: group.id,
                        assignedChildIds: selectedChildIds.toList(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Add Reward'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
