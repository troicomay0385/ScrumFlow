import 'package:flutter/material.dart';

/// Tiện ích phân bố giao diện thích ứng (Responsive UI - US-030)
///
/// Sử dụng [LayoutBuilder] để kiểm tra giới hạn kích thước theo Breakpoint:
/// - Mobile: < 600px
/// - Tablet / Desktop: >= 600px (Desktop rộng hơn >= 1024px nếu cần phân tách chi tiết)
class ResponsiveLayout extends StatelessWidget {
  /// Breakpoint mặc định cho thiết bị di động (< 600px)
  static const double mobileBreakpoint = 600.0;

  /// Breakpoint cho màn hình máy tính lớn / Desktop (>= 1024px)
  static const double desktopBreakpoint = 1024.0;

  /// Widget cho màn hình điện thoại (< 600px)
  final Widget? mobile;

  /// Widget cho máy tính bảng / màn hình lớn (>= 600px)
  final Widget? tablet;

  /// Widget cho máy tính để bàn (>= 1024px) - tùy chọn
  final Widget? desktop;

  /// Builder cho mobile nhận BoxConstraints
  final Widget Function(BuildContext context, BoxConstraints constraints)? mobileBuilder;

  /// Builder cho tablet nhận BoxConstraints
  final Widget Function(BuildContext context, BoxConstraints constraints)? tabletBuilder;

  /// Builder cho desktop nhận BoxConstraints
  final Widget Function(BuildContext context, BoxConstraints constraints)? desktopBuilder;

  const ResponsiveLayout({
    super.key,
    this.mobile,
    this.tablet,
    this.desktop,
    this.mobileBuilder,
    this.tabletBuilder,
    this.desktopBuilder,
  }) : assert(
          mobile != null || mobileBuilder != null,
          'Cần cung cấp ít nhất mobile hoặc mobileBuilder',
        );

  /// Kiểm tra nhanh màn hình hiện tại có phải là Mobile (< 600px) không
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < mobileBreakpoint;
  }

  /// Kiểm tra nhanh màn hình hiện tại có phải là Tablet / Desktop (>= 600px) không
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Kiểm tra nhanh màn hình hiện tại có phải là Desktop (>= 1024px) không
  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktopBreakpoint;
  }

  /// Kiểm tra nhanh thiết bị là màn hình lớn (Tablet hoặc Desktop >= 600px)
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= mobileBreakpoint;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Desktop breakpoint (>= 1024px)
        if (constraints.maxWidth >= desktopBreakpoint) {
          if (desktopBuilder != null) {
            return desktopBuilder!(context, constraints);
          }
          if (desktop != null) {
            return desktop!;
          }
        }

        // Tablet / Large screen breakpoint (>= 600px)
        if (constraints.maxWidth >= mobileBreakpoint) {
          if (tabletBuilder != null) {
            return tabletBuilder!(context, constraints);
          }
          if (tablet != null) {
            return tablet!;
          }
        }

        // Mobile fallback (< 600px)
        if (mobileBuilder != null) {
          return mobileBuilder!(context, constraints);
        }
        return mobile!;
      },
    );
  }
}
