import '../../../app/constants/user_story_priority.dart';
import '../../../data/models/user_story_model.dart';

/// Tiêu chí sắp xếp Product Backlog (US-009). Chỉ đổi THỨ TỰ HIỂN THỊ,
/// không bao giờ sửa dữ liệu User Story.
enum BacklogSortOption {
  /// Thứ tự gốc từ Firestore (theo storyKey).
  defaultOrder,

  /// CAO → TB → THẤP.
  priority,

  /// Deadline gần nhất trước; story chưa có deadline xếp cuối.
  deadline;

  String get label {
    switch (this) {
      case BacklogSortOption.defaultOrder:
        return 'Mặc định';
      case BacklogSortOption.priority:
        return 'Ưu tiên';
      case BacklogSortOption.deadline:
        return 'Deadline';
    }
  }
}

/// Áp dụng lần lượt SEARCH, FILTER (status, priority, tag) rồi SORT lên danh sách story gốc —
/// filter và sort độc lập nên không bao giờ làm mất nhau.
///
/// [statusFilter] = `null` hoặc 'Tất cả' nghĩa là "Tất cả".
/// Trả về list mới, không sửa [stories]. Sort ổn định: 2 story bằng nhau giữ nguyên thứ tự gốc.
List<UserStoryModel> applyBacklogView(
  List<UserStoryModel> stories, {
  String? searchQuery,
  String? statusFilter,
  String? priorityFilter,
  String? tagFilter,
  BacklogSortOption sortOption = BacklogSortOption.defaultOrder,
}) {
  final query = searchQuery?.trim().toLowerCase();

  final filtered = stories.where((s) {
    // 1. Search Query (US-007)
    if (query != null && query.isNotEmpty) {
      final inTitle = s.title.toLowerCase().contains(query);
      final inDesc = s.description.toLowerCase().contains(query);
      final inKey = s.storyKey.toLowerCase().contains(query);
      final inAssignee = s.assigneeName?.toLowerCase().contains(query) ?? false;
      final inTags = s.tags.any((t) => t.toLowerCase().contains(query));
      if (!inTitle && !inDesc && !inKey && !inAssignee && !inTags) {
        return false;
      }
    }

    // 2. Status Filter (US-008)
    if (statusFilter != null &&
        statusFilter.isNotEmpty &&
        statusFilter != 'Tất cả') {
      if (s.status.toLowerCase() != statusFilter.toLowerCase()) {
        return false;
      }
    }

    // 3. Priority Filter (US-008)
    if (priorityFilter != null &&
        priorityFilter.isNotEmpty &&
        priorityFilter != 'Tất cả') {
      if (s.priority.toUpperCase() != priorityFilter.toUpperCase()) {
        return false;
      }
    }

    // 4. Tag Filter (US-008)
    if (tagFilter != null &&
        tagFilter.isNotEmpty &&
        tagFilter != 'Tất cả') {
      final normalizedTag = tagFilter.startsWith('#') ? tagFilter : '#$tagFilter';
      final hasTag = s.tags.any((t) {
        final normT = t.startsWith('#') ? t : '#$t';
        return normT.toLowerCase() == normalizedTag.toLowerCase() ||
            t.toLowerCase() == tagFilter.toLowerCase();
      });
      if (!hasTag) {
        return false;
      }
    }

    return true;
  }).toList();

  if (sortOption == BacklogSortOption.defaultOrder) {
    return List.of(filtered);
  }

  final indexed = filtered.asMap().entries.toList();
  indexed.sort((a, b) {
    final result = _compare(a.value, b.value, sortOption);
    return result != 0 ? result : a.key.compareTo(b.key);
  });
  return indexed.map((e) => e.value).toList();
}

int _compare(UserStoryModel a, UserStoryModel b, BacklogSortOption option) {
  switch (option) {
    case BacklogSortOption.priority:
      return UserStoryPriority.rank(a.priority)
          .compareTo(UserStoryPriority.rank(b.priority));
    case BacklogSortOption.deadline:
      final da = a.deadline;
      final db = b.deadline;
      if (da == null && db == null) {
        // Cùng không có deadline → xếp phụ theo ưu tiên cho có ý nghĩa.
        return UserStoryPriority.rank(a.priority)
            .compareTo(UserStoryPriority.rank(b.priority));
      }
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    case BacklogSortOption.defaultOrder:
      return 0;
  }
}
