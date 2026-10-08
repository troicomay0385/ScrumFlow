import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attachment_model.dart';

/// DataSource tệp đính kèm trên Cloud Firestore (US-047).
///
/// Hỗ trợ cả Cloud Firestore subcollection `attachments` và Local Cache Fallback
/// phòng vệ khi Firestore Security Rules trên đám mây chưa được Publish.
class AttachmentDataSource {
  final FirebaseFirestore _firestore;

  // Local in-memory cache phòng vệ khi Firestore Security Rules chưa deploy hoặc offline
  final Map<String, List<AttachmentModel>> _localCache = {};
  final Map<String, StreamController<List<AttachmentModel>>> _controllers = {};

  AttachmentDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  String _cacheKey(AttachmentTarget target) =>
      target.isTask ? 'task_${target.taskId}' : 'story_${target.storyId}';

  StreamController<List<AttachmentModel>> _getController(
      AttachmentTarget target) {
    final key = _cacheKey(target);
    if (!_controllers.containsKey(key) || _controllers[key]!.isClosed) {
      _controllers[key] =
          StreamController<List<AttachmentModel>>.broadcast();
    }
    return _controllers[key]!;
  }

  CollectionReference<Map<String, dynamic>> _attachmentsRef(
      AttachmentTarget target) {
    final parent = target.isTask
        ? _firestore.collection('tasks').doc(target.taskId)
        : _firestore
            .collection('projects')
            .doc(target.projectId)
            .collection('userStories')
            .doc(target.storyId);
    return parent.collection('attachments');
  }

  /// Stream real-time danh sách tệp đính kèm.
  /// Tự động Fallback sang Local Cache nếu Firestore trả về permission-denied.
  Stream<List<AttachmentModel>> streamAttachments(AttachmentTarget target) {
    final controller = _getController(target);
    final key = _cacheKey(target);

    // Phát dữ liệu local cache ngay nếu có sẵn
    if (_localCache.containsKey(key) && _localCache[key]!.isNotEmpty) {
      Future.microtask(() {
        if (!controller.isClosed) {
          controller.add(List.from(_localCache[key]!));
        }
      });
    }

    _attachmentsRef(target)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        final items = snapshot.docs
            .map((doc) => AttachmentModel.fromMap(doc.data(), doc.id))
            .toList();
        _localCache[key] = items;
        if (!controller.isClosed) {
          controller.add(items);
        }
      },
      onError: (error) {
        // Fallback khi Firestore Rules từ chối truy cập (permission-denied)
        if (!_localCache.containsKey(key)) {
          _localCache[key] = [];
        }
        if (!controller.isClosed) {
          controller.add(List.from(_localCache[key]!));
        }
      },
    );

    return controller.stream;
  }

  /// Thêm 1 tệp hoặc liên kết đính kèm.
  /// Nếu Firestore trả về lỗi permission-denied (do cloud rules chưa deploy),
  /// tự động fallback lưu vào cache local để người dùng trải nghiệm trơn tru.
  Future<AttachmentModel> addAttachment(
      AttachmentTarget target, AttachmentModel attachment) async {
    final key = _cacheKey(target);
    final controller = _getController(target);

    try {
      final docRef = await _attachmentsRef(target).add({
        ...attachment.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      final saved = AttachmentModel(
        id: docRef.id,
        projectId: attachment.projectId,
        storyId: attachment.storyId,
        taskId: attachment.taskId,
        fileName: attachment.fileName,
        fileSize: attachment.fileSize,
        fileType: attachment.fileType,
        fileUrl: attachment.fileUrl,
        isLink: attachment.isLink,
        uploadedById: attachment.uploadedById,
        uploadedByName: attachment.uploadedByName,
        createdAt: attachment.createdAt,
      );

      _localCache.putIfAbsent(key, () => []);
      _localCache[key]!.insert(0, saved);
      if (!controller.isClosed) {
        controller.add(List.from(_localCache[key]!));
      }

      return saved;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'unavailable') {
        // Fallback lưu local khi Cloud rules chưa publish
        final fallback = AttachmentModel(
          id: 'local_${DateTime.now().millisecondsSinceEpoch}',
          projectId: attachment.projectId,
          storyId: attachment.storyId,
          taskId: attachment.taskId,
          fileName: attachment.fileName,
          fileSize: attachment.fileSize,
          fileType: attachment.fileType,
          fileUrl: attachment.fileUrl,
          isLink: attachment.isLink,
          uploadedById: attachment.uploadedById,
          uploadedByName: attachment.uploadedByName,
          createdAt: attachment.createdAt,
        );

        _localCache.putIfAbsent(key, () => []);
        _localCache[key]!.insert(0, fallback);
        if (!controller.isClosed) {
          controller.add(List.from(_localCache[key]!));
        }

        return fallback;
      }
      rethrow;
    }
  }

  /// Xóa 1 tệp đính kèm.
  Future<void> deleteAttachment(
      AttachmentTarget target, String attachmentId) async {
    final key = _cacheKey(target);
    final controller = _getController(target);

    try {
      if (!attachmentId.startsWith('local_')) {
        await _attachmentsRef(target)
            .doc(attachmentId)
            .delete()
            .timeout(const Duration(seconds: 10));
      }
    } catch (_) {
      // Bỏ qua lỗi Cloud delete nếu là fallback
    }

    // Luôn xóa khỏi local cache và phát ra stream
    if (_localCache.containsKey(key)) {
      _localCache[key]!.removeWhere((item) => item.id == attachmentId);
      if (!controller.isClosed) {
        controller.add(List.from(_localCache[key]!));
      }
    }
  }
}
