class PasswordValidation {
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSpecialChar;
  final bool isValid;

  const PasswordValidation({
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecialChar,
    required this.isValid,
  });
}

class PasswordValidator {
  static const int minLength = 8;

  /// Validate password and return detailed validation result
  static PasswordValidation validatePassword(String password) {
    final hasMinLength = password.length >= minLength;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    final isValid = hasMinLength &&
        hasUppercase &&
        hasLowercase &&
        hasNumber &&
        hasSpecialChar;

    return PasswordValidation(
      hasMinLength: hasMinLength,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasNumber: hasNumber,
      hasSpecialChar: hasSpecialChar,
      isValid: isValid,
    );
  }

  /// Calculate password strength score (0-100)
  static int calculatePasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int score = 0;

    // Length scoring
    if (password.length >= 8) score += 20;
    if (password.length >= 12) score += 10;
    if (password.length >= 16) score += 10;

    // Character variety scoring
    if (password.contains(RegExp(r'[a-z]'))) score += 15;
    if (password.contains(RegExp(r'[A-Z]'))) score += 15;
    if (password.contains(RegExp(r'[0-9]'))) score += 15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score += 15;

    return score.clamp(0, 100);
  }

  /// Get password strength label
  static String getPasswordStrengthLabel(int strength) {
    if (strength < 30) return 'Weak';
    if (strength < 60) return 'Fair';
    if (strength < 80) return 'Good';
    return 'Strong';
  }

  /// Validate email format
  static bool validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Get password validation error message
  static String? getPasswordErrorMessage(String password) {
    if (password.isEmpty) return 'Password is required';

    final validation = validatePassword(password);

    if (!validation.hasMinLength) {
      return 'Password must be at least $minLength characters long';
    }
    if (!validation.hasUppercase) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!validation.hasLowercase) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!validation.hasNumber) {
      return 'Password must contain at least one number';
    }
    if (!validation.hasSpecialChar) {
      return 'Password must contain at least one special character';
    }

    return null; // Password is valid
  }

  /// Get email validation error message
  static String? getEmailErrorMessage(String email) {
    if (email.isEmpty) return 'Email is required';
    if (!validateEmail(email)) return 'Please enter a valid email address';
    return null;
  }
}
