import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? helperText;
  final String? Function(String?)? validator;
  final bool enabled;
  final void Function(String)? onChanged;
  final TextInputAction? textInputAction;
  final void Function()? onEditingComplete;

  const PasswordField({
    super.key,
    required this.controller,
    this.labelText = 'Password',
    this.helperText,
    this.validator,
    this.enabled = true,
    this.onChanged,
    this.textInputAction,
    this.onEditingComplete,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _isObscured,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      textInputAction: widget.textInputAction,
      onEditingComplete: widget.onEditingComplete,
      decoration: InputDecoration(
        labelText: widget.labelText,
        helperText: widget.helperText,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _isObscured ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: widget.enabled
              ? () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                }
              : null,
        ),
      ),
      validator: widget.validator,
    );
  }
}
