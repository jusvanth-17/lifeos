import 'package:flutter/material.dart';
import '../../utils/password_validator.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showDetails;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = PasswordValidator.calculatePasswordStrength(password);
    final validation = PasswordValidator.validatePassword(password);
    final strengthLabel = PasswordValidator.getPasswordStrengthLabel(strength);

    Color strengthColor;
    if (strength < 30) {
      strengthColor = Colors.red;
    } else if (strength < 60) {
      strengthColor = Colors.orange;
    } else if (strength < 80) {
      strengthColor = Colors.blue;
    } else {
      strengthColor = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strength bar
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strength / 100,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                minHeight: 4,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              strengthLabel,
              style: TextStyle(
                color: strengthColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),

        if (showDetails) ...[
          const SizedBox(height: 8),
          // Validation details
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _ValidationChip(
                label: '8+ chars',
                isValid: validation.hasMinLength,
              ),
              _ValidationChip(
                label: 'A-Z',
                isValid: validation.hasUppercase,
              ),
              _ValidationChip(
                label: 'a-z',
                isValid: validation.hasLowercase,
              ),
              _ValidationChip(
                label: '0-9',
                isValid: validation.hasNumber,
              ),
              _ValidationChip(
                label: '!@#',
                isValid: validation.hasSpecialChar,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ValidationChip extends StatelessWidget {
  final String label;
  final bool isValid;

  const _ValidationChip({
    required this.label,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.shade100 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid ? Colors.green.shade300 : Colors.grey.shade400,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: isValid ? Colors.green.shade700 : Colors.grey.shade600,
        ),
      ),
    );
  }
}
