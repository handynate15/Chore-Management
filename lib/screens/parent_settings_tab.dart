import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../screens/login_screen.dart';
import 'add_child_screen.dart';
import 'notification_settings_screen.dart';

class ParentSettingsTab extends StatelessWidget {
  const ParentSettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final children = provider.children;
    final parents = provider.parents;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: Theme.of(context).textTheme.headlineLarge),
            const SizedBox(height: 24),

            // Current user
            _sectionHeader(context, 'Logged In As'),
            const SizedBox(height: 10),
            _currentUserCard(context, provider),

            const SizedBox(height: 28),

            // Parents
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionHeader(context, 'Parents'),
              ],
            ),
            const SizedBox(height: 10),
            ...parents.map((p) => _userCard(context, provider, p, isParent: true)),

            const SizedBox(height: 28),

            // Children
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionHeader(context, 'Children'),
                TextButton.icon(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddChildScreen())),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Child'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (children.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.accentLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('No children added yet.',
                    style: Theme.of(context).textTheme.bodyMedium),
              )
            else
              ...children.map((c) => _userCard(context, provider, c, isParent: false)),

            const SizedBox(height: 28),

            // Notifications
            _sectionHeader(context, 'Notifications'),
            const SizedBox(height: 10),
            _notificationsCard(context),

            const SizedBox(height: 28),

            // About section
            _sectionHeader(context, 'About'),
            const SizedBox(height: 10),
            _aboutCard(context),

            const SizedBox(height: 28),

            // Logout
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  provider.logout();
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()));
                },
                icon: const Icon(Icons.logout, size: 16),
                label: const Text('Log Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.error,
                  side: const BorderSide(color: AppTheme.error),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) {
    return Text(
      text.toUpperCase(),
      style: Theme.of(context)
          .textTheme
          .labelSmall
          ?.copyWith(color: AppTheme.textTertiary, letterSpacing: 1.2),
    );
  }

  Widget _currentUserCard(BuildContext context, AppProvider provider) {
    final user = provider.currentUser!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Text(user.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: Theme.of(context).textTheme.titleMedium),
              Text('Parent account',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.accent)),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: () => _showEditParentDialog(context, provider, user),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _userCard(BuildContext context, AppProvider provider, AppUser user,
      {required bool isParent}) {
    final color =
        isParent ? AppTheme.accent : provider.getChildColor(user);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
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
                child: Text(user.emoji, style: const TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: Theme.of(context).textTheme.titleMedium),
                Text(isParent ? 'Parent' : 'Child',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: color)),
              ],
            ),
          ),
          if (!isParent)
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 18, color: AppTheme.textTertiary),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddChildScreen(editUser: user))),
            ),
          if (!isParent)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: AppTheme.textTertiary),
              onPressed: () => _confirmDelete(context, provider, user),
            ),
        ],
      ),
    );
  }

  Widget _notificationsCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const NotificationSettingsScreen())),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications_outlined,
                  color: AppTheme.accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notification Settings',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(
                      'Chore reminders, approval alerts, group completions',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppTheme.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _aboutCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('OnTrackFam',
                      style: Theme.of(context).textTheme.titleMedium),
                  Text('Family Chore Manager',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const Spacer(),
              Text('v1.0.0',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppTheme.textTertiary)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppTheme.divider, height: 1),
          const SizedBox(height: 12),
          Text(
            'All data is stored locally on this device. No cloud sync or account required.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textTertiary),
          ),
        ],
      ),
    );
  }

  void _showEditParentDialog(
      BuildContext context, AppProvider provider, AppUser user) {
    final nameCtrl = TextEditingController(text: user.name);
    final pinCtrl = TextEditingController(text: user.pin);
    String selectedEmoji = user.emoji;
    final emojis = ['👨', '👩', '🧑', '👴', '👵', '🧔'];

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Parent',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),
              // Emoji picker
              Wrap(
                spacing: 10,
                children: emojis.map((e) => GestureDetector(
                  onTap: () => setModalState(() => selectedEmoji = e),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selectedEmoji == e
                          ? AppTheme.accentLight
                          : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: selectedEmoji == e
                          ? Border.all(color: AppTheme.accent)
                          : null,
                    ),
                    child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinCtrl,
                decoration: const InputDecoration(labelText: 'PIN (4 digits)'),
                keyboardType: TextInputType.number,
                maxLength: 4,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    user.name = nameCtrl.text;
                    user.pin = pinCtrl.text;
                    user.emoji = selectedEmoji;
                    await provider.updateUser(user);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider provider, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove ${user.name}?'),
        content: Text(
            'This will remove ${user.name} and all their chore history. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              provider.removeChild(user.id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
