import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/errors/app_failure.dart';

/// Bộ widget trạng thái dùng chung (US-063 / US-064): loading, lỗi kèm
/// "Thử lại", và danh sách rỗng — để các màn hình hiển thị nhất quán thay
/// vì mỗi màn tự dựng một kiểu.
///
/// Mọi view đều cuộn được, nên dùng được trong `RefreshIndicator` và không
/// bị tràn trên màn hình thấp / khi tăng cỡ chữ (US-055).

/// Vòng loading ở giữa vùng nội dung, kèm dòng mô tả tuỳ chọn.
class AppLoadingView extends StatelessWidget {
  final String? message;

  const AppLoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: message ?? 'Đang tải dữ liệu',
        liveRegion: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.primary,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Khung cuộn được, căn giữa nội dung khi còn chỗ — dùng chung cho
/// [AppErrorView] và [AppEmptyView].
class _CenteredScrollable extends StatelessWidget {
  final Widget child;

  const _CenteredScrollable({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.hasBoundedHeight
                ? (constraints.maxHeight - 64).clamp(0, double.infinity)
                : 0,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _StateIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _StateIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 44, color: color),
    );
  }
}

/// Hiển thị lỗi thân thiện + nút "Thử lại" (US-063).
///
/// Nút bị khoá ngay sau lần bấm đầu tiên cho tới khi widget được dựng lại
/// với lỗi mới, nên bấm liên tục không gửi nhiều request trùng lặp.
class AppErrorView extends StatefulWidget {
  final String message;
  final AppFailureType type;

  /// `null` = lỗi không nên thử lại (vd. không có quyền) → ẩn nút.
  final VoidCallback? onRetry;

  final String? title;

  const AppErrorView({
    super.key,
    required this.message,
    this.type = AppFailureType.unknown,
    this.onRetry,
    this.title,
  });

  /// Tạo từ [AppFailure]; tự ẩn nút "Thử lại" nếu lỗi không thể thử lại.
  factory AppErrorView.fromFailure(
    AppFailure failure, {
    Key? key,
    VoidCallback? onRetry,
  }) {
    return AppErrorView(
      key: key,
      message: failure.message,
      type: failure.type,
      onRetry: failure.isRetryable ? onRetry : null,
    );
  }

  @override
  State<AppErrorView> createState() => _AppErrorViewState();
}

class _AppErrorViewState extends State<AppErrorView> {
  bool _retrying = false;

  @override
  void didUpdateWidget(covariant AppErrorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message || oldWidget.type != widget.type) {
      _retrying = false;
    }
  }

  void _handleRetry() {
    if (_retrying || widget.onRetry == null) return;
    setState(() => _retrying = true);
    widget.onRetry!();
  }

  (IconData, Color, String) get _visual {
    switch (widget.type) {
      case AppFailureType.noConnection:
        return (Icons.wifi_off_rounded, AppColors.warning, 'Mất kết nối mạng');
      case AppFailureType.timeout:
        return (
          Icons.hourglass_bottom_rounded,
          AppColors.warning,
          'Hết thời gian chờ',
        );
      case AppFailureType.server:
        return (
          Icons.cloud_off_rounded,
          AppColors.error,
          'Máy chủ không phản hồi',
        );
      case AppFailureType.permission:
        return (Icons.lock_outline_rounded, AppColors.error, 'Không có quyền');
      case AppFailureType.auth:
        return (
          Icons.person_off_outlined,
          AppColors.error,
          'Phiên đăng nhập không hợp lệ',
        );
      case AppFailureType.notFound:
        return (
          Icons.search_off_rounded,
          AppColors.onSurfaceVariant,
          'Không tìm thấy dữ liệu',
        );
      case AppFailureType.validation:
      case AppFailureType.unknown:
        return (
          Icons.error_outline_rounded,
          AppColors.error,
          'Không thể tải dữ liệu',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color, defaultTitle) = _visual;
    return _CenteredScrollable(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StateIcon(icon: icon, color: color),
          const SizedBox(height: 16),
          Text(
            widget.title ?? defaultTitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.45,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _retrying ? null : _handleRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: _retrying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(_retrying ? 'Đang thử lại...' : 'Thử lại'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Trạng thái không có dữ liệu, kèm hành động gợi ý tuỳ chọn.
class AppEmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const AppEmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return _CenteredScrollable(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StateIcon(icon: icon, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.onSurface,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.45,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}
