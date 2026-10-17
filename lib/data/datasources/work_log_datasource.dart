import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/work_log_model.dart';

/// DataSource ghi nhận thời gian làm việc (Work Log) trên Cloud Firestore (US-066).
class WorkLogDataSource {
  final FirebaseFirestore _firestore;

  static const Duration _writeTimeout = Duration(seconds: 15);

  WorkLogDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _workLogsRef(String taskId) {
    return _firestore.collection('tasks').doc(taskId).collection('workLogs');
  }

  /// Lắng nghe Stream danh sách lịch sử ghi giờ của task, sắp xếp createdAt giảm dần.
  Stream<List<WorkLogModel>> streamWorkLogs(String taskId) {
    return _workLogsRef(taskId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkLogModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Ghi nhận 1 bản ghi thời gian làm việc (Work Log) và cộng dồn `loggedHours` của Task.
  ///
  /// Dùng [WriteBatch] trong cùng 1 transaction/batch:
  /// (a) Set document mới tại `tasks/{taskId}/workLogs/{newId}` với
  ///     `createdAt = FieldValue.serverTimestamp()`.
  /// (b) Cập nhật `tasks/{taskId}` CHỈ với `{'loggedHours': FieldValue.increment(log.hours)}`.
  ///
  /// TUYỆT ĐỐI KHÔNG cập nhật `updatedAt` của Task (PerformanceScoreService
  /// dùng `updatedAt` làm mốc hoàn thành công việc của sprint/task).
  /// Giới hạn timeout 15 giây và không nuốt lỗi.
  Future<void> addWorkLog(WorkLogModel log) async {
    final batch = _firestore.batch();
    final taskRef = _firestore.collection('tasks').doc(log.taskId);
    final logRef = log.id.isEmpty
        ? taskRef.collection('workLogs').doc()
        : taskRef.collection('workLogs').doc(log.id);

    final logData = {
      ...log.toMap(),
      'id': logRef.id,
      'createdAt': FieldValue.serverTimestamp(),
    };

    batch.set(logRef, logData);
    batch.update(taskRef, {
      'loggedHours': FieldValue.increment(log.hours),
    });

    await batch.commit().timeout(_writeTimeout);
  }
}
