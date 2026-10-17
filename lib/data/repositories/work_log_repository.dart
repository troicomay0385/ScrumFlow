import '../models/task_model.dart';
import '../models/work_log_model.dart';

/// Interface cho Repository quản lý ghi nhận thời gian làm việc (Work Log) (US-066).
abstract class WorkLogRepository {
  /// Lắng nghe danh sách lịch sử ghi giờ theo [taskId].
  Stream<List<WorkLogModel>> streamWorkLogs(String taskId);

  /// Ghi nhận thời gian làm việc cho [task].
  Future<void> logWork({
    required TaskModel task,
    required String projectId,
    required double hours,
    required String note,
    required DateTime workDate,
  });
}
