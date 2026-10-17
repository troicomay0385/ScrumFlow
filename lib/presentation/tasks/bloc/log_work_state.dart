import 'package:equatable/equatable.dart';

/// Trạng thái của [LogWorkCubit] (US-066).
abstract class LogWorkState extends Equatable {
  const LogWorkState();

  bool get isIdle => this is LogWorkIdle;
  bool get isSubmitting => this is LogWorkSubmitting;
  bool get isSuccess => this is LogWorkSuccess;
  bool get isFailure => this is LogWorkFailure;

  @override
  List<Object?> get props => [];
}

/// Trạng thái ban đầu khi mở form ghi giờ.
class LogWorkIdle extends LogWorkState {
  const LogWorkIdle();
}

/// Đang gửi dữ liệu ghi giờ lên Firestore.
class LogWorkSubmitting extends LogWorkState {
  const LogWorkSubmitting();
}

/// Ghi giờ làm việc thành công.
class LogWorkSuccess extends LogWorkState {
  const LogWorkSuccess();
}

/// Ghi giờ làm việc thất bại kèm thông báo lỗi tiếng Việt.
class LogWorkFailure extends LogWorkState {
  final String message;

  const LogWorkFailure(this.message);

  @override
  List<Object?> get props => [message];
}
