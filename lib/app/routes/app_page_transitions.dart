import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

/// Hiệu ứng chuyển trang thống nhất của ScrumFlow (US-064): fade + trượt
/// nhẹ từ dưới lên (4% chiều cao) với curve `easeOutCubic`.
///
/// - Dùng chung cho named route ([AppRoutes.buildRoute]) và mọi
///   `MaterialPageRoute` trong app (qua [ScrumFlowPageTransitionsBuilder]
///   đăng ký trong `AppTheme.pageTransitionsTheme`).
/// - Tôn trọng cài đặt "Giảm chuyển động" của hệ điều hành: khi
///   `MediaQuery.disableAnimations` bật thì chuyển trang tức thì.
/// - Chỉ dùng `FadeTransition` + `SlideTransition` (không rebuild cây con
///   mỗi khung hình) nên nhẹ trên máy cấu hình thấp.
class AppPageTransition {
  AppPageTransition._();

  static const Duration duration = Duration(milliseconds: 300);

  static Widget build(
    BuildContext context,
    Animation<double> animation,
    Widget child,
  ) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// [PageTransitionsBuilder] áp dụng [AppPageTransition] cho mọi
/// `MaterialPageRoute` — không phải sửa từng chỗ `Navigator.push`.
class ScrumFlowPageTransitionsBuilder extends PageTransitionsBuilder {
  const ScrumFlowPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return AppPageTransition.build(context, animation, child);
  }
}

/// Theme chuyển trang của app. iOS/macOS giữ hiệu ứng Cupertino để không
/// mất thao tác vuốt từ mép trái để quay lại (hành vi Back quen thuộc).
const PageTransitionsTheme appPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: ScrumFlowPageTransitionsBuilder(),
    TargetPlatform.fuchsia: ScrumFlowPageTransitionsBuilder(),
    TargetPlatform.windows: ScrumFlowPageTransitionsBuilder(),
    TargetPlatform.linux: ScrumFlowPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
  },
);
