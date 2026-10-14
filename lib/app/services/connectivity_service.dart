import 'package:connectivity_plus/connectivity_plus.dart';

/// Dịch vụ kiểm tra trạng thái kết nối mạng.
///
/// **Chỉ là pre-check** — dùng để hiện thông báo sớm cho người dùng
/// khi chắc chắn không có mạng. Không thay thế try/catch vì:
/// - Mạng có thể mất giữa chừng sau khi check
/// - connectivity_plus có thể báo sai trên một số thiết bị
/// - "Có Wi-Fi" không có nghĩa là truy cập được máy chủ (captive portal,
///   DNS lỗi...) — trường hợp đó được bắt bằng timeout (US-063).
///
/// Repository vẫn luôn bọc mọi Firebase call trong try/catch.
class ConnectivityService {
  final Connectivity _connectivity;

  ConnectivityService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  /// Kiểm tra thiết bị có kết nối mạng hay không.
  ///
  /// Trả về `true` nếu có wifi, mobile data, ethernet, hoặc VPN.
  /// Trả về `false` nếu không có kết nối nào (ConnectivityResult.none).
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  /// Giống [checkConnectivity] nhưng không bao giờ throw: nếu plugin lỗi
  /// (vd. chạy trong môi trường không hỗ trợ) thì coi như **có mạng** để
  /// request thật quyết định — tránh chặn người dùng vì lỗi của pre-check.
  Future<bool> isOnline() async {
    try {
      return await checkConnectivity();
    } catch (_) {
      return true;
    }
  }

  /// Phát `true`/`false` mỗi khi trạng thái có/không có mạng thay đổi.
  Stream<bool> get onStatusChanged =>
      _connectivity.onConnectivityChanged.map(_hasConnection).distinct();

  // connectivity_plus trả về List<ConnectivityResult>
  // Nếu chỉ chứa none hoặc rỗng → không có mạng
  static bool _hasConnection(List<ConnectivityResult> results) =>
      results.isNotEmpty && !results.every((r) => r == ConnectivityResult.none);
}
