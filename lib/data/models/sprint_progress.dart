import 'package:equatable/equatable.dart';

import '../../app/constants/task_status.dart';
import 'task_model.dart';

/// Thống kê tiến độ Sprint dựa trên các task (US-065).
class SprintProgress extends Equatable {
  final int todo;
  final int inProgress;
  final int done;

  const SprintProgress({
    this.todo = 0,
    this.inProgress = 0,
    this.done = 0,
  });

  /// Tổng số task trong Sprint.
  int get total => todo + inProgress + done;

  /// Tỷ lệ hoàn thành nhiệm vụ (0..100%), làm tròn số nguyên, trả về 0 nếu total == 0.
  int get donePercent => total == 0 ? 0 : ((done / total) * 100).round();

  /// Kiểm tra có task nào trong Sprint hay không.
  bool get isEmpty => total == 0;

  /// Tạo [SprintProgress] từ danh sách TaskModel.
  /// Status lạ hoặc không khớp được chuẩn hoá vào nhóm 'To Do'.
  factory SprintProgress.fromTasks(List<TaskModel> tasks) {
    int todoCount = 0;
    int inProgressCount = 0;
    int doneCount = 0;

    for (final task in tasks) {
      final normalized = TaskStatus.normalize(task.status);
      switch (normalized) {
        case TaskStatus.inProgress:
          inProgressCount++;
          break;
        case TaskStatus.done:
          doneCount++;
          break;
        case TaskStatus.todo:
        default:
          todoCount++;
          break;
      }
    }

    return SprintProgress(
      todo: todoCount,
      inProgress: inProgressCount,
      done: doneCount,
    );
  }

  @override
  List<Object?> get props => [todo, inProgress, done];
}
