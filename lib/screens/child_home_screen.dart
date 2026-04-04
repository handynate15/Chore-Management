import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../screens/login_screen.dart';
import 'child_calendar_tab.dart';
import 'child_rewards_tab.dart';

class ChildHomeScreen extends StatefulWidget {
  const ChildHomeScreen({super.key});

  @override
  State<ChildHomeScreen> createState() => _ChildHomeScreenState();
}

class _ChildHomeScreenState extends State<ChildHomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final child = provider.currentUser!;
    final childColor = provider.getChildColor(child);

    final tabs = [
      _MyChoresTab(child: child, childColor: childColor),
      ChildCalendarTab(child: child, childColor: childColor),
      ChildRewardsTab(child: child, childColor: childColor),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: tabs[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.divider, width: 1)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.task_alt_rounded, 'My Chores', childColor),
                _navItem(2, Icons.calendar_month_rounded, 'Calendar', childColor),
                _navItem(1, Icons.star_rounded, 'Rewards', childColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label, Color childColor) {
    final selected = _selectedIndex == index;
    final color = selected ? childColor : AppTheme.textTertiary;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              )),
        ],
      ),
    );
  }
}

class _MyChoresTab extends StatelessWidget {
  final AppUser child;
  final Color childColor;

  const _MyChoresTab({required this.child, required this.childColor});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final today = DateTime.now();
    final instances = provider.getInstancesForChild(child.id, today);

    final morningInstances = _getBySlot(instances, provider, ChoreTimeSlot.morning);
    final afternoonInstances = _getBySlot(instances, provider, ChoreTimeSlot.afternoon);
    final eveningInstances = _getBySlot(instances, provider, ChoreTimeSlot.evening);
    final specificInstances = _getBySlot(instances, provider, ChoreTimeSlot.specific);

    final approvedCount =
        instances.where((i) => i.statusIndex == ChoreStatus.approved.index).length;
    final total = instances.length;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hi, ${child.name}!',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineLarge
                                  ?.copyWith(
                                      color: childColor,
                                      fontWeight: FontWeight.w700)),
                          Text(_todayLabel(),
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          provider.logout();
                          Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const LoginScreen()));
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: childColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                              child: Text(child.emoji,
                                  style: const TextStyle(fontSize: 22))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Progress bar
                  if (total > 0) _progressBar(context, approvedCount, total),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          if (instances.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      const Text('🎉', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      Text('No chores today!',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 8),
                      Text('Enjoy your free day!',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            if (morningInstances.isNotEmpty)
              _slotSection(context, provider, '☀️ Morning', morningInstances),
            if (afternoonInstances.isNotEmpty)
              _slotSection(context, provider, '🌤️ Afternoon', afternoonInstances),
            if (eveningInstances.isNotEmpty)
              _slotSection(context, provider, '🌙 Evening', eveningInstances),
            if (specificInstances.isNotEmpty)
              _slotSection(context, provider, '🕐 Scheduled', specificInstances),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  List<ChoreInstance> _getBySlot(
      List<ChoreInstance> instances, AppProvider provider, ChoreTimeSlot slot) {
    return instances.where((i) {
      final chore = provider.getChoreById(i.choreId);
      return chore?.timeSlot == slot;
    }).toList();
  }

  Widget _progressBar(BuildContext context, int done, int total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$done of $total chores done',
                style: Theme.of(context).textTheme.bodyMedium),
            Text('${total > 0 ? (done / total * 100).round() : 0}%',
                style: TextStyle(
                    color: childColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: total > 0 ? done / total : 0,
            backgroundColor: childColor.withValues(alpha: 0.15),
            color: childColor,
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  SliverToBoxAdapter _slotSection(BuildContext context, AppProvider provider,
      String label, List<ChoreInstance> instances) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textTertiary,
                      letterSpacing: 1.0,
                    )),
            const SizedBox(height: 10),
            ...instances.map((i) => _choreCard(context, provider, i)),
          ],
        ),
      ),
    );
  }

  Widget _choreCard(
      BuildContext context, AppProvider provider, ChoreInstance instance) {
    final chore = provider.getChoreById(instance.choreId);
    if (chore == null) return const SizedBox.shrink();

    final status = instance.status;
    final isApproved = status == ChoreStatus.approved;
    final isSubmitted = status == ChoreStatus.submitted;
    final isDenied = status == ChoreStatus.denied;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDenied
              ? AppTheme.error.withValues(alpha: 0.4)
              : isApproved
                  ? childColor.withValues(alpha: 0.3)
                  : AppTheme.divider,
          width: isDenied || isApproved ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Status indicator / emoji
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isApproved
                        ? childColor.withValues(alpha: 0.15)
                        : isDenied
                            ? AppTheme.errorLight
                            : AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: isApproved
                        ? Icon(Icons.check_circle, color: childColor, size: 24)
                        : isSubmitted
                            ? Icon(Icons.hourglass_empty, color: AppTheme.warning, size: 24)
                            : isDenied
                                ? const Icon(Icons.replay_rounded, color: AppTheme.error, size: 24)
                                : Text(chore.emoji, style: const TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chore.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              decoration: isApproved
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isApproved
                                  ? AppTheme.textTertiary
                                  : AppTheme.textPrimary,
                            ),
                      ),
                      if (isDenied && instance.deniedReason != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          '↩ ${instance.deniedReason}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.error,
                              fontStyle: FontStyle.italic),
                        ),
                      ] else if (chore.specificTime != null) ...[
                        const SizedBox(height: 3),
                        Text(chore.specificTime!,
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
                // Action button
                if (!isApproved && !isSubmitted)
                  GestureDetector(
                    onTap: () => _submitChore(context, provider, instance, chore),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: childColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(isDenied ? 'Redo' : 'Done',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  )
                else if (isSubmitted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Pending',
                        style: TextStyle(
                            color: AppTheme.warning,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ),
              ],
            ),
          ),
          // Photo preview if submitted
          if (instance.photoPath != null && isSubmitted) ...[
            const Divider(height: 1, color: AppTheme.divider),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.photo_outlined,
                      size: 16, color: AppTheme.textTertiary),
                  const SizedBox(width: 6),
                  Text('Photo submitted - waiting for approval',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _submitChore(BuildContext context, AppProvider provider,
      ChoreInstance instance, Chore chore) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _SubmitChoreSheet(
        chore: chore,
        instance: instance,
        childColor: childColor,
        provider: provider,
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    final days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

class _SubmitChoreSheet extends StatefulWidget {
  final Chore chore;
  final ChoreInstance instance;
  final Color childColor;
  final AppProvider provider;

  const _SubmitChoreSheet({
    required this.chore,
    required this.instance,
    required this.childColor,
    required this.provider,
  });

  @override
  State<_SubmitChoreSheet> createState() => _SubmitChoreSheetState();
}

class _SubmitChoreSheetState extends State<_SubmitChoreSheet> {
  String? _photoPath;
  bool _loading = false;

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file != null) setState(() => _photoPath = file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Mark as Done',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            '${widget.chore.emoji} ${widget.chore.title}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          // Photo section
          if (_photoPath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(_photoPath!),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _pickPhoto(ImageSource.camera),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retake'),
            ),
          ] else ...[
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.camera_alt_outlined,
                      size: 36, color: AppTheme.textTertiary),
                  const SizedBox(height: 10),
                  Text('Add a photo to show you\'re done!',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt, size: 16),
                        label: const Text('Camera'),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () => _pickPhoto(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library, size: 16),
                        label: const Text('Gallery'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      await widget.provider.submitChoreInstance(
                          widget.instance.id, _photoPath);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              '${widget.chore.emoji} Submitted! Waiting for approval.'),
                          backgroundColor: widget.childColor,
                        ));
                      }
                    },
              style: ElevatedButton.styleFrom(
                  backgroundColor: widget.childColor),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Submit for Approval'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
