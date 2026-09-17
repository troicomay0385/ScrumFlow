import 'package:flutter/material.dart';

/// Định nghĩa tên các route và hàm tạo route với animated transitions.
///
/// Phase 1 chỉ khai báo route names và hàm [generateRoute].
/// Các màn hình cụ thể (LoginScreen, RegisterScreen, HomeScreen)
/// sẽ được thêm trong Phase 2.
class AppRoutes {
  AppRoutes._();

  // ── Route names ────────────────────────────────────────────
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';

  /// Tạo route với fade + slide transition.
  ///
  /// [page] — widget màn hình đích.
  /// [duration] — thời gian animation (mặc định 400ms).
  static PageRouteBuilder buildRoute({
    required Widget page,
    required RouteSettings settings,
    Duration duration = const Duration(milliseconds: 400),
  }) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Kết hợp fade + slide từ dưới lên
        final fadeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(fadeAnimation);

        return FadeTransition(
          opacity: fadeAnimation,
          child: SlideTransition(
            position: slideAnimation,
            child: child,
          ),
        );
      },
    );
  }

  /// Placeholder [onGenerateRoute] — sẽ được hoàn thiện ở Phase 2
  /// khi có các Screen cụ thể.
  ///
  /// Hiện tại trả về route mặc định với Scaffold trống
  /// để tránh lỗi khi chạy app.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Phase 2 sẽ thêm switch-case cho từng route name.
    return buildRoute(
      settings: settings,
      page: const Scaffold(
        body: Center(child: Text('Route not found')),
      ),
    );
  }
}
