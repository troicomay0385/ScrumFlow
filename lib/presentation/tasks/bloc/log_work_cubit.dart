// ignore_for_file: prefer_initializing_formals
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/utils/work_log_validator.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/work_log_repository.dart';
import 'log_work_state.dart';

/// Cubit quản lý nghiệp vụ ghi nhận thời gian làm việc (Work Log) cho Task (US-066).
class LogWorkCubit extends Cubit<LogWorkState> {
  final WorkLogRepository _repository;
  final TaskModel _task;
  final String _projectId;

  LogWorkCubit({
    required WorkLogRepository repository,
    required TaskModel task,
    required String projectId,
  })  : _repository = repository,
        _task = task,
        _projectId = projectId,
        super(const LogWorkIdle());

  /// Gửi bản ghi log work.
  ///
  /// - Bỏ qua khi đang submitting hoặc đã success (chống bấm submit lặp).
  /// - Kiểm tra tính hợp lệ bằng [WorkLogValidator] trước khi gọi repository.
  /// - Hiển thị thông báo lỗi tiếng Việt nếu gặp sự cố.
  Future<void> submit({
    required double? hours,
    required String note,
    required DateTime workDate,
  }) async {
    // Chống bấm lặp khi đang xử lý hoặc đã hoàn tất thành công
    if (state is LogWorkSubmitting || state is LogWorkSuccess) {
      return;
    }

    final hoursError = WorkLogValidator.validateHours(hours);
    if (hoursError != null) {
      emit(LogWorkFailure(hoursError));
      return;
    }

    final noteError = WorkLogValidator.validateNote(note);
    if (noteError != null) {
      emit(LogWorkFailure(noteError));
      return;
    }

    final dateError = WorkLogValidator.validateWorkDate(workDate);
    if (dateError != null) {
      emit(LogWorkFailure(dateError));
      return;
    }

    emit(const LogWorkSubmitting());
    try {
      await _repository.logWork(
        task: _task,
        projectId: _projectId,
        hours: hours!,
        note: note,
        workDate: workDate,
      );
      if (isClosed) return;
      emit(const LogWorkSuccess());
    } catch (e) {
      if (isClosed) return;
      final raw = e.toString();
      final message = raw.startsWith('Exception: ')
          ? raw.substring('Exception: '.length).trim()
          : raw;
      emit(LogWorkFailure(
        message.isEmpty ? 'Không thể ghi nhận giờ làm việc.' : message,
      ));
    }
  }
}
