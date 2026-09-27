import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/services/biometric_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/loading_overlay.dart';
import '../widgets/saved_account_tile.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _biometricService = BiometricService();
  bool _obscurePassword = true;
  bool _canUseBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final available = await _biometricService.isBiometricAvailable();
    final creds = await _biometricService.getSavedCredentials();
    if (mounted) {
      setState(() {
        _canUseBiometric = available && creds != null;
      });
      // Tự động gợi ý điền email nếu có creds
      if (creds != null && _emailController.text.isEmpty) {
        _emailController.text = creds['email'] ?? '';
      }
    }
  }

  Future<void> _onBiometricLoginPressed() async {
    final creds = await _biometricService.getSavedCredentials();
    if (creds == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Chưa có dữ liệu sinh trắc học đã lưu. Vui lòng đăng nhập bằng mật khẩu trước để kích hoạt.',
            ),
          ),
        );
      }
      return;
    }

    final authenticated = await _biometricService.authenticate();
    if (authenticated && mounted) {
      final email = creds['email']!;
      final password = creds['password']!;
      _emailController.text = email;
      _passwordController.text = password;

      context.read<AuthBloc>().add(
            AuthSignInRequested(
              email: email,
              password: password,
            ),
          );
    }
  }

  Future<void> _onFaceIdLoginPressed() async {
    final messenger = ScaffoldMessenger.of(context);
    final creds = await _biometricService.getSavedCredentials();

    final authenticated = await _biometricService.authenticateFaceId(
      localizedReason: 'Nhìn vào màn hình để quét Face ID đăng nhập ScrumFlow',
    );

    if (authenticated && mounted) {
      if (creds != null) {
        final email = creds['email']!;
        final password = creds['password']!;
        _emailController.text = email;
        _passwordController.text = password;

        context.read<AuthBloc>().add(
              AuthSignInRequested(
                email: email,
                password: password,
              ),
            );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 Quét Face ID thành công! Để tự động đăng nhập, vui lòng đăng nhập một lần bằng mật khẩu để liên kết tài khoản.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } else if (mounted) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Chưa nhận diện được khuôn mặt. Vui lòng kiểm tra camera trước và đảm bảo đã bật Mở khóa khuôn mặt trong Cài đặt điện thoại.',
          ),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _onLoginPressed() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email và mật khẩu')),
      );
      return;
    }

    context.read<AuthBloc>().add(
          AuthSignInRequested(
            email: email,
            password: password,
          ),
        );
  }

  void _onForgotPasswordPressed() {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email để đặt lại mật khẩu')),
      );
      return;
    }

    context.read<AuthBloc>().add(AuthPasswordResetRequested(email));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // Lưu credentials an toàn cho các lần đăng nhập sinh trắc học sau (US-056)
            final email = _emailController.text.trim();
            final password = _passwordController.text;
            if (email.isNotEmpty && password.isNotEmpty) {
              _biometricService.enableBiometricLogin(
                email: email,
                password: password,
              );
            }

            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.home,
              (route) => false,
            );
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          } else if (state is AuthPasswordResetSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã gửi email đặt lại mật khẩu tới ${state.email}'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        },
        builder: (context, state) {
          List<String> recentAccounts = [];
          if (state is AuthUnauthenticated) {
            recentAccounts = state.recentAccounts;
          } else if (state is AuthError) {
            recentAccounts = state.recentAccounts;
          }

          return LoadingOverlay(
            isLoading: state is AuthLoading,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),
                    const Text(
                      'Chào mừng trở lại',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    
                    if (recentAccounts.isNotEmpty) ...[
                      const Text(
                        'Tài khoản gần đây',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentAccounts.length,
                        itemBuilder: (context, index) {
                          final email = recentAccounts[index];
                          return SavedAccountTile(
                            email: email,
                            onTap: () {
                              _emailController.text = email;
                            },
                            onRemove: () {
                              context.read<AuthBloc>().add(AuthRemoveRecentAccount(email));
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],

                    AuthTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _passwordController,
                      label: 'Mật khẩu',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textHint,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _onForgotPasswordPressed,
                        child: const Text('Quên mật khẩu?'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AuthButton(
                      text: 'Đăng nhập',
                      onPressed: _onLoginPressed,
                    ),
                    if (_canUseBiometric) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: AppColors.primary, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _onBiometricLoginPressed,
                              icon: const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 22),
                              label: const Text(
                                'Vân tay',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _onFaceIdLoginPressed,
                              icon: const Icon(Icons.face_retouching_natural, color: Color(0xFF4F46E5), size: 22),
                              label: const Text(
                                'Face ID',
                                style: TextStyle(
                                  color: Color(0xFF4F46E5),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(46),
                          side: BorderSide(color: Colors.indigo.shade200, width: 1.2),
                          backgroundColor: Colors.indigo.shade50.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _onFaceIdLoginPressed,
                        icon: const Icon(Icons.face_retouching_natural, color: Color(0xFF4F46E5), size: 22),
                        label: const Text(
                          'Kiểm tra cảm biến Face ID / Khuôn mặt',
                          style: TextStyle(
                            color: Color(0xFF4F46E5),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    GoogleSignInButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthGoogleSignInRequested());
                      },
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Chưa có tài khoản? ',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppRoutes.register);
                          },
                          child: const Text('Đăng ký ngay'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
