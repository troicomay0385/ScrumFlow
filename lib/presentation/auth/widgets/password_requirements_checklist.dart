import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/utils/password_validator.dart';

class PasswordRequirementsChecklist extends StatelessWidget {
  final String password;
  final String confirmPassword;

  const PasswordRequirementsChecklist({
    super.key,
    required this.password,
    required this.confirmPassword,
  });

  @override
  Widget build(BuildContext context) {
    final result = PasswordValidator.validate(password, confirmPassword);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRequirement(
          text: 'Tối thiểu 8 ký tự',
          isMet: result.hasMinLength,
        ),
        _buildRequirement(
          text: 'Có ít nhất 1 chữ hoa',
          isMet: result.hasUppercase,
        ),
        _buildRequirement(
          text: 'Có ít nhất 1 chữ số',
          isMet: result.hasDigit,
        ),
        _buildRequirement(
          text: 'Có ít nhất 1 ký tự đặc biệt',
          isMet: result.hasSpecialChar,
        ),
        _buildRequirement(
          text: 'Xác nhận mật khẩu trùng khớp',
          isMet: result.passwordsMatch,
        ),
      ],
    );
  }

  Widget _buildRequirement({required String text, required bool isMet}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              isMet ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isMet ? AppColors.success : AppColors.textHint,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? AppColors.textPrimary : AppColors.textHint,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
