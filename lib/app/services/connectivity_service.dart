import 'package:connectivity_plus/connectivity_plus.dart';

/// Dịch vụ kiểm tra trạng thái kết nối mạng.
///
/// **Chỉ là pre-check** — dùng để hiện thông báo sớm cho người dùng
/// khi chắc chắn không có mạng. Không thay thế try/catch vì:
/// - Mạng có thể mất giữa chừng sau khi check
/// - connectivity_plus có thể báo sai trên một số thiết bị
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
    // connectivity_plus trả về List<ConnectivityResult>
    // Nếu chỉ chứa none hoặc rỗng → không có mạng
    return results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);
  }
}
