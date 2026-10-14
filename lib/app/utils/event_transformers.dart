import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Event transformer kiểu "restartable": khi có event mới, huỷ việc xử lý
/// event trước (kể cả `emit.forEach` đang lắng nghe stream) rồi mới chạy
/// event mới.
///
/// Dùng cho các event subscribe/tải lại dữ liệu để bấm "Thử lại" nhiều lần
/// không tạo ra nhiều subscription chạy song song (US-063). Tự viết thay vì
/// thêm package `bloc_concurrency` vì chỉ cần đúng một transformer này.
EventTransformer<E> restartable<E>() {
  return (events, mapper) {
    StreamSubscription<E>? outerSubscription;
    StreamSubscription<E>? innerSubscription;
    var outerDone = false;
    late final StreamController<E> controller;

    controller = StreamController<E>(
      sync: true,
      onListen: () {
        outerSubscription = events.listen(
          (event) {
            innerSubscription?.cancel();
            innerSubscription = mapper(event).listen(
              controller.add,
              onError: controller.addError,
              onDone: () {
                innerSubscription = null;
                if (outerDone) controller.close();
              },
            );
          },
          onError: controller.addError,
          onDone: () {
            outerDone = true;
            if (innerSubscription == null) controller.close();
          },
        );
      },
      onCancel: () async {
        await innerSubscription?.cancel();
        await outerSubscription?.cancel();
      },
    );
    return controller.stream;
  };
}
