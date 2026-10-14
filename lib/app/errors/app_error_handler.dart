import 'dart:async';

import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/services.dart' show PlatformException;

import '../constants/firebase_error_mapper.dart';
import 'app_failure.dart';

/// Chuyển mọi lỗi (Firebase, timeout, lỗi mạng, Exception nghiệp vụ) về
/// [AppFailure] có thông báo tiếng Việt an toàn (US-063).
///
/// App gọi Firebase trực tiếp (không có HTTP client riêng) nên việc phân
/// loại dựa trên `FirebaseException.code` là chính; các chuỗi lỗi mạng
/// cấp thấp (SocketException, XMLHttpRequest...) được nhận diện qua nội
/// dung để không phải import `dart:io` (không chạy được trên Web).
class AppErrorHandler {
  AppErrorHandler._();

  static const _networkHints = [
    'socketexception',
    'failed host lookup',
    'network is unreachable',
    'connection refused',
    'connection reset',
    'connection closed',
    'xmlhttprequest error',
    'client is offline',
    'network-request-failed',
    'network error',
  ];

  static AppFailure classify(Object error) {
    if (error is AppFailure) return error;
    if (error is TimeoutException) return const AppFailure.timeout();
    if (error is FirebaseException) {
      return _fromFirebaseCode(error.code, error.message);
    }
    if (error is PlatformException) {
      // Google Sign-In báo mất mạng bằng mã `network_error` /
      // `ApiException: 7` (CommonStatusCodes.NETWORK_ERROR).
      final text = '${error.code} ${error.message}'.toLowerCase();
      if (_looksLikeNetworkError(text) ||
          text.contains('network') ||
          text.contains('apiexception: 7')) {
        return const AppFailure.noConnection();
      }
      return AppFailure(
        AppFailureType.server,
        FirebaseErrorMapper.mapPlatformError(error.code, error.message),
      );
    }

    final raw = error.toString();
    if (_looksLikeNetworkError(raw)) return const AppFailure.noConnection();

    // Repository trong app ném `Exception('<thông báo tiếng Việt>')` cho
    // lỗi nghiệp vụ (không có quyền, sprint chưa Active...). Thông báo đó
    // vốn dành cho người dùng nên giữ nguyên.
    if (error is Exception && raw.startsWith('Exception: ')) {
      final message = raw.substring('Exception: '.length).trim();
      if (message.isNotEmpty) {
        return AppFailure(AppFailureType.validation, message);
      }
    }

    // Error (TypeError, StateError...) là lỗi lập trình — không hiển thị
    // chi tiết kỹ thuật cho người dùng.
    return const AppFailure.unknown();
  }

  /// Thông báo hiển thị cho người dùng, tiện cho các Bloc chỉ cần chuỗi.
  static String messageOf(Object error) => classify(error).message;

  static bool _looksLikeNetworkError(String text) {
    final lower = text.toLowerCase();
    return _networkHints.any(lower.contains);
  }

  static AppFailure _fromFirebaseCode(String code, String? message) {
    final normalized = code.trim().toLowerCase().replaceAll('_', '-');
    switch (normalized) {
      case 'network-request-failed':
        return const AppFailure.noConnection();
      case 'unavailable':
        // Firestore trả `unavailable` cả khi client offline lẫn khi
        // backend tạm sập — phân biệt bằng nội dung thông báo.
        if (_looksLikeNetworkError(message ?? '')) {
          return const AppFailure.noConnection();
        }
        return const AppFailure.server();
      case 'deadline-exceeded':
        return const AppFailure.timeout();
      case 'internal':
      case 'internal-error':
      case 'unknown':
      case 'aborted':
      case 'data-loss':
      case 'resource-exhausted':
      case 'cancelled':
        return const AppFailure.server();
      case 'permission-denied':
        return AppFailure(
          AppFailureType.permission,
          FirebaseErrorMapper.mapErrorCode(normalized),
        );
      case 'unauthenticated':
      case 'user-token-expired':
      case 'requires-recent-login':
      case 'user-disabled':
        return const AppFailure(
          AppFailureType.auth,
          'Phiên đăng nhập đã hết hạn hoặc không hợp lệ. '
          'Vui lòng đăng nhập lại.',
        );
      case 'not-found':
        return AppFailure(
          AppFailureType.notFound,
          FirebaseErrorMapper.mapErrorCode(normalized),
        );
      case 'invalid-argument':
      case 'failed-precondition':
      case 'already-exists':
      case 'out-of-range':
        return const AppFailure(
          AppFailureType.validation,
          'Dữ liệu không hợp lệ hoặc không thể xử lý lúc này. '
          'Vui lòng kiểm tra lại.',
        );
      default:
        // Mã lỗi Auth (sai mật khẩu, email đã dùng...) đã có thông báo
        // riêng trong FirebaseErrorMapper.
        final mapped = FirebaseErrorMapper.mapErrorCode(normalized);
        if (mapped.startsWith('Đã xảy ra lỗi hệ thống (')) {
          return const AppFailure.unknown();
        }
        return AppFailure(AppFailureType.validation, mapped);
    }
  }
}
