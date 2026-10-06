import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _notificationsRef => _firestore.collection('notifications');

  /// Tạo và lưu một notification mới vào Firestore
  Future<void> sendNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? targetId,
  }) async {
    try {
      final docRef = _notificationsRef.doc();
      final notification = NotificationModel(
        id: docRef.id,
        userId: userId,
        title: title,
        body: body,
        type: type,
        targetId: targetId,
        createdAt: DateTime.now(),
      );

      await docRef.set(notification.toMap());
      print('[NOTIFICATION TRIGGER] Đã bắn thông báo thành công cho user: $userId - Tiêu đề: $title');
    } catch (e) {
      print('[NOTIFICATION ERROR] Lỗi gửi thông báo: $e');
    }
  }

  /// Lấy stream danh sách notification của một user
  /// Sắp xếp client-side theo createdAt giảm dần để tránh yêu cầu Composite Index trên Firestore.
  Stream<List<NotificationModel>> streamUserNotifications(String userId) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs.map((doc) {
            return NotificationModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  /// Đánh dấu đã đọc
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsRef.doc(notificationId).update({'isRead': true});
    } catch (e) {
      print('[NOTIFICATION ERROR] Lỗi đánh dấu đã đọc notification $notificationId: $e');
    }
  }

  /// Đánh dấu tất cả đã đọc
  Future<void> markAllAsRead(String userId) async {
    try {
      final unreadQuery = await _notificationsRef
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadQuery.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      print('[NOTIFICATION ERROR] Lỗi đánh dấu tất cả đã đọc: $e');
    }
  }

  // ── Helper methods (Trigger Notifications) ──────────────────────────────

  Future<void> notifyTaskAssigned({
    required String assigneeId,
    required String taskTitle,
    required String taskId,
  }) async {
    await sendNotification(
      userId: assigneeId,
      title: 'Task mới được giao',
      body: 'Bạn vừa được phân công task: "$taskTitle"',
      type: 'ASSIGN_TASK',
      targetId: taskId,
    );
  }

  Future<void> notifyTaskStatusChanged({
    required String ownerId, // Hoặc những người liên quan
    required String taskTitle,
    required String newStatus,
    required String taskId,
  }) async {
    await sendNotification(
      userId: ownerId,
      title: 'Trạng thái Task thay đổi',
      body: 'Task "$taskTitle" đã chuyển sang trạng thái: $newStatus',
      type: 'STATUS_CHANGE',
      targetId: taskId,
    );
  }

  Future<void> notifyNewComment({
    required String receiverId,
    required String taskTitle,
    required String commenterName,
    required String taskId,
  }) async {
    await sendNotification(
      userId: receiverId,
      title: 'Bình luận mới',
      body: '$commenterName đã bình luận trong task "$taskTitle"',
      type: 'NEW_COMMENT',
      targetId: taskId,
    );
  }

  Future<void> notifyNewStory({
    required List<String> memberIds,
    required String storyTitle,
    required String projectId,
  }) async {
    try {
      const title = 'User Story mới';
      final batch = _firestore.batch();
      for (var userId in memberIds) {
        final docRef = _notificationsRef.doc();
        final notification = NotificationModel(
          id: docRef.id,
          userId: userId,
          title: title,
          body: 'Story "$storyTitle" vừa được thêm vào dự án',
          type: 'STORY_ADDED',
          targetId: projectId,
          createdAt: DateTime.now(),
        );
        batch.set(docRef, notification.toMap());
      }
      await batch.commit();
      for (var userId in memberIds) {
        print('[NOTIFICATION TRIGGER] Đã bắn thông báo thành công cho user: $userId - Tiêu đề: $title');
      }
    } catch (e) {
      print('[NOTIFICATION ERROR] Lỗi gửi thông báo User Story: $e');
    }
  }

  Future<void> notifyProjectUpdated({
    required List<String> memberIds,
    required String projectName,
    required String projectId,
  }) async {
    try {
      const title = 'Dự án được cập nhật';
      final batch = _firestore.batch();
      for (var userId in memberIds) {
        final docRef = _notificationsRef.doc();
        final notification = NotificationModel(
          id: docRef.id,
          userId: userId,
          title: title,
          body: 'Thông tin dự án "$projectName" vừa được cập nhật',
          type: 'PROJECT_UPDATED',
          targetId: projectId,
          createdAt: DateTime.now(),
        );
        batch.set(docRef, notification.toMap());
      }
      await batch.commit();
      for (var userId in memberIds) {
        print('[NOTIFICATION TRIGGER] Đã bắn thông báo thành công cho user: $userId - Tiêu đề: $title');
      }
    } catch (e) {
      print('[NOTIFICATION ERROR] Lỗi gửi thông báo cập nhật dự án: $e');
    }
  }
}
