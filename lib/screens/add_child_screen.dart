import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

class AddChildScreen extends StatefulWidget {
  final AppUser? editUser;
  const AddChildScreen({super.key, this.editUser});

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen> {
  final _nameCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _confirmPinCtrl = TextEditingController();
  int _selectedColorIndex = 0;
  String _selectedEmoji = '👦';

  final List<String> _kidEmojis = [
    '👦', '👧', '🧒', '👶', '🧑', '🙋', '🧑‍🎓', '🧑‍💻',
    '🧑‍🎨', '🧑‍🍳', '🦸', '🦄'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editUser != null) {
      final u = widget.editUser!;
      _nameCtrl.text = u.name;
      _pinCtrl.text = u.pin;
      _confirmPinCtrl.text = u.pin;
      _selectedColorIndex = u.colorIndex;
      _selectedEmoji = u.emoji;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    _confirmPinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editUser != null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Child' : 'Add Child'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar preview
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.childColors[_selectedColorIndex]
                      .withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.childColors[_selectedColorIndex],
                    width: 3,
                  ),
                ),
                child: Center(
                    child: Text(_selectedEmoji,
                        style: const TextStyle(fontSize: 46))),
              ),
            ),
            const SizedBox(height: 24),

            // Emoji picker
            _sectionLabel('Avatar'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _kidEmojis.map((e) {
                final selected = _selectedEmoji == e;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = e),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.accentLight
                          : AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          selected ? Border.all(color: AppTheme.accent) : null,
                    ),
                    child: Center(
                        child: Text(e, style: const TextStyle(fontSize: 24))),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Color picker
            _sectionLabel('Color'),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                AppTheme.childColors.length,
                (i) {
                  final selected = _selectedColorIndex == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColorIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: selected ? 40 : 34,
                      height: selected ? 40 : 34,
                      decoration: BoxDecoration(
                        color: AppTheme.childColors[i],
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: AppTheme.textPrimary, width: 2.5)
                            : null,
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                    color: AppTheme.childColors[i]
                                        .withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3))
                              ]
                            : null,
                      ),
                      child: selected
                          ? const Icon(Icons.check,
                              color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                AppTheme.childColorNames.length,
                (i) => SizedBox(
                  width: 44,
                  child: Text(
                    AppTheme.childColorNames[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 9,
                      color: _selectedColorIndex == i
                          ? AppTheme.textPrimary
                          : AppTheme.textTertiary,
                      fontWeight: _selectedColorIndex == i
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Name
            _sectionLabel('Name'),
            const SizedBox(height: 10),
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(hintText: 'Child\'s name'),
              textCapitalization: TextCapitalization.words,
            ),

            const SizedBox(height: 20),

            // PIN
            _sectionLabel('PIN'),
            const SizedBox(height: 10),
            TextField(
              controller: _pinCtrl,
              decoration: const InputDecoration(hintText: '4-digit PIN'),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPinCtrl,
              decoration: const InputDecoration(hintText: 'Confirm PIN'),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(isEdit ? 'Save Changes' : 'Add Child'),
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

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _showError('Please enter the child\'s name');
      return;
    }
    if (_pinCtrl.text.length != 4) {
      _showError('PIN must be 4 digits');
      return;
    }
    if (_pinCtrl.text != _confirmPinCtrl.text) {
      _showError('PINs do not match');
      return;
    }

    final provider = context.read<AppProvider>();

    if (widget.editUser != null) {
      final user = widget.editUser!;
      user.name = _nameCtrl.text.trim();
      user.pin = _pinCtrl.text;
      user.colorIndex = _selectedColorIndex;
      user.emoji = _selectedEmoji;
      await provider.updateUser(user);
    } else {
      await provider.addChild(
        name: _nameCtrl.text.trim(),
        pin: _pinCtrl.text,
        colorIndex: _selectedColorIndex,
        emoji: _selectedEmoji,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }
}
