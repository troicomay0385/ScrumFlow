import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/project_model.dart';

/// DataSource cho Cloud Firestore collection `projects`.
///
/// Chỉ chứa CRUD thô trên collection `projects`. Không biết gì về
/// membership/role — phần đó thuộc [ProjectMemberDataSource] để giữ
/// đúng nguyên tắc mỗi datasource một trách nhiệm (giống
/// [FirestoreDataSource] chỉ lo `users`).
class ProjectDataSource {
  final FirebaseFirestore _firestore;

  ProjectDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _projectsCollection =>
      _firestore.collection('projects');

  /// Tạo project mới, trả về [ProjectModel] đã có `id`.
  Future<ProjectModel> createProject({
    required String name,
    required String description,
    required String createdBy,
  }) async {
    final docRef = _projectsCollection.doc();
    final now = DateTime.now();
    final project = ProjectModel(
      id: docRef.id,
      name: name,
      description: description,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );
    await docRef.set(project.toMap());
    return project;
  }

  /// Xoá project — chỉ dùng để rollback khi bootstrap PO membership
  /// thất bại ngay sau khi tạo project (xem `ProjectRepositoryImpl`).
  Future<void> deleteProject(String projectId) async {
    await _projectsCollection.doc(projectId).delete();
  }

  Future<ProjectModel?> getProject(String projectId) async {
    final doc = await _projectsCollection.doc(projectId).get();
    if (!doc.exists || doc.data() == null) return null;
    return ProjectModel.fromMap(doc.data()!);
  }

  /// Stream real-time cho 1 project (đổi tên/mô tả cập nhật ngay trên UI).
  Stream<ProjectModel?> streamProject(String projectId) {
    return _projectsCollection.doc(projectId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ProjectModel.fromMap(doc.data()!);
    });
  }

  /// Đọc nhiều project theo danh sách id (dùng cho màn hình "Project của tôi").
  ///
  /// Project không tồn tại (đã bị xoá) sẽ bị bỏ qua thay vì throw.
  Future<List<ProjectModel>> getProjectsByIds(List<String> projectIds) async {
    if (projectIds.isEmpty) return [];

    final results = await Future.wait(projectIds.map(getProject));
    return results.whereType<ProjectModel>().toList();
  }
}
