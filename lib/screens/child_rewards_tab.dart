import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class ChildRewardsTab extends StatelessWidget {
  final AppUser child;
  final Color childColor;

  const ChildRewardsTab({
    super.key,
    required this.child,
    required this.childColor,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final unredeemedRewards =
        provider.getUnredeemedRewardsForChild(child.id);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My Rewards',
                    style: Theme.of(context)
                        .textTheme
                        .headlineLarge
                        ?.copyWith(color: childColor)),
                Text('Complete chore groups to unlock rewards!',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Unlocked rewards
          if (unredeemedRewards.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _sectionLabel(context, '🎉 Unlocked Rewards'),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: unredeemedRewards.length,
                itemBuilder: (context, index) {
                  final ri = unredeemedRewards[index];
                  final reward = provider.getRewardById(ri.rewardId);
                  if (reward == null) return const SizedBox.shrink();
                  return _unlockedRewardCard(context, provider, ri, reward);
                },
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Progress toward groups
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _sectionLabel(context, '📋 Group Progress'),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _buildGroupProgress(context, provider),
          ),
        ],
      ),
    );
  }

  Widget _unlockedRewardCard(BuildContext context, AppProvider provider,
      RewardInstance ri, Reward reward) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            childColor.withValues(alpha: 0.8),
            childColor,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reward.emoji, style: const TextStyle(fontSize: 32)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(reward.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _confirmRedeem(context, provider, ri, reward),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Redeem',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupProgress(BuildContext context, AppProvider provider) {
    final groups = provider.allChoreGroups
        .where((g) => g.assignedChildIds.contains(child.id))
        .toList();

    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('No reward groups yet',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Ask a parent to create chore groups with rewards.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return _groupProgressCard(context, provider, group);
      },
    );
  }

  Widget _groupProgressCard(
      BuildContext context, AppProvider provider, ChoreGroup group) {
    final today = DateTime.now();
    final choreIds = group.choreIds;
    int completed = 0;
    int total = choreIds.length;

    for (final choreId in choreIds) {
      final instances = provider
          .getInstancesForChild(child.id, today)
          .where((i) => i.choreId == choreId)
          .toList();
      if (instances.any((i) => i.statusIndex == ChoreStatus.approved.index)) {
        completed++;
      }
    }

    final progress = total > 0 ? completed / total : 0.0;
    final isComplete = completed >= total && total > 0;

    // Get associated rewards
    final rewards = provider.allRewards
        .where((r) => r.choreGroupId == group.id)
        .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isComplete
            ? childColor.withValues(alpha: 0.08)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isComplete
              ? childColor.withValues(alpha: 0.3)
              : AppTheme.divider,
        ),
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
              if (isComplete)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: childColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Complete! 🎉',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$completed/$total chores',
                  style: Theme.of(context).textTheme.bodySmall),
              Text('${(progress * 100).round()}%',
                  style: TextStyle(
                      color: childColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: childColor.withValues(alpha: 0.1),
              color: isComplete ? childColor : childColor.withValues(alpha: 0.6),
              minHeight: 7,
            ),
          ),
          if (rewards.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.lock_outline,
                    size: 14, color: AppTheme.textTertiary),
                const SizedBox(width: 5),
                Text('Unlocks: ',
                    style: Theme.of(context).textTheme.bodySmall),
                Expanded(
                  child: Text(
                    rewards.map((r) => '${r.emoji} ${r.title}').join(', '),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isComplete ? childColor : AppTheme.textTertiary,
                          fontWeight: isComplete ? FontWeight.w600 : FontWeight.w400,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(fontWeight: FontWeight.w600));
  }

  void _confirmRedeem(BuildContext context, AppProvider provider,
      RewardInstance ri, Reward reward) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('${reward.emoji} Redeem Reward?'),
        content: Text(
            'Are you sure you want to redeem "${reward.title}"? Ask a parent to confirm.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Not yet')),
          ElevatedButton(
            onPressed: () {
              provider.redeemReward(ri.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${reward.emoji} "${reward.title}" redeemed!'),
                backgroundColor: childColor,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: childColor),
            child: const Text('Redeem!'),
          ),
        ],
      ),
    );
  }
}
