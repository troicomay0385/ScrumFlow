import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskRepository {
  final FirebaseFirestore _firestore;

  TaskRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _tasksRef => _firestore.collection('tasks');

  // ── Streams ────────────────────────────────────────────────────────────────

  /// Stream realtime tất cả tasks của 1 User Story.
  /// Không dùng orderBy để tránh yêu cầu Composite Index trên Firestore.
  Stream<List<TaskModel>> streamTasksByStory(String storyId) {
    return _tasksRef
        .where('storyId', isEqualTo: storyId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return TaskModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
            }).toList());
  }

  // ── Write Operations ───────────────────────────────────────────────────────

  /// Tạo Task mới và lưu lên Firestore.
  Future<TaskModel> createTask({
    required String storyId,
    required String title,
    String description = '',
    String? assigneeId,
    String? assigneeName,
  }) async {
    final now = DateTime.now();
    final docRef = _tasksRef.doc(); // auto-generate ID

    final newTask = TaskModel(
      id: docRef.id,
      storyId: storyId,
      title: title,
      description: description,
      status: 'To Do',
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      createdAt: now,
      updatedAt: now,
    );

    // Lưu dùng Timestamp Firestore thay vì ISO string để nhất quán
    await docRef.set({
      'id': newTask.id,
      'storyId': newTask.storyId,
      'title': newTask.title,
      'description': newTask.description,
      'status': newTask.status,
      'assigneeId': newTask.assigneeId,
      'assigneeName': newTask.assigneeName,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    return newTask;
  }

  /// Cập nhật trạng thái task (dùng cho Drag & Drop).
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    await _tasksRef.doc(taskId).update({
      'status': newStatus,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Cập nhật toàn bộ thông tin task.
  Future<void> updateTask(TaskModel task) async {
    final updated = task.copyWith(updatedAt: DateTime.now());
    await _tasksRef.doc(task.id).update({
      'title': updated.title,
      'description': updated.description,
      'status': updated.status,
      'assigneeId': updated.assigneeId,
      'assigneeName': updated.assigneeName,
      'updatedAt': Timestamp.fromDate(updated.updatedAt),
    });
  }

  /// Xóa task.
  Future<void> deleteTask(String taskId) async {
    await _tasksRef.doc(taskId).delete();
  }
}
