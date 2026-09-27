import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/app/constants/firebase_error_mapper.dart';

void main() {
  group('FirebaseErrorMapper', () {
    test('mapping standard error codes', () {
      expect(
        FirebaseErrorMapper.mapErrorCode('invalid-credential'),
        contains('Thông tin đăng nhập không hợp lệ'),
      );
      expect(
        FirebaseErrorMapper.mapErrorCode('user-not-found'),
        contains('Không tìm thấy tài khoản'),
      );
      expect(
        FirebaseErrorMapper.mapErrorCode('wrong-password'),
        contains('Mật khẩu không chính xác'),
      );
    });

    test('mapping uppercase and underscored error codes from Firebase SDKs', () {
      expect(
        FirebaseErrorMapper.mapErrorCode('INVALID_LOGIN_CREDENTIALS'),
        contains('Thông tin đăng nhập không hợp lệ'),
      );
      expect(
        FirebaseErrorMapper.mapErrorCode('invalid_login_credentials'),
        contains('Thông tin đăng nhập không hợp lệ'),
      );
      expect(
        FirebaseErrorMapper.mapErrorCode('USER_NOT_FOUND'),
        contains('Không tìm thấy tài khoản'),
      );
    });

    test('mapping network and system error codes', () {
      expect(
        FirebaseErrorMapper.mapErrorCode('channel-error'),
        contains('Thông tin nhập vào không hợp lệ'),
      );
      expect(
        FirebaseErrorMapper.mapErrorCode('permission-denied'),
        contains('Không có quyền truy cập'),
      );
      expect(
        FirebaseErrorMapper.mapErrorCode('internal-error'),
        contains('lỗi hệ thống'),
      );
    });
  });
}
