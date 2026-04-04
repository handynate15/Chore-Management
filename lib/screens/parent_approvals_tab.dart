import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class ParentApprovalsTab extends StatelessWidget {
  const ParentApprovalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final pending = provider.getPendingApprovals();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              children: [
                Text('Approvals', style: Theme.of(context).textTheme.headlineLarge),
                if (pending.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${pending.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: pending.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text('All caught up!',
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 8),
                        Text('No chores waiting for review.',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      ...pending.map((instance) =>
                          _approvalCard(context, provider, instance)),
                      const SizedBox(height: 80),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _approvalCard(
      BuildContext context, AppProvider provider, ChoreInstance instance) {
    final chore = provider.getChoreById(instance.choreId);
    final child = provider.getUserById(instance.childId);
    if (chore == null || child == null) return const SizedBox.shrink();

    final childColor = provider.getChildColor(child);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: childColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                      child: Text(child.emoji,
                          style: const TextStyle(fontSize: 18))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(child.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: childColor)),
                      Text(
                        '${chore.emoji} ${chore.title}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (instance.submittedAt != null)
                  Text(
                    _timeAgo(instance.submittedAt!),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppTheme.textTertiary),
                  ),
              ],
            ),
          ),

          // Photo
          if (instance.photoPath != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildPhoto(instance.photoPath!),
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('No photo attached',
                      style: TextStyle(color: AppTheme.textTertiary)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Action buttons
          const Divider(height: 1, color: AppTheme.divider),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showDenyDialog(context, provider, instance),
                    icon: const Icon(Icons.close, size: 16,
                        color: AppTheme.error),
                    label: const Text('Redo',
                        style: TextStyle(color: AppTheme.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppTheme.error, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final parentId =
                          provider.currentUser?.id ?? '';
                      provider.approveChoreInstance(
                          instance.id, parentId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '${chore.emoji} ${chore.title} approved!'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoto(String photoPath) {
    if (photoPath.startsWith('http')) {
      return Image.network(
        photoPath,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const SizedBox(
          height: 80,
          child: Center(child: Text('Could not load photo')),
        ),
      );
    }
    final file = File(photoPath);
    if (file.existsSync()) {
      return Image.file(
        file,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }
    return Container(
      height: 80,
      color: AppTheme.surfaceVariant,
      child: const Center(child: Text('Photo not found')),
    );
  }

  void _showDenyDialog(
      BuildContext context, AppProvider provider, ChoreInstance instance) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Send Back for Redo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tell the child why they need to redo this:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                  hintText: 'e.g. Didn\'t fold the towels properly'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.denyChoreInstance(
                instance.id,
                provider.currentUser?.id ?? '',
                reasonCtrl.text,
              );
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Send Back'),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
