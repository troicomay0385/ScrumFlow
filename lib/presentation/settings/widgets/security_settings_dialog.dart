import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/services/biometric_service.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';

class SecuritySettingsDialog extends StatefulWidget {
  const SecuritySettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: const SecuritySettingsDialog(),
      ),
    );
  }

  @override
  State<SecuritySettingsDialog> createState() => _SecuritySettingsDialogState();
}

class _SecuritySettingsDialogState extends State<SecuritySettingsDialog> {
  final _biometricService = BiometricService();
  final _passwordController = TextEditingController();
  bool _isLoading = true;
  bool _isAvailable = false;
  bool _isEnabled = false;
  String _savedEmail = '';
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final available = await _biometricService.isBiometricAvailable();
    final enabled = await _biometricService.isBiometricLoginEnabled();
    final creds = await _biometricService.getSavedCredentials();

    if (mounted) {
      setState(() {
        _isAvailable = available;
        _isEnabled = enabled;
        _savedEmail = creds?['email'] ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleToggleBiometric(bool enable) async {
    if (enable) {
      final authState = context.read<AuthBloc>().state;
      final currentEmail =
          authState is AuthAuthenticated ? authState.user.email : '';

      _showPasswordConfirmationDialog(currentEmail);
    } else {
      await _biometricService.disableBiometricLogin();
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tắt đăng nhập bằng Vân tay / Face ID')),
        );
      }
    }
  }

  void _showPasswordConfirmationDialog(String currentEmail) {
    _passwordController.clear();
    showDialog(
      context: context,
      builder: (confirmContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fingerprint, color: AppColors.primaryContainer, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Kích hoạt Sinh trắc học',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tài khoản liên kết: $currentEmail',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Vui lòng nhập mật khẩu tài khoản hiện tại để xác thực và liên kết sinh trắc học vào máy:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () {
                          setDialogState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(confirmContext).pop(),
                  child: Text(
                    'Hủy',
                    style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    final password = _passwordController.text;
                    if (password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Vui lòng nhập mật khẩu của bạn')),
                      );
                      return;
                    }

                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.of(confirmContext).pop();

                    final authenticated = await _biometricService.authenticate(
                      localizedReason:
                          'Chạm vân tay hoặc quét Face ID để kích hoạt liên kết tài khoản',
                    );

                    if (authenticated) {
                      await _biometricService.enableBiometricLogin(
                        email: currentEmail,
                        password: password,
                      );
                      await _loadStatus();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                              'Đã liên kết sinh trắc học thành công cho $currentEmail!'),
                          backgroundColor: Colors.green.shade700,
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Xác thực sinh trắc học thất bại hoặc đã bị hủy.'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Xác nhận & Quét',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'Đăng xuất',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này không? Bạn có thể dùng Mật khẩu hoặc Vân tay đã lưu để đăng nhập lại sau.',
          style: GoogleFonts.plusJakartaSans(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Hủy',
              style: GoogleFonts.plusJakartaSans(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Đăng xuất',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      Navigator.of(context).pop();
      context.read<AuthBloc>().add(AuthSignOutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final currentEmail =
        authState is AuthAuthenticated ? authState.user.email : 'Chưa đăng nhập';
    final currentName =
        authState is AuthAuthenticated ? authState.user.fullName : '';

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.settings_suggest_rounded,
                color: AppColors.primaryContainer, size: 24),
          ),
          const SizedBox(width: 10),
          Text(
            'Cài đặt tài khoản',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 120,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User info card
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            currentName.isNotEmpty
                                ? currentName.substring(0, 1).toUpperCase()
                                : 'U',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentName.isNotEmpty ? currentName : 'Người dùng',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.onSurface,
                                ),
                              ),
                              Text(
                                currentEmail,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Hardware status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isAvailable
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _isAvailable
                            ? Colors.green.shade200
                            : Colors.orange.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isAvailable ? Icons.check_circle_rounded : Icons.warning_rounded,
                          color: _isAvailable ? Colors.green.shade700 : Colors.orange.shade700,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _isAvailable
                                ? 'Cảm biến sinh trắc học: Sẵn sàng'
                                : 'Không tìm thấy cảm biến sinh trắc học',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: _isAvailable
                                  ? Colors.green.shade800
                                  : Colors.orange.shade800,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Toggle Biometric Switch
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      title: Text(
                        'Đăng nhập bằng Vân tay / Face ID',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        _isEnabled
                            ? 'Đang liên kết: $_savedEmail'
                            : 'Mở khóa nhanh khi quay lại màn hình đăng nhập',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      value: _isEnabled,
                      activeThumbColor: AppColors.primaryContainer,
                      onChanged: _isAvailable ? _handleToggleBiometric : null,
                    ),
                  ),

                  if (_isEnabled) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        backgroundColor: AppColors.surfaceContainerLow,
                      ),
                      onPressed: () async {
                        final ok = await _biometricService.authenticate(
                          localizedReason: 'Kiểm tra độ nhạy cảm biến vân tay',
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? '🎉 Xác thực sinh trắc học thành công 100%!'
                                  : 'Xác thực không thành công.'),
                              backgroundColor:
                                  ok ? Colors.green.shade700 : AppColors.error,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.fingerprint_rounded, size: 18),
                      label: Text(
                        'Thử nghiệm cảm biến ngay',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Logout action inside dialog content
                  InkWell(
                    onTap: () => _confirmSignOut(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.logout_rounded,
                                color: AppColors.error, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Đăng xuất tài khoản',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Thoát phiên làm việc trên thiết bị này',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppColors.error, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF1F5F9),
            foregroundColor: const Color(0xFF334155),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Đóng',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
