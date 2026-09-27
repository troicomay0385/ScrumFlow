import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;

  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keySavedEmail = 'saved_email';
  static const String _keySavedPassword = 'saved_password';

  BiometricService({
    LocalAuthentication? localAuth,
    FlutterSecureStorage? secureStorage,
  })  : _localAuth = localAuth ?? LocalAuthentication(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Kiểm tra thiết bị có hỗ trợ phần cứng sinh trắc học và đã đăng ký vân tay/Face ID hay không.
  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Kiểm tra các loại sinh trắc học có sẵn trên thiết bị (vân tay, khuôn mặt, v.v.).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Thực hiện yêu cầu người dùng xác thực sinh trắc học (mặc định ưu tiên vân tay/sinh trắc học mạnh).
  Future<bool> authenticate({
    String localizedReason = 'Vui lòng quét vân tay hoặc Face ID để truy cập ScrumFlow',
  }) async {
    try {
      final available = await isBiometricAvailable();
      if (!available) return false;

      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Thực hiện xác thực chuyên biệt bằng Face ID / Nhận diện khuôn mặt.
  /// Trên Android, một số dòng máy phân loại Face Unlock là Weak Biometric,
  /// vì vậy biometricOnly = false sẽ cho phép kích hoạt camera nhận diện khuôn mặt.
  Future<bool> authenticateFaceId({
    String localizedReason = 'Nhìn thẳng vào camera trước để xác thực Face ID',
  }) async {
    try {
      final available = await isBiometricAvailable();
      if (!available) return false;

      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          sensitiveTransaction: false,
        ),
      );
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Trạng thái người dùng đã kích hoạt đăng nhập sinh trắc học trong app hay chưa.
  Future<bool> isBiometricLoginEnabled() async {
    final value = await _secureStorage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  /// Lưu thông tin đăng nhập an toàn để phục vụ đăng nhập sinh trắc học.
  Future<void> enableBiometricLogin({
    required String email,
    required String password,
  }) async {
    await _secureStorage.write(key: _keyBiometricEnabled, value: 'true');
    await _secureStorage.write(key: _keySavedEmail, value: email);
    await _secureStorage.write(key: _keySavedPassword, value: password);
  }

  /// Vô hiệu hoá đăng nhập sinh trắc học và xóa thông tin đã lưu an toàn.
  Future<void> disableBiometricLogin() async {
    await _secureStorage.write(key: _keyBiometricEnabled, value: 'false');
    await _secureStorage.delete(key: _keySavedEmail);
    await _secureStorage.delete(key: _keySavedPassword);
  }

  /// Lấy thông tin đăng nhập đã lưu trong Secure Storage.
  Future<Map<String, String>?> getSavedCredentials() async {
    final enabled = await isBiometricLoginEnabled();
    if (!enabled) return null;

    final email = await _secureStorage.read(key: _keySavedEmail);
    final password = await _secureStorage.read(key: _keySavedPassword);

    if (email != null && password != null && email.isNotEmpty && password.isNotEmpty) {
      return {'email': email, 'password': password};
    }
    return null;
  }
}
