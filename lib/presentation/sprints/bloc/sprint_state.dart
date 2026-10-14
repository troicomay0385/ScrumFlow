import 'package:equatable/equatable.dart';
import '../../../app/errors/app_failure.dart';
import '../../../data/models/sprint_model.dart';

abstract class SprintState extends Equatable {
  const SprintState();

  @override
  List<Object?> get props => [];
}

class SprintActionCompleted extends SprintState {
  final String message;
  final List<SprintModel> sprints;

  const SprintActionCompleted(this.message, {this.sprints = const []});

  @override
  List<Object?> get props => [message, sprints];
}

class SprintInitial extends SprintState {}

class SprintLoading extends SprintState {}

class SprintLoaded extends SprintState {
  final List<SprintModel> sprints;

  const SprintLoaded({required this.sprints});

  @override
  List<Object?> get props => [sprints];
}

class SprintError extends SprintState {
  final String message;
  final List<SprintModel> sprints;

  const SprintError(this.message, {this.sprints = const []});

  @override
  List<Object?> get props => [message, sprints];
}

/// Không tải được danh sách Sprint lần đầu (mất mạng, timeout, lỗi máy chủ…).
///
/// Tách riêng khỏi [SprintError] (lỗi của một thao tác như tạo/bắt đầu
/// Sprint, hiển thị bằng SnackBar) để màn hình hiện trạng thái lỗi toàn
/// trang kèm nút "Thử lại" (US-063).
class SprintLoadFailure extends SprintState {
  final AppFailure failure;

  const SprintLoadFailure(this.failure);

  @override
  List<Object?> get props => [failure.type, failure.message];
}
