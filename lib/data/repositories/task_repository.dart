import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/constants/firebase_error_mapper.dart';
import '../../app/utils/list_utils.dart';
import '../datasources/local_cache_datasource.dart';
import '../models/task_model.dart';
import 'notification_repository.dart';

class TaskRepository {
  final FirebaseFirestore _firestore;
  final NotificationRepository? _notificationRepository;
  final LocalCacheDataSource? _localCache;

  TaskRepository({
    FirebaseFirestore? firestore,
    NotificationRepository? notificationRepository,
    LocalCacheDataSource? localCache,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _notificationRepository = notificationRepository ??
            NotificationRepository(firestore: firestore ?? FirebaseFirestore.instance),
        _localCache = localCache;

  CollectionReference get _tasksRef => _firestore.collection('tasks');

  // ── Streams ────────────────────────────────────────────────────────────────

  /// Stream realtime tất cả tasks của 1 User Story.
  /// Không dùng orderBy để tránh yêu cầu Composite Index trên Firestore.
  Stream<List<TaskModel>> streamTasksByStory(String storyId) async* {
    try {
      await for (final snapshot in _tasksRef
          .where('storyId', isEqualTo: storyId)
          .snapshots()) {
        final tasks = snapshot.docs.map((doc) {
          return TaskModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
        // US-062: Cache kết quả mỗi lần stream emit
        _localCache?.cacheTasks(storyId, tasks);
        yield tasks;
      }
    } catch (e) {
      // US-062: Offline fallback
      if (_localCache != null) {
        final cached = await _localCache.getCachedTasks(storyId);
        if (cached.isNotEmpty) {
          yield cached;
          return;
        }
      }
      rethrow;
    }
  }

  /// Stream realtime 1 task (màn Task Detail). Emit `null` nếu task đã bị xoá.
  Stream<TaskModel?> streamTask(String taskId) async* {
    try {
      await for (final snapshot in _tasksRef.doc(taskId).snapshots()) {
        final data = snapshot.data() as Map<String, dynamic>?;
        if (!snapshot.exists || data == null) {
          yield null;
        } else {
          yield TaskModel.fromMap(data, snapshot.id);
        }
      }
    } catch (e) {
      // US-062: Offline fallback
      if (_localCache != null) {
        final cached = await _localCache.getCachedTask(taskId);
        if (cached != null) {
          yield cached;
          return;
        }
      }
      rethrow;
    }
  }

  /// Stream realtime tất cả tasks của 1 Project (dùng cho bảng thống kê hiệu suất US-060).
  Stream<List<TaskModel>> streamTasksByProject(String projectId) async* {
    try {
      await for (final snapshot in _tasksRef
          .where('projectId', isEqualTo: projectId)
          .snapshots()) {
        final tasks = snapshot.docs.map((doc) {
          return TaskModel.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();
        // US-062: Cache kết quả theo project
        _localCache?.cacheTasks(projectId, tasks);
        yield tasks;
      }
    } catch (e) {
      // US-062: Offline fallback theo project
      if (_localCache != null) {
        final cached = await _localCache.getCachedTasksByProject(projectId);
        if (cached.isNotEmpty) {
          yield cached;
          return;
        }
      }
      rethrow;
    }
  }

  /// Stream realtime tất cả tasks thuộc danh sách User Stories (US-065).
  ///
  /// - Danh sách [storyIds] rỗng -> trả về `Stream.value([])`.
  /// - Chia nhỏ [storyIds] thành từng chunk tối đa 30 phần tử để phù hợp giới hạn `whereIn` của Firestore.
  /// - Gộp kết quả các chunk: chỉ emit khi mọi chunk đã phát ít nhất 1 lần, loại trùng theo task id.
  /// - Hủy mọi sub-subscription khi stream bị huỷ.
  /// - Offline fallback: đọc từ SQLite cache qua [LocalCacheDataSource.getCachedTasksByStories].
  /// - Không lọc theo projectId (hỗ trợ task cũ có thể thiếu field này).
  Stream<List<TaskModel>> streamTasksByStories(List<String> storyIds) {
    if (storyIds.isEmpty) {
      return Stream.value(const <TaskModel>[]);
    }

    final chunks = chunkList(storyIds, 30);
    late final StreamController<List<TaskModel>> controller;
    final subscriptions = <StreamSubscription>[];
    final latestChunkTasks = List<List<TaskModel>?>.filled(chunks.length, null);
    bool hasEmittedFallback = false;

    Future<void> fallbackToCache(Object error) async {
      if (_localCache != null && !hasEmittedFallback) {
        try {
          final cached = await _localCache.getCachedTasksByStories(storyIds);
          if (cached.isNotEmpty && !controller.isClosed) {
            hasEmittedFallback = true;
            controller.add(cached);
            return;
          }
        } catch (_) {}
      }
      if (!controller.isClosed && !hasEmittedFallback) {
        controller.addError(error);
      }
    }

    controller = StreamController<List<TaskModel>>(
      onListen: () {
        for (int i = 0; i < chunks.length; i++) {
          final chunkIndex = i;
          final chunk = chunks[chunkIndex];

          try {
            final sub = _tasksRef
                .where('storyId', whereIn: chunk)
                .snapshots()
                .listen(
              (snapshot) {
                final tasks = snapshot.docs.map((doc) {
                  return TaskModel.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  );
                }).toList();

                // Ghi cache theo từng storyId trong chunk
                for (final storyId in chunk) {
                  final storyTasks =
                      tasks.where((t) => t.storyId == storyId).toList();
                  _localCache?.cacheTasks(storyId, storyTasks);
                }

                latestChunkTasks[chunkIndex] = tasks;

                // Chỉ emit khi MỌI chunk đã phát ít nhất 1 lần
                if (latestChunkTasks.every((t) => t != null)) {
                  final allTasks = <TaskModel>[];
                  final seenIds = <String>{};
                  for (final cList in latestChunkTasks) {
                    if (cList != null) {
                      for (final task in cList) {
                        if (seenIds.add(task.id)) {
                          allTasks.add(task);
                        }
                      }
                    }
                  }
                  if (!controller.isClosed) {
                    controller.add(allTasks);
                  }
                }
              },
              onError: (Object error) {
                fallbackToCache(error);
              },
            );

            subscriptions.add(sub);
          } catch (e) {
            fallbackToCache(e);
          }
        }
      },
      onCancel: () async {
        for (final sub in subscriptions) {
          await sub.cancel();
        }
        subscriptions.clear();
      },
    );

    return controller.stream;
  }

  /// Lấy toàn bộ danh sách Tasks của 1 project (dùng cho tính điểm hiệu suất US-058 & gợi ý AI US-057).
  Future<List<TaskModel>> getTasksByProject(String projectId) async {
    try {
      final snapshot = await _tasksRef
          .where('projectId', isEqualTo: projectId)
          .get()
          .timeout(_writeTimeout);

      final tasks = snapshot.docs.map((doc) {
        return TaskModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      return tasks;
    } catch (_) {
      // US-062: Offline fallback
      if (_localCache != null) {
        final cached = await _localCache.getCachedTasksByProject(projectId);
        if (cached.isNotEmpty) return cached;
      }
      return [];
    }
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
      'loggedHours': 0.0,
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
      final updateData = <String, dynamic>{
        'title': updated.title,
        'description': updated.description,
        'status': updated.status,
        'assigneeId': updated.assigneeId,
        'assigneeName': updated.assigneeName,
        'updatedAt': Timestamp.fromDate(updated.updatedAt),
      };
      // Chống ghi đè (US-066): loggedHours chỉ được thay đổi bằng FieldValue.increment
      updateData.remove('loggedHours');

      await _tasksRef.doc(task.id).update(updateData);

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

  /// Đánh dấu task bị Blocker và gửi FCM notification tới Scrum Master.
  ///
  /// Ghi field `isBlocked=true`, `blockerReason`, `updatedAt` vào Firestore,
  /// sau đó gọi [NotificationRepository.notifyBlockerAlert] để push tới mọi SM.
  Future<void> markTaskAsBlocked({
    required String taskId,
    required String reason,
    required String projectId,
  }) {
    return _guard(() async {
      // Lấy tên task để hiển thị trong notification
      final docSnapshot = await _tasksRef.doc(taskId).get();
      if (!docSnapshot.exists) {
        throw Exception('Task $taskId không tồn tại.');
      }
      final taskData = docSnapshot.data() as Map<String, dynamic>;
      final taskTitle = (taskData['title'] as String?) ?? 'Task';

      // Ghi blocker vào Firestore
      await _tasksRef.doc(taskId).update({
        'isBlocked': true,
        'blockerReason': reason,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      }).timeout(_writeTimeout);

      // Push notification tới Scrum Master
      if (_notificationRepository != null) {
        try {
          await _notificationRepository.notifyBlockerAlert(
            projectId: projectId,
            taskId: taskId,
            taskTitle: taskTitle,
            reason: reason,
          );
        } catch (e) {
          print('[BLOCKER ERROR] Lỗi gửi BLOCKER_ALERT: $e');
        }
      }
    });
  }

  /// Xóa task.
  Future<void> deleteTask(String taskId) async {
    await _tasksRef.doc(taskId).delete();
  }
}
