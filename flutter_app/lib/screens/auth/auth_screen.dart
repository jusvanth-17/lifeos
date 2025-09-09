import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/supabase_auth_provider.dart';
import '../../widgets/auth/password_field.dart';
import '../../widgets/auth/password_strength_indicator.dart';
import '../../utils/password_validator.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Check if user is already authenticated and redirect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated) {
        context.go('/home');
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).signInWithPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).signUpWithPassword(
          _emailController.text.trim(),
          _passwordController.text,
          _displayNameController.text.trim(),
        );
  }

  void _switchAuthMode() {
    final currentMode = ref.read(authProvider).mode;
    final newMode =
        currentMode == AuthMode.login ? AuthMode.register : AuthMode.login;
    ref.read(authProvider.notifier).switchAuthMode(newMode);

    // Clear form when switching modes
    _formKey.currentState?.reset();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _displayNameController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLogin = authState.mode == AuthMode.login;

    // Listen to auth state changes and redirect when authenticated
    ref.listen<AppAuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated && mounted) {
        context.go('/home');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo and Title
                  Icon(
                    Icons.rocket_launch,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'lifeOS',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your comprehensive productivity platform',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Auth Mode Toggle
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed:
                              authState.isSigningIn || authState.isRegistering
                                  ? null
                                  : () {
                                      if (!isLogin) _switchAuthMode();
                                    },
                          style: TextButton.styleFrom(
                            backgroundColor: isLogin
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                            foregroundColor: isLogin
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                : null,
                          ),
                          child: const Text('Sign In'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextButton(
                          onPressed:
                              authState.isSigningIn || authState.isRegistering
                                  ? null
                                  : () {
                                      if (isLogin) _switchAuthMode();
                                    },
                          style: TextButton.styleFrom(
                            backgroundColor: !isLogin
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                            foregroundColor: !isLogin
                                ? Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                : null,
                          ),
                          child: const Text('Sign Up'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Auth Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Display Name (Register only)
                        if (!isLogin) ...[
                          TextFormField(
                            controller: _displayNameController,
                            enabled: !authState.isRegistering,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Display Name',
                              prefixIcon: Icon(Icons.person_outline),
                              helperText: 'How you\'d like to be addressed',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your display name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email
                        TextFormField(
                          controller: _emailController,
                          enabled: !authState.isSigningIn &&
                              !authState.isRegistering,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            return PasswordValidator.getEmailErrorMessage(
                                value ?? '');
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password
                        PasswordField(
                          controller: _passwordController,
                          enabled: !authState.isSigningIn &&
                              !authState.isRegistering,
                          textInputAction: isLogin
                              ? TextInputAction.done
                              : TextInputAction.next,
                          onEditingComplete: isLogin ? _handleSignIn : null,
                          onChanged: (value) {
                            // Trigger rebuild for password strength indicator
                            setState(() {});
                          },
                          validator: (value) {
                            if (isLogin) {
                              // For login, just check if password is not empty
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            } else {
                              // For registration, validate password strength
                              return PasswordValidator.getPasswordErrorMessage(
                                  value ?? '');
                            }
                          },
                        ),

                        // Password Strength Indicator (Register only)
                        if (!isLogin) ...[
                          const SizedBox(height: 8),
                          PasswordStrengthIndicator(
                            password: _passwordController.text,
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password
                          PasswordField(
                            controller: _confirmPasswordController,
                            labelText: 'Confirm Password',
                            enabled: !authState.isRegistering,
                            textInputAction: TextInputAction.done,
                            onEditingComplete: _handleSignUp,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Submit Button
                        ElevatedButton(
                          onPressed:
                              (authState.isSigningIn || authState.isRegistering)
                                  ? null
                                  : (isLogin ? _handleSignIn : _handleSignUp),
                          child: (authState.isSigningIn ||
                                  authState.isRegistering)
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(isLogin
                                        ? 'Signing In...'
                                        : 'Creating Account...'),
                                  ],
                                )
                              : Text(isLogin ? 'Sign In' : 'Create Account'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Security Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.security,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Secure Authentication',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Your data is protected with industry-standard encryption and security practices.',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  // Error Display
                  if (authState.error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              authState.error!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                ref.read(authProvider.notifier).clearError(),
                            icon: const Icon(Icons.close),
                            iconSize: 20,
                            color: Colors.red.shade700,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
