import 'dart:async';

/// Timeout cho **lần phát dữ liệu đầu tiên** của stream (US-063).
///
/// Firestore `snapshots()` không tự báo lỗi khi mạng chậm/không tới được
/// máy chủ — nó chỉ "im lặng", khiến UI loading vô tận. Extension này phát
/// [TimeoutException] nếu sau [duration] chưa có dữ liệu nào, nhưng **vẫn
/// giữ** subscription: khi mạng hồi phục và Firestore đẩy dữ liệu về, UI tự
/// chuyển sang trạng thái thành công mà không cần tạo request mới.
///
/// Sau khi đã nhận dữ liệu đầu tiên thì không còn timeout nữa (stream
/// real-time có thể im lặng rất lâu một cách hợp lệ).
extension FirstEventTimeout<T> on Stream<T> {
  Stream<T> timeoutFirstEvent(Duration duration) {
    StreamSubscription<T>? subscription;
    Timer? timer;
    late final StreamController<T> controller;

    void stopTimer() {
      timer?.cancel();
      timer = null;
    }

    controller = StreamController<T>(
      onListen: () {
        timer = Timer(duration, () {
          timer = null;
          controller.addError(
            TimeoutException('Không nhận được dữ liệu', duration),
          );
        });
        subscription = listen(
          (data) {
            stopTimer();
            controller.add(data);
          },
          onError: (Object error, StackTrace stackTrace) {
            stopTimer();
            controller.addError(error, stackTrace);
          },
          onDone: () {
            stopTimer();
            controller.close();
          },
        );
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () {
        stopTimer();
        return subscription?.cancel();
      },
    );
    return controller.stream;
  }
}
