import '../models/project_model.dart';
import '../models/project_summary.dart';

/// Interface cho Project Repository.
///
/// Giống [AuthRepository] — UI/Bloc chỉ phụ thuộc interface này,
/// không biết Firestore nằm phía sau.
abstract class ProjectRepository {
  /// Tạo project mới. User hiện tại tự động trở thành PO (project admin)
  /// của project vừa tạo.
  Future<ProjectModel> createProject({
    required String name,
    required String description,
  });

  /// Danh sách project mà user hiện tại là thành viên, kèm role của họ.
  Future<List<ProjectSummary>> getMyProjects();

  Future<ProjectModel?> getProject(String projectId);

  /// Stream real-time cho 1 project.
  Stream<ProjectModel?> streamProject(String projectId);
}
