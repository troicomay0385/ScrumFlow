// US-063 — Timeout cho lần phát dữ liệu đầu tiên của stream.
//
// Dùng thời gian thật rất ngắn (vài chục ms) để không phải thêm
// dependency fake_async vào pubspec.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/app/errors/stream_timeout.dart';

const _timeout = Duration(milliseconds: 40);

Future<void> _wait([int ms = 80]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  group('timeoutFirstEvent', () {
    test('phát TimeoutException nếu không có dữ liệu trong thời hạn', () async {
      final source = StreamController<int>();
      final errors = <Object>[];
      final sub = source.stream
          .timeoutFirstEvent(_timeout)
          .listen((_) {}, onError: errors.add);

      await _wait();
      expect(errors.single, isA<TimeoutException>());
      await sub.cancel();
      await source.close();
    });

    test(
      'dữ liệu đến sau timeout vẫn được chuyển tiếp (tự hồi phục)',
      () async {
        final source = StreamController<int>();
        final events = <Object>[];
        final sub = source.stream
            .timeoutFirstEvent(_timeout)
            .listen(events.add, onError: events.add);

        await _wait();
        source.add(42);
        await _wait(10);
        expect(events.first, isA<TimeoutException>());
        expect(events.last, 42);
        await sub.cancel();
        await source.close();
      },
    );

    test('đã có dữ liệu thì không còn timeout', () async {
      final source = StreamController<int>();
      final errors = <Object>[];
      final data = <int>[];
      final sub = source.stream
          .timeoutFirstEvent(_timeout)
          .listen(data.add, onError: errors.add);

      source.add(1);
      await _wait(150);
      expect(data, [1]);
      expect(errors, isEmpty);
      await sub.cancel();
      await source.close();
    });

    test('lỗi từ nguồn được chuyển tiếp và huỷ đồng hồ timeout', () async {
      final source = StreamController<int>();
      final errors = <Object>[];
      final sub = source.stream
          .timeoutFirstEvent(_timeout)
          .listen((_) {}, onError: errors.add);

      source.addError(StateError('boom'));
      await _wait(150);
      expect(errors.single, isA<StateError>());
      await sub.cancel();
      await source.close();
    });

    test('huỷ subscription thì huỷ luôn subscription nguồn', () async {
      var cancelled = false;
      final source = StreamController<int>(onCancel: () => cancelled = true);
      final sub = source.stream.timeoutFirstEvent(_timeout).listen((_) {});
      await sub.cancel();
      expect(cancelled, isTrue);
      await source.close();
    });
  });
}
