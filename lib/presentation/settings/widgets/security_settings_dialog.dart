import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

      // Mở modal yêu cầu nhập mật khẩu để kích hoạt
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
                  borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.fingerprint, color: AppColors.primary, size: 28),
                  SizedBox(width: 8),
                  Text('Kích hoạt Vân tay / Face ID',
                      style: TextStyle(fontSize: 16)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tài khoản liên kết: $currentEmail',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Vui lòng nhập mật khẩu tài khoản hiện tại để xác thực và liên kết sinh trắc học:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
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
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
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

                    // Yêu cầu quét vân tay để kích hoạt
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
                  child: const Text('Xác nhận & Quét vân tay'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 8),
            Text('Đăng xuất',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản này không? Bạn có thể dùng Mật khẩu hoặc Vân tay đã lưu để đăng nhập lại sau.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      Navigator.of(context).pop(); // Đóng SecuritySettingsDialog
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Row(
        children: [
          Icon(Icons.settings_outlined, color: AppColors.primary, size: 26),
          SizedBox(width: 8),
          Text(
            'Cài đặt tài khoản',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFEEF2FF),
                          child: const Icon(Icons.person,
                              color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentName.isNotEmpty ? currentName : 'Người dùng',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                currentEmail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Hardware status
                  Row(
                    children: [
                      Icon(
                        _isAvailable ? Icons.check_circle : Icons.warning_rounded,
                        color: _isAvailable ? Colors.green : Colors.orange,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _isAvailable
                              ? 'Cảm biến sinh trắc học: Sẵn sàng'
                              : 'Không tìm thấy cảm biến sinh trắc học',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isAvailable
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Toggle Biometric Switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Đăng nhập bằng Vân tay / Face ID',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      _isEnabled
                          ? 'Đang liên kết: $_savedEmail'
                          : 'Bật để mở khóa nhanh khi quay lại màn hình đăng nhập',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    value: _isEnabled,
                    activeThumbColor: AppColors.primary,
                    onChanged: _isAvailable ? _handleToggleBiometric : null,
                  ),

                  if (_isEnabled) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final ok = await _biometricService.authenticate(
                          localizedReason: 'Kiểm tra độ nhạy cảm biến vân tay',
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ok
                                  ? '🎉 Xác thực vân tay thành công 100%!'
                                  : 'Xác thực không thành công.'),
                              backgroundColor:
                                  ok ? Colors.green.shade700 : AppColors.error,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.fingerprint_rounded, size: 20),
                      label: const Text('Thử nghiệm quét vân tay ngay'),
                    ),
                  ],

                  const Divider(height: 24),

                  // Logout action inside dialog content
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.logout_rounded,
                          color: AppColors.error, size: 20),
                    ),
                    title: const Text(
                      'Đăng xuất tài khoản',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Thoát phiên làm việc hiện tại trên thiết bị này',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.error, size: 20),
                    onTap: () => _confirmSignOut(context),
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
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Đóng'),
        ),
      ],
    );
  }
}
