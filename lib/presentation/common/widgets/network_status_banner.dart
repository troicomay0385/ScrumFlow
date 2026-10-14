import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';

/// Dải thông báo trạng thái mạng hiển thị trên đầu mọi màn hình (US-063).
///
/// Bọc toàn bộ app qua `MaterialApp.builder`. Khi thiết bị mất kết nối, dải
/// màu cam "Không có kết nối mạng" hiện ra; khi có mạng lại, dải xanh "Đã
/// kết nối lại" hiện ngắn rồi tự ẩn.
///
/// Lưu ý: trạng thái lấy từ `connectivity_plus` — chỉ phản ánh thiết bị có
/// Wi-Fi/4G hay không, KHÔNG đảm bảo truy cập được máy chủ. Trường hợp có
/// mạng nhưng máy chủ không phản hồi được xử lý bằng timeout ở từng màn.
class NetworkStatusBanner extends StatefulWidget {
  /// Stream `true` = có mạng, `false` = mất mạng.
  final Stream<bool> statusStream;
  final Widget child;

  /// Thời gian hiển thị dải "Đã kết nối lại".
  final Duration reconnectedDisplay;

  const NetworkStatusBanner({
    super.key,
    required this.statusStream,
    required this.child,
    this.reconnectedDisplay = const Duration(seconds: 3),
  });

  @override
  State<NetworkStatusBanner> createState() => _NetworkStatusBannerState();
}

enum _BannerMode { hidden, offline, reconnected }

class _NetworkStatusBannerState extends State<NetworkStatusBanner> {
  StreamSubscription<bool>? _subscription;
  Timer? _hideTimer;
  _BannerMode _mode = _BannerMode.hidden;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(covariant NetworkStatusBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statusStream != widget.statusStream) {
      _subscription?.cancel();
      _listen();
    }
  }

  void _listen() {
    _subscription = widget.statusStream.listen(
      _onStatus,
      // Lỗi từ plugin không được làm hỏng UI — bỏ qua, giữ trạng thái cũ.
      onError: (_) {},
    );
  }

  void _onStatus(bool online) {
    if (!mounted) return;
    _hideTimer?.cancel();
    if (!online) {
      setState(() => _mode = _BannerMode.offline);
      return;
    }
    // Chỉ báo "đã kết nối lại" nếu trước đó thực sự đang offline.
    if (_mode != _BannerMode.offline) return;
    setState(() => _mode = _BannerMode.reconnected);
    _hideTimer = Timer(widget.reconnectedDisplay, () {
      if (mounted) setState(() => _mode = _BannerMode.hidden);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Column(
      children: [
        AnimatedSize(
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: _mode == _BannerMode.hidden
              ? const SizedBox(width: double.infinity)
              : _Banner(offline: _mode == _BannerMode.offline),
        ),
        Expanded(
          // Dải banner đã chiếm phần tai thỏ/status bar nên bỏ padding top
          // để các Scaffold bên dưới không chừa trống thêm lần nữa.
          child: _mode == _BannerMode.hidden
              ? widget.child
              : MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: widget.child,
                ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  final bool offline;

  const _Banner({required this.offline});

  @override
  Widget build(BuildContext context) {
    final color = offline ? AppColors.warning : AppColors.success;
    final text = offline
        ? 'Không có kết nối mạng. Dữ liệu có thể chưa được cập nhật.'
        : 'Đã kết nối lại.';
    return Material(
      color: color,
      child: SafeArea(
        bottom: false,
        child: Semantics(
          liveRegion: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Icon(
                  offline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
