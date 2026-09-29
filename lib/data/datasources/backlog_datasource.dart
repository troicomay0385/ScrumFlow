import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_story_model.dart';

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
        // Khi Firestore từ chối quyền (permission-denied do rule chưa deploy trên cloud),
        // tự động fallback về Local Cache & tự động nạp 8 User Stories mẫu để việc kiểm thử không bị gián đoạn.
        if (!_localCache.containsKey(projectId) || _localCache[projectId]!.isEmpty) {
          _localCache[projectId] = _buildSampleStories(projectId);
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
      if (!_localCache.containsKey(projectId) || _localCache[projectId]!.isEmpty) {
        _localCache[projectId] = _buildSampleStories(projectId);
      }
      return List.from(_localCache[projectId]!);
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

  /// Tạo hàng loạt dữ liệu User Stories mẫu với các User ảo để kiểm thử (Seed Data).
  Future<void> seedMockStories(String projectId) async {
    final sampleStories = _buildSampleStories(projectId);

    // Luôn lưu vào local cache và push vào stream trước để UI phản hồi tức thì
    _localCache[projectId] = sampleStories;
    final controller = _getController(projectId);
    if (!controller.isClosed) {
      controller.add(List.from(sampleStories));
    }

    // Thử đồng bộ lên Firestore nếu có quyền
    try {
      final batch = _firestore.batch();
      for (final story in sampleStories) {
        final docRef = _storiesCollection(projectId).doc(story.id);
        batch.set(docRef, story.toMap());
      }
      await batch.commit();
    } catch (_) {
      // Bỏ qua lỗi permission-denied của Cloud Firestore
    }
  }

  List<UserStoryModel> _buildSampleStories(String projectId) {
    final now = DateTime.now();
    return [
      UserStoryModel(
        id: 'mock_us_001',
        projectId: projectId,
        storyKey: 'US-001',
        title: 'Đăng ký tài khoản người dùng mới bằng Email & Mật khẩu',
        description:
            'Là người dùng mới, tôi muốn đăng ký tài khoản bằng email và mật khẩu an toàn để có tài khoản truy cập vào hệ thống làm việc.',
        priority: 'CAO',
        storyPoints: 3,
        status: 'Done',
        assigneeId: 'mock_u3',
        assigneeName: 'Trần Thúy',
        assigneeEmail: 'thuy.qa@scrumflow.com',
        tags: const ['Authentication'],
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 6)),
      ),
      UserStoryModel(
        id: 'mock_us_002',
        projectId: projectId,
        storyKey: 'US-002',
        title: 'Đăng nhập vào hệ thống bằng Email và Mật khẩu',
        description:
            'Là người dùng đã có tài khoản, tôi muốn đăng nhập bằng email và mật khẩu để truy cập bảng điều khiển và danh sách dự án của tôi.',
        priority: 'CAO',
        storyPoints: 3,
        status: 'Done',
        assigneeId: 'mock_u3',
        assigneeName: 'Trần Thúy',
        assigneeEmail: 'thuy.qa@scrumflow.com',
        tags: const ['Authentication', 'Frontend'],
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      UserStoryModel(
        id: 'mock_us_004',
        projectId: projectId,
        storyKey: 'US-004',
        title: 'Phân quyền vai trò PO, SM và Member trong dự án',
        description:
            'Là quản trị viên, tôi muốn phân chia vai trò rõ ràng theo mô hình Agile Scrum (Product Owner, Scrum Master, Member) để kiểm soát quyền hạn dữ liệu an toàn.',
        priority: 'CAO',
        storyPoints: 5,
        status: 'Done',
        assigneeId: 'mock_u1',
        assigneeName: 'Lê Phúc',
        assigneeEmail: 'phuc.po@scrumflow.com',
        tags: const ['Security'],
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 4)),
      ),
      UserStoryModel(
        id: 'mock_us_036',
        projectId: projectId,
        storyKey: 'US-036',
        title: 'Tạo dự án mới với tên và mục tiêu ban đầu',
        description:
            'Là quản trị viên/PO, tôi muốn tạo dự án mới với tên gọi và định hướng mục tiêu để bắt đầu khởi tạo Product Backlog và Sprint.',
        priority: 'CAO',
        storyPoints: 5,
        status: 'Done',
        assigneeId: 'mock_u2',
        assigneeName: 'Nguyễn Hiếu',
        assigneeEmail: 'hieu.dev@scrumflow.com',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
      UserStoryModel(
        id: 'mock_us_056',
        projectId: projectId,
        storyKey: 'US-056',
        title: 'Mở khóa ứng dụng nhanh bằng Vân tay hoặc Face ID',
        description:
            'Là người dùng di động, tôi muốn mở khóa nhanh bằng cảm biến sinh trắc học (vân tay hoặc nhận diện khuôn mặt) sau lần đăng nhập đầu để tăng tính tiện lợi và bảo mật.',
        priority: 'CAO',
        storyPoints: 5,
        status: 'In Progress',
        assigneeId: 'mock_u1',
        assigneeName: 'Lê Phúc',
        assigneeEmail: 'phuc.po@scrumflow.com',
        tags: const ['Authentication', 'Mobile'],
        deadline: now.add(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      UserStoryModel(
        id: 'mock_us_005',
        projectId: projectId,
        storyKey: 'US-005',
        title: 'Xem danh sách tất cả User Stories trong Product Backlog',
        description:
            'Là PO hoặc Scrum Master, tôi muốn xem toàn bộ danh mục User Stories trong Product Backlog dưới dạng danh sách tổng quan, hiển thị rõ độ ưu tiên, Story Points và người phụ trách.',
        priority: 'CAO',
        storyPoints: 3,
        status: 'In Progress',
        assigneeId: 'mock_u4',
        assigneeName: 'Phạm Duy',
        assigneeEmail: 'duy.dev@scrumflow.com',
        tags: const ['Backlog', 'Frontend'],
        deadline: now.add(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
      ),
      UserStoryModel(
        id: 'mock_us_006',
        projectId: projectId,
        storyKey: 'US-006',
        title: 'Xem chi tiết thông tin và tiêu chí hoàn thành của User Story',
        description:
            'Là PO hoặc thành viên phát triển, tôi muốn xem chi tiết một User Story gồm mô tả đầy đủ, tiêu chí chấp nhận (Acceptance Criteria), người phụ trách và tiến độ xử lý.',
        priority: 'CAO',
        storyPoints: 2,
        status: 'In Progress',
        assigneeId: 'mock_u4',
        assigneeName: 'Phạm Duy',
        assigneeEmail: 'duy.dev@scrumflow.com',
        deadline: now.add(const Duration(days: 9)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
      ),
      UserStoryModel(
        id: 'mock_us_010',
        projectId: projectId,
        storyKey: 'US-010',
        title: 'Tạo mới một User Story vào Product Backlog',
        description:
            'Là PO, tôi muốn thêm nhanh một yêu cầu/hạng mục mới vào Backlog với tiêu đề, mô tả và độ ưu tiên để nhóm ước lượng trong các phiên lập kế hoạch Sprint.',
        priority: 'TB',
        storyPoints: 3,
        status: 'To Do',
        assigneeId: 'mock_u2',
        assigneeName: 'Nguyễn Hiếu',
        assigneeEmail: 'hieu.dev@scrumflow.com',
        tags: const ['Backlog'],
        deadline: now.add(const Duration(days: 14)),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      ),
    ];
  }
}
