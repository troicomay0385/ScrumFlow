import '../../../data/repositories/sprint_repository.dart';

/// Use case khởi động Sprint (US-049).
///
/// Chuyển Sprint từ trạng thái "Planned" → "Active".
/// Ràng buộc:
/// - Chỉ PO/SM mới được thực hiện (kiểm tra ở Repository).
/// - Chỉ được phép có 1 Sprint "Active" trong 1 project tại 1 thời điểm.
/// - Sprint phải có ít nhất 1 User Story.
class StartSprintUseCase {
  final SprintRepository _repository;

  StartSprintUseCase(this._repository);

  Future<void> call({
    required String projectId,
    required String sprintId,
    required DateTime startDate,
    required DateTime endDate,
  }) =>
      execute(
        projectId: projectId,
        sprintId: sprintId,
        startDate: startDate,
        endDate: endDate,
      );

  Future<void> execute({
    required String projectId,
    required String sprintId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (projectId.trim().isEmpty) {
      throw Exception('projectId không hợp lệ (bị rỗng).');
    }
    if (sprintId.trim().isEmpty) {
      throw Exception('sprintId không hợp lệ (bị rỗng).');
    }
    if (!endDate.isAfter(startDate)) {
      throw Exception('Ngày kết thúc phải sau ngày bắt đầu.');
    }

    await _repository.startSprint(
      projectId: projectId,
      sprintId: sprintId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
