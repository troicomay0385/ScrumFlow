import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/constants/firebase_error_mapper.dart';
import '../models/task_model.dart';
import 'notification_repository.dart';

class TaskRepository {
  final FirebaseFirestore _firestore;
  final NotificationRepository? _notificationRepository;

  TaskRepository({
    FirebaseFirestore? firestore,
    NotificationRepository? notificationRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationRepository = notificationRepository ??
            NotificationRepository(firestore: firestore ?? FirebaseFirestore.instance);

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

  /// Stream realtime 1 task (màn Task Detail). Emit `null` nếu task đã bị xoá.
  Stream<TaskModel?> streamTask(String taskId) {
    return _tasksRef.doc(taskId).snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>?;
      if (!doc.exists || data == null) return null;
      return TaskModel.fromMap(data, doc.id);
    });
  }

  // ── Write Operations ───────────────────────────────────────────────────────

  /// Tạo Task mới và lưu lên Firestore.
  Future<TaskModel> createTask({
    required String storyId,
    required String title,
    String description = '',
    String? assigneeId,
    String? assigneeName,
    String? projectId,
    DateTime? deadline,
  }) async {
    final now = DateTime.now();
    final docRef = _tasksRef.doc(); // auto-generate ID

    final newTask = TaskModel(
      id: docRef.id,
      storyId: storyId,
      projectId: projectId,
      title: title,
      description: description,
      status: 'To Do',
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      deadline: deadline,
      createdAt: now,
      updatedAt: now,
    );

    // Lưu dùng Timestamp Firestore thay vì ISO string để nhất quán
    await docRef.set({
      'id': newTask.id,
      'storyId': newTask.storyId,
      'projectId': ?projectId,
      'title': newTask.title,
      'description': newTask.description,
      'status': newTask.status,
      'assigneeId': newTask.assigneeId,
      'assigneeName': newTask.assigneeName,
      'deadline': deadline != null ? Timestamp.fromDate(deadline) : null,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });

    if (_notificationRepository != null && assigneeId != null && assigneeId.isNotEmpty) {
      try {
        await _notificationRepository.notifyTaskAssigned(
          assigneeId: assigneeId,
          taskTitle: title,
          taskId: newTask.id,
        );
      } catch (e) {
        print('[NOTIFICATION ERROR] Lỗi gửi thông báo phân công task mới: $e');
      }
    }

    return newTask;
  }

  /// Cập nhật trạng thái task (dùng cho Drag & Drop).
  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    try {
      final docSnapshot = await _tasksRef.doc(taskId).get();
      if (!docSnapshot.exists) {
        print('[TASK REPO] Không tìm thấy task $taskId để cập nhật trạng thái');
        return;
      }

      final taskMap = docSnapshot.data() as Map<String, dynamic>;
      final taskTitle = (taskMap['title'] as String?) ?? 'Task';
      final assigneeId = taskMap['assigneeId'] as String?;

      await _tasksRef.doc(taskId).update({
        'status': newStatus,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (_notificationRepository != null) {
        final recipients = <String>{};
        // 1. Người được giao task (nếu có)
        if (assigneeId != null && assigneeId.isNotEmpty) {
          recipients.add(assigneeId);
        }
        // 2. BẬT THÔNG BÁO CHO CHÍNH NGƯỜI THỰC HIỆN: Thêm currentUserId (người vừa kéo thả) để test 1 tài khoản
        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        if (currentUserId != null && currentUserId.isNotEmpty) {
          recipients.add(currentUserId);
        }

        for (final receiverId in recipients) {
          try {
            await _notificationRepository.notifyTaskStatusChanged(
              ownerId: receiverId,
              taskTitle: taskTitle,
              newStatus: newStatus,
              taskId: taskId,
            );
          } catch (e) {
            print('[NOTIFICATION ERROR] Lỗi gửi thông báo đổi trạng thái task cho user $receiverId: $e');
          }
        }
      }
    } catch (e) {
      print('[NOTIFICATION ERROR] Lỗi updateTaskStatus trên Firestore: $e');
      rethrow;
    }
  }

  /// Cập nhật toàn bộ thông tin task.
  Future<void> updateTask(TaskModel task) async {
    try {
      final docSnapshot = await _tasksRef.doc(task.id).get();
      String? oldAssigneeId;
      String? oldStatus;
      if (docSnapshot.exists) {
        final oldData = docSnapshot.data() as Map<String, dynamic>;
        oldAssigneeId = oldData['assigneeId'] as String?;
        oldStatus = oldData['status'] as String?;
      }

      final updated = task.copyWith(updatedAt: DateTime.now());
      await _tasksRef.doc(task.id).update({
        'title': updated.title,
        'description': updated.description,
        'status': updated.status,
        'assigneeId': updated.assigneeId,
        'assigneeName': updated.assigneeName,
        'updatedAt': Timestamp.fromDate(updated.updatedAt),
      });

      if (_notificationRepository != null) {
        // 1. Phân công task mới
        if (updated.assigneeId != null && 
            updated.assigneeId!.isNotEmpty && 
            updated.assigneeId != oldAssigneeId) {
          try {
            await _notificationRepository.notifyTaskAssigned(
              assigneeId: updated.assigneeId!,
              taskTitle: updated.title,
              taskId: updated.id,
            );
          } catch (e) {
            print('[NOTIFICATION ERROR] Lỗi gửi thông báo phân công task: $e');
          }
        }

        // 2. Đổi trạng thái task
        if (oldStatus != null && oldStatus != updated.status) {
          final recipients = <String>{};
          if (updated.assigneeId != null && updated.assigneeId!.isNotEmpty) {
            recipients.add(updated.assigneeId!);
          }
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          if (currentUserId != null && currentUserId.isNotEmpty) {
            recipients.add(currentUserId);
          }

          for (final receiverId in recipients) {
            try {
              await _notificationRepository.notifyTaskStatusChanged(
                ownerId: receiverId,
                taskTitle: updated.title,
                newStatus: updated.status,
                taskId: updated.id,
              );
            } catch (e) {
              print('[NOTIFICATION ERROR] Lỗi gửi thông báo đổi trạng thái task: $e');
            }
          }
        }
      }
    } catch (e) {
      print('[NOTIFICATION ERROR] Lỗi updateTask trên Firestore: $e');
      rethrow;
    }
  }

  /// Đổi người phụ trách task (US-043). `assigneeId == null` = bỏ phân công.
  ///
  /// Chỉ update field assignee + `updatedAt` → không ghi đè các field khác.
  Future<void> updateTaskAssignee({
    required String taskId,
    required String taskTitle,
    String? assigneeId,
    String? assigneeName,
  }) {
    return _guard(() async {
      await _tasksRef.doc(taskId).update({
        'assigneeId': assigneeId,
        'assigneeName': assigneeName,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }).timeout(_writeTimeout);

      // Cùng hành vi với updateTask: báo cho người vừa được giao task.
      if (_notificationRepository != null &&
          assigneeId != null &&
          assigneeId.isNotEmpty) {
        try {
          await _notificationRepository.notifyTaskAssigned(
            assigneeId: assigneeId,
            taskTitle: taskTitle,
            taskId: taskId,
          );
        } catch (_) {
          // Gửi thông báo thất bại không được làm hỏng việc đổi assignee.
        }
      }
    });
  }

  /// Đặt / đổi / xoá (`null`) deadline của task (US-044).
  ///
  /// Chỉ update field `deadline` + `updatedAt`, lưu dạng Timestamp như các
  /// field ngày khác của task.
  Future<void> updateTaskDeadline({
    required String taskId,
    DateTime? deadline,
  }) {
    return _guard(() async {
      await _tasksRef.doc(taskId).update({
        'deadline': deadline != null ? Timestamp.fromDate(deadline) : null,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }).timeout(_writeTimeout);
    });
  }

  /// Gắn `projectId` cho task cũ chưa có field này (task tạo trước US-043).
  ///
  /// Security Rules dựa vào `projectId` của task để kiểm tra thành viên
  /// project khi đổi assignee/deadline và khi bình luận.
  Future<void> attachProject({
    required String taskId,
    required String projectId,
  }) {
    return _guard(() async {
      await _tasksRef
          .doc(taskId)
          .update({'projectId': projectId}).timeout(_writeTimeout);
    });
  }

  static const Duration _writeTimeout = Duration(seconds: 15);

  /// Chuyển lỗi Firebase/timeout sang thông báo tiếng Việt qua
  /// [FirebaseErrorMapper] (cùng cách làm với `BacklogRepositoryImpl`).
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      throw Exception(FirebaseErrorMapper.mapErrorCode(e.code));
    } on TimeoutException {
      throw Exception(FirebaseErrorMapper.mapErrorCode('deadline-exceeded'));
    }
  }

  /// Xóa task.
  Future<void> deleteTask(String taskId) async {
    await _tasksRef.doc(taskId).delete();
  }
}
