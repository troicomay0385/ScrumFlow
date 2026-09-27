import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../app/services/biometric_service.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricStatus() async {
    final available = await _biometricService.isBiometricAvailable();
    final creds = await _biometricService.getSavedCredentials();
    if (mounted) {
      setState(() {
        _canUseBiometric = available && creds != null;
      });
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
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
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
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),

                    // Top Bar Brand Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryContainer.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.splitscreen_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ScrumFlow',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Agile Pill Tag
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'SPRINT WORKSPACE V2.4',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title & Subtitle
                    Text(
                      'Chào mừng trở lại',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Đăng nhập vào không gian làm việc Agile của bạn',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Recent Accounts Tile
                    if (recentAccounts.isNotEmpty) ...[
                      Text(
                        'Tài khoản gần đây',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
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
                            onTap: () => _emailController.text = email,
                            onRemove: () {
                              context.read<AuthBloc>().add(AuthRemoveRecentAccount(email));
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Bento Card Wrapper
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email Input
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: AppColors.onSurface,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Email công việc',
                              hintText: 'alex@company.com',
                              prefixIcon: const Icon(Icons.mail_outline_rounded,
                                  color: Color(0xFF64748B), size: 20),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Password Input
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: AppColors.onSurface,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              prefixIcon: const Icon(Icons.lock_outline_rounded,
                                  color: Color(0xFF64748B), size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF64748B),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: _onForgotPasswordPressed,
                              child: Text(
                                'Quên mật khẩu?',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryContainer,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Primary Action Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryContainer,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 1,
                              shadowColor: AppColors.primaryContainer.withValues(alpha: 0.4),
                            ),
                            onPressed: _onLoginPressed,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Đăng nhập',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                          ),

                          // Biometrics Section
                          if (_canUseBiometric) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                                      backgroundColor: AppColors.surfaceContainerLow,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: _onBiometricLoginPressed,
                                    icon: const Icon(Icons.fingerprint_rounded,
                                        color: AppColors.primaryContainer, size: 20),
                                    label: Text(
                                      'Vân tay',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.onSurface,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                                      backgroundColor: AppColors.surfaceContainerLow,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: _onFaceIdLoginPressed,
                                    icon: const Icon(Icons.face_retouching_natural,
                                        color: AppColors.primaryContainer, size: 20),
                                    label: Text(
                                      'Face ID',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: AppColors.onSurface,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
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
                                minimumSize: const Size.fromHeight(42),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                backgroundColor: AppColors.surfaceContainerLow,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _onFaceIdLoginPressed,
                              icon: const Icon(Icons.face_retouching_natural,
                                  color: AppColors.primaryContainer, size: 20),
                              label: Text(
                                'Kiểm tra cảm biến Face ID',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Divider with Text
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'HOẶC TIẾP TỤC VỚI',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Google Sign-In Button
                    GoogleSignInButton(
                      onPressed: () {
                        context.read<AuthBloc>().add(AuthGoogleSignInRequested());
                      },
                    ),

                    const SizedBox(height: 24),

                    // Redirect to Register
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Chưa có tài khoản? ',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamed(AppRoutes.register);
                          },
                          child: Text(
                            'Đăng ký ngay',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppColors.primaryContainer,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Security Badges
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_user_outlined,
                            size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          'SOC2 Certified',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFFCBD5E1),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.lock_outline_rounded,
                            size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Text(
                          '256-bit TLS',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
