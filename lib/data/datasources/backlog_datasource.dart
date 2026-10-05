import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_story_model.dart';

/// Kết quả phân trang từ Firestore (cursor-based pagination).
class PaginatedResult {
  final List<UserStoryModel> stories;

  /// Con trỏ (DocumentSnapshot) đánh dấu vị trí cuối cùng — truyền vào
  /// lần gọi tiếp theo để lấy trang kế. `null` = hết dữ liệu hoặc fallback.
  final DocumentSnapshot? lastDocument;

  /// `true` nếu có thể còn trang tiếp theo.
  final bool hasMore;

  const PaginatedResult({
    required this.stories,
    this.lastDocument,
    this.hasMore = false,
  });
}


class BacklogDataSource {
  final FirebaseFirestore _firestore;

  // Local in-memory cache phục vụ fallback khi Firestore Security Rules chưa deploy hoặc offline
  static final Map<String, List<UserStoryModel>> _localCache = {};
  static final Map<String, StreamController<List<UserStoryModel>>> _controllers = {};

  BacklogDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _storiesCollection(String projectId) {
    return _firestore.collection('projects').doc(projectId).collection('userStories');
  }

  StreamController<List<UserStoryModel>> _getController(String projectId) {
    if (!_controllers.containsKey(projectId) || _controllers[projectId]!.isClosed) {
      _controllers[projectId] = StreamController<List<UserStoryModel>>.broadcast();
    }
    return _controllers[projectId]!;
  }

  /// Lắng nghe danh sách User Stories real-time theo Project.
  /// Có cơ chế tự động Fallback sang Local Cache nếu Firestore trả về permission-denied (do cloud rules chưa deploy).
  Stream<List<UserStoryModel>> streamUserStories(String projectId) {
    final controller = _getController(projectId);

    // Phát dữ liệu local ngay nếu đã có sẵn
    if (_localCache.containsKey(projectId) && _localCache[projectId]!.isNotEmpty) {
      Future.microtask(() {
        if (!controller.isClosed) {
          controller.add(List.from(_localCache[projectId]!));
        }
      });
    }

    // Kết nối lắng nghe Firestore
    _storiesCollection(projectId)
        .orderBy('storyKey', descending: false)
        .snapshots()
        .listen(
      (snapshot) {
        final stories = snapshot.docs
            .map((doc) => UserStoryModel.fromMap(doc.data(), doc.id))
            .toList();
        _localCache[projectId] = stories;
        if (!controller.isClosed) {
          controller.add(stories);
        }
      },
      onError: (error) {
        if (!_localCache.containsKey(projectId)) {
          _localCache[projectId] = [];
        }
        if (!controller.isClosed) {
          controller.add(List.from(_localCache[projectId]!));
        }
      },
    );

    return controller.stream;
  }

  /// Lấy danh sách User Stories (one-shot).
  Future<List<UserStoryModel>> getUserStories(String projectId) async {
    try {
      final snapshot = await _storiesCollection(projectId)
          .orderBy('storyKey', descending: false)
          .get();
      final stories = snapshot.docs
          .map((doc) => UserStoryModel.fromMap(doc.data(), doc.id))
          .toList();
      _localCache[projectId] = stories;
      return stories;
    } catch (_) {
      return List.from(_localCache[projectId] ?? const []);
    }
  }

  /// Lấy chi tiết 1 User Story.
  Future<UserStoryModel?> getUserStory(String projectId, String storyId) async {
    try {
      final doc = await _storiesCollection(projectId).doc(storyId).get();
      if (doc.exists && doc.data() != null) {
        return UserStoryModel.fromMap(doc.data()!, doc.id);
      }
    } catch (_) {
      // Fallback
    }

    final localList = _localCache[projectId];
    if (localList != null) {
      final found = localList.where((s) => s.id == storyId || s.storyKey == storyId);
      if (found.isNotEmpty) return found.first;
    }
    return null;
  }

  /// Tạo hoặc cập nhật User Story.
  Future<void> saveUserStory(String projectId, UserStoryModel story) async {
    // Cập nhật local cache trước
    final currentList = _localCache[projectId] ?? [];
    final index = currentList.indexWhere((s) => s.id == story.id || s.storyKey == story.storyKey);
    if (index >= 0) {
      currentList[index] = story;
    } else {
      currentList.add(story);
    }
    _localCache[projectId] = currentList;
    final controller = _getController(projectId);
    if (!controller.isClosed) {
      controller.add(List.from(currentList));
    }

    try {
      final docRef = story.id.isEmpty
          ? _storiesCollection(projectId).doc()
          : _storiesCollection(projectId).doc(story.id);

      final finalStory = story.id.isEmpty ? story.copyWith() : story;
      await docRef.set(finalStory.toMap(), SetOptions(merge: true));
    } catch (_) {
      // Bỏ qua lỗi Firestore nếu không có quyền, local cache đã lưu
    }
  }

  /// Tạo mới 1 User Story (US-010) với document id do Firestore sinh.
  ///
  /// Khác [saveUserStory]: KHÔNG nuốt lỗi và KHÔNG ghi local cache trước —
  /// lỗi permission-denied/mạng phải được báo lên UI thay vì giả vờ thành
  /// công. Mỗi lần gọi luôn tạo đúng 1 document mới (không upsert theo
  /// storyKey), nên chống bấm lặp được xử lý ở tầng Cubit.
  Future<UserStoryModel> createUserStory(
    String projectId,
    UserStoryModel story,
  ) async {
    final docRef = _storiesCollection(projectId).doc();
    final created = story.copyWith(id: docRef.id);
    await docRef.set(created.toMap()).timeout(_writeTimeout);
    _upsertLocal(projectId, created);
    return created;
  }

  /// Cập nhật các field cơ bản của User Story (US-011, US-013).
  Future<void> updateUserStory(
    String projectId,
    UserStoryModel story,
  ) async {
    await _storiesCollection(projectId).doc(story.id).update({
      'title': story.title,
      'description': story.description,
      'priority': story.priority,
      'storyPoints': story.storyPoints,
      'deadline': story.deadline?.toIso8601String(),
      'updatedAt': story.updatedAt.toIso8601String(),
    }).timeout(_writeTimeout);

    _upsertLocal(projectId, story);
  }

  /// Cập nhật RIÊNG field `tags` (+ `updatedAt`) của 1 User Story (US-014).
  ///
  /// Dùng `update()` thay vì `set()` toàn bộ object để không bao giờ ghi đè
  /// các field khác (title, priority, status, storyPoints, deadline...).
  Future<void> updateTags(
    String projectId,
    String storyId,
    List<String> tags,
    DateTime updatedAt,
  ) async {
    await _storiesCollection(projectId).doc(storyId).update({
      'tags': tags,
      'updatedAt': updatedAt.toIso8601String(),
    }).timeout(_writeTimeout);

    final cached = _localCache[projectId];
    if (cached == null) return;
    final index = cached.indexWhere((s) => s.id == storyId);
    if (index >= 0) {
      _upsertLocal(
        projectId,
        cached[index].copyWith(tags: tags, updatedAt: updatedAt),
      );
    }
  }

  /// Xóa 1 User Story khỏi Firestore và local cache.
  Future<void> deleteUserStory(String projectId, String storyId) async {
    await deleteUserStories(projectId, [storyId]);
  }

  /// Xóa hàng loạt User Stories khỏi Firestore và local cache (US-053 / US-012).
  Future<void> deleteUserStories(String projectId, List<String> storyIds) async {
    if (storyIds.isEmpty) return;

    // Cập nhật local cache trước
    final currentList = _localCache[projectId] ?? [];
    _localCache[projectId] = currentList
        .where((s) => !storyIds.contains(s.id) && !storyIds.contains(s.storyKey))
        .toList();
    final controller = _getController(projectId);
    if (!controller.isClosed) {
      controller.add(List.from(_localCache[projectId]!));
    }

    try {
      final batch = _firestore.batch();
      for (final storyId in storyIds) {
        final docRef = _storiesCollection(projectId).doc(storyId);
        batch.delete(docRef);
      }
      await batch.commit().timeout(_writeTimeout);
    } catch (_) {
      // Bỏ qua lỗi Firestore nếu offline, local cache đã xóa
    }
  }

  /// Lấy 1 trang User Stories theo cursor-based pagination (US-054).
  ///
  /// [pageSize] = số lượng tối đa trên 1 trang.
  /// [startAfterDoc] = con trỏ đánh dấu kết thúc trang trước (null = trang đầu).
  /// [statusFilter] = lọc theo status trên server (null = tất cả).
  /// Trả về `PaginatedResult` chứa danh sách stories + con trỏ cho trang kế.
  Future<PaginatedResult> getUserStoriesPaginated({
    required String projectId,
    required int pageSize,
    DocumentSnapshot? startAfterDoc,
    String? statusFilter,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _storiesCollection(projectId)
          .orderBy('storyKey', descending: false);

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.where('status', isEqualTo: statusFilter);
      }

      if (startAfterDoc != null) {
        query = query.startAfterDocument(startAfterDoc);
      }

      query = query.limit(pageSize);

      final snapshot = await query.get();
      final stories = snapshot.docs
          .map((doc) => UserStoryModel.fromMap(doc.data(), doc.id))
          .toList();

      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      final hasMore = snapshot.docs.length == pageSize;

      return PaginatedResult(
        stories: stories,
        lastDocument: lastDoc,
        hasMore: hasMore,
      );
    } catch (e) {
      // Fallback sang local cache khi offline hoặc permission-denied
      final allLocal = _localCache[projectId] ?? const [];
      final filtered = statusFilter == null
          ? allLocal
          : allLocal.where((s) => s.status == statusFilter).toList();
      final start = startAfterDoc == null ? 0 : pageSize; // simplified offset fallback
      final page = filtered.skip(start).take(pageSize).toList();
      return PaginatedResult(
        stories: page,
        lastDocument: null,
        hasMore: page.length == pageSize,
      );
    }
  }

  /// Lấy danh sách User Stories theo tập hợp IDs (dùng cho Task Board theo Sprint).
  Future<List<UserStoryModel>> getStoriesByIds(
    String projectId,
    List<String> storyIds,
  ) async {
    if (storyIds.isEmpty) return const [];

    try {
      // Firestore 'whereIn' giới hạn 30 item/lần — chia batch.
      final results = <UserStoryModel>[];
      for (var i = 0; i < storyIds.length; i += 30) {
        final batch = storyIds.sublist(
          i,
          i + 30 > storyIds.length ? storyIds.length : i + 30,
        );
        // Sử dụng document ID (__name__) để query
        final snapshot = await _storiesCollection(projectId)
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        results.addAll(
          snapshot.docs.map((doc) => UserStoryModel.fromMap(doc.data(), doc.id)),
        );
      }
      return results;
    } catch (_) {
      // Fallback sang local cache
      final allLocal = _localCache[projectId] ?? const [];
      return allLocal.where((s) => storyIds.contains(s.id)).toList();
    }
  }

  /// Firestore Web chỉ hoàn thành Future ghi khi server xác nhận — nếu mất
  /// mạng sẽ treo vô hạn, nên giới hạn thời gian chờ để UI báo lỗi được.
  static const Duration _writeTimeout = Duration(seconds: 15);

  /// Đồng bộ local cache + stream sau khi ghi thành công, để UI vẫn cập
  /// nhật khi stream đang ở chế độ fallback (listener Firestore đã lỗi).
  /// Upsert theo id nên không bao giờ tạo bản trùng.
  void _upsertLocal(String projectId, UserStoryModel story) {
    final list = List<UserStoryModel>.from(_localCache[projectId] ?? const []);
    final index = list.indexWhere((s) => s.id == story.id);
    if (index >= 0) {
      list[index] = story;
    } else {
      list.add(story);
    }
    _localCache[projectId] = list;
    final controller = _getController(projectId);
    if (!controller.isClosed) {
      controller.add(List.from(list));
    }
  }

  Future<void> seedMockStories(String projectId) async {
    // Chức năng tự sinh mẫu đã bị loại bỏ theo yêu cầu người dùng
  }

}
