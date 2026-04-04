import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PinPad extends StatelessWidget {
  final void Function(String digit) onDigitPressed;
  final VoidCallback onBackspace;

  const PinPad({
    super.key,
    required this.onDigitPressed,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(context, ['1', '2', '3']),
        const SizedBox(height: 12),
        _buildRow(context, ['4', '5', '6']),
        const SizedBox(height: 12),
        _buildRow(context, ['7', '8', '9']),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 72 + 12), // spacer
            _buildKey(context, '0'),
            const SizedBox(width: 12),
            _buildBackspace(context),
          ],
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.asMap().entries.map((e) {
        return Row(
          children: [
            _buildKey(context, e.value),
            if (e.key < 2) const SizedBox(width: 12),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildKey(BuildContext context, String digit) {
    return GestureDetector(
      onTap: () => onDigitPressed(digit),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Center(
          child: Text(
            digit,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: AppTheme.textPrimary,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackspace(BuildContext context) {
    return GestureDetector(
      onTap: onBackspace,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: const Center(
          child: Icon(Icons.backspace_outlined, size: 22, color: AppTheme.textSecondary),
        ),
      ),
    );
  }
}
