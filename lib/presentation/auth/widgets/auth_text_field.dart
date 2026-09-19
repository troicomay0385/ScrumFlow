import 'package:flutter/material.dart';

class AuthTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool obscureText;
  final String? errorText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const AuthTextField({
    super.key,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        errorText: errorText,
      ),
    );
  }
}
