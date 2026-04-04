import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../screens/parent_home_screen.dart';
import '../screens/child_home_screen.dart';
import '../widgets/pin_pad.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AppUser? _selectedUser;
  String _enteredPin = '';
  bool _showError = false;

  void _onPinEntered(String pin) {
    if (_selectedUser == null) return;
    final provider = context.read<AppProvider>();
    final success = provider.login(_selectedUser!.id, pin);
    if (success) {
      final user = provider.currentUser!;
      if (user.isParent) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const ParentHomeScreen()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const ChildHomeScreen()));
      }
    } else {
      setState(() {
        _showError = true;
        _enteredPin = '';
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _showError = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final users = provider.allUsers;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: _selectedUser == null
            ? _buildUserSelection(users)
            : _buildPinEntry(),
      ),
    );
  }

  Widget _buildUserSelection(List<AppUser> users) {
    final parents = users.where((u) => u.isParent).toList();
    final children = users.where((u) => u.isChild).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          // Logo & title
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('OnTrack',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          )),
                  Text('Who\'s checking in?',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 48),

          // Parents section
          if (parents.isNotEmpty) ...[
            _sectionLabel(context, 'Parents'),
            const SizedBox(height: 12),
            ...parents.map((u) => _userTile(u, isParent: true)),
            const SizedBox(height: 32),
          ],

          // Children section
          if (children.isNotEmpty) ...[
            _sectionLabel(context, 'Kids'),
            const SizedBox(height: 12),
            ...children.map((u) => _userTile(u, isParent: false)),
          ],

          if (children.isEmpty && parents.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Log in as a parent to add your children.',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.accent),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Text(label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.textTertiary,
              letterSpacing: 1.2,
            ));
  }

  Widget _userTile(AppUser user, {required bool isParent}) {
    final provider = context.read<AppProvider>();
    final color = isParent ? AppTheme.accent : provider.getChildColor(user);

    return GestureDetector(
      onTap: () => setState(() {
        _selectedUser = user;
        _enteredPin = '';
        _showError = false;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(user.emoji,
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(user.name,
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isParent ? 'Parent' : 'Kid',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppTheme.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildPinEntry() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedUser = null;
                _enteredPin = '';
              }),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back_ios, size: 16, color: AppTheme.textSecondary),
                  Text('Back',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          // User avatar
          _buildAvatarCircle(),
          const SizedBox(height: 16),
          Text(_selectedUser!.name,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text('Enter your PIN',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 32),
          // PIN dots
          _buildPinDots(),
          if (_showError) ...[
            const SizedBox(height: 12),
            Text('Incorrect PIN. Try again.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppTheme.error)),
          ],
          const SizedBox(height: 32),
          // PIN pad
          PinPad(
            onDigitPressed: (digit) {
              if (_enteredPin.length < 4) {
                final newPin = _enteredPin + digit;
                setState(() => _enteredPin = newPin);
                if (newPin.length == 4) _onPinEntered(newPin);
              }
            },
            onBackspace: () {
              if (_enteredPin.isNotEmpty) {
                setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCircle() {
    final provider = context.read<AppProvider>();
    final color = _selectedUser!.isParent
        ? AppTheme.accent
        : provider.getChildColor(_selectedUser!);
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Center(
        child: Text(_selectedUser!.emoji, style: const TextStyle(fontSize: 36)),
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final filled = i < _enteredPin.length;
        final color = _showError
            ? AppTheme.error
            : _selectedUser!.isParent
                ? AppTheme.accent
                : context.read<AppProvider>().getChildColor(_selectedUser!);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? color : AppTheme.divider,
            border: Border.all(color: filled ? color : AppTheme.textTertiary, width: 1.5),
          ),
        );
      }),
    );
  }
}
