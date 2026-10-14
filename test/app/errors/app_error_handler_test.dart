// US-063 — Phân loại lỗi và thông báo tiếng Việt an toàn.
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/app/errors/app_error_handler.dart';
import 'package:scrumflow/app/errors/app_failure.dart';

FirebaseException _fb(String code, [String? message]) =>
    FirebaseException(plugin: 'cloud_firestore', code: code, message: message);

void main() {
  group('AppErrorHandler.classify', () {
    test('TimeoutException → timeout, có thể thử lại', () {
      final f = AppErrorHandler.classify(TimeoutException('x'));
      expect(f.type, AppFailureType.timeout);
      expect(f.isRetryable, isTrue);
      expect(f.message, contains('quá lâu'));
    });

    test('network-request-failed → noConnection', () {
      final f = AppErrorHandler.classify(_fb('network-request-failed'));
      expect(f.type, AppFailureType.noConnection);
      expect(f.isRetryable, isTrue);
    });

    test('unavailable kèm "client is offline" → noConnection', () {
      final f = AppErrorHandler.classify(
        _fb(
          'unavailable',
          'Failed to get document because the client is offline.',
        ),
      );
      expect(f.type, AppFailureType.noConnection);
    });

    test('unavailable không do offline → server', () {
      final f = AppErrorHandler.classify(_fb('unavailable', 'Backend down'));
      expect(f.type, AppFailureType.server);
      expect(f.isRetryable, isTrue);
    });

    test('deadline-exceeded → timeout', () {
      expect(
        AppErrorHandler.classify(_fb('deadline-exceeded')).type,
        AppFailureType.timeout,
      );
    });

    test('internal / aborted / resource-exhausted → server', () {
      for (final code in ['internal', 'aborted', 'resource-exhausted']) {
        expect(
          AppErrorHandler.classify(_fb(code)).type,
          AppFailureType.server,
          reason: code,
        );
      }
    });

    test('permission-denied → permission, KHÔNG cho thử lại', () {
      final f = AppErrorHandler.classify(_fb('permission-denied'));
      expect(f.type, AppFailureType.permission);
      expect(f.isRetryable, isFalse);
      expect(f.message, contains('quyền'));
    });

    test('unauthenticated → auth, không cho thử lại', () {
      final f = AppErrorHandler.classify(_fb('unauthenticated'));
      expect(f.type, AppFailureType.auth);
      expect(f.isRetryable, isFalse);
    });

    test('not-found → notFound', () {
      expect(
        AppErrorHandler.classify(_fb('not-found')).type,
        AppFailureType.notFound,
      );
    });

    test('mã lỗi Auth đã biết (wrong-password) giữ thông báo của mapper', () {
      final f = AppErrorHandler.classify(
        FirebaseException(plugin: 'firebase_auth', code: 'wrong-password'),
      );
      expect(f.type, AppFailureType.validation);
      expect(f.message, 'Mật khẩu không chính xác. Vui lòng thử lại.');
    });

    test('mã Firebase lạ → unknown, không lộ mã kỹ thuật', () {
      final f = AppErrorHandler.classify(_fb('some-weird-code'));
      expect(f.type, AppFailureType.unknown);
      expect(f.message, isNot(contains('some-weird-code')));
    });

    test('chuỗi SocketException → noConnection (không cần dart:io)', () {
      final f = AppErrorHandler.classify(
        Exception(
          'SocketException: Failed host lookup: firestore.googleapis.com',
        ),
      );
      expect(f.type, AppFailureType.noConnection);
    });

    test('PlatformException mạng → noConnection', () {
      final f = AppErrorHandler.classify(
        PlatformException(code: 'network_error', message: 'ApiException: 7'),
      );
      expect(f.type, AppFailureType.noConnection);
    });

    test('Exception nghiệp vụ giữ nguyên thông báo tiếng Việt', () {
      final f = AppErrorHandler.classify(
        Exception('Chỉ PO/SM mới được bắt đầu Sprint.'),
      );
      expect(f.type, AppFailureType.validation);
      expect(f.message, 'Chỉ PO/SM mới được bắt đầu Sprint.');
      expect(f.isRetryable, isFalse);
    });

    test(
      'Error lập trình (StateError) → thông báo chung, không lộ chi tiết',
      () {
        final f = AppErrorHandler.classify(
          StateError('Bad state: secret detail'),
        );
        expect(f.type, AppFailureType.unknown);
        expect(f.message, isNot(contains('secret')));
      },
    );

    test('AppFailure truyền vào được giữ nguyên', () {
      const failure = AppFailure.noConnection();
      expect(identical(AppErrorHandler.classify(failure), failure), isTrue);
    });

    test('không thông báo nào chứa stack trace hay tên plugin', () {
      final inputs = <Object>[
        _fb('unavailable'),
        _fb('internal'),
        _fb('permission-denied'),
        TimeoutException('t'),
        StateError('x'),
      ];
      for (final input in inputs) {
        final message = AppErrorHandler.messageOf(input);
        expect(message, isNot(contains('cloud_firestore')));
        expect(message, isNot(contains('#0')));
        expect(message, isNot(contains('Exception')));
      }
    });
  });
}
