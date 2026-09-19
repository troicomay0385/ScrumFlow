import 'package:flutter/material.dart';
import '../../../app/constants/app_colors.dart';

class SavedAccountTile extends StatelessWidget {
  final String email;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const SavedAccountTile({
    super.key,
    required this.email,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary,
        child: Text(
          email.isNotEmpty ? email[0].toUpperCase() : '?',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      title: Text(
        email,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close, color: AppColors.textHint),
        onPressed: onRemove,
      ),
    );
  }
}
