import 'package:equatable/equatable.dart';
import '../../../data/models/user_story_model.dart';

import 'backlog_event.dart';

abstract class BacklogState extends Equatable {
  const BacklogState();

  @override
  List<Object?> get props => [];
}

class BacklogInitial extends BacklogState {}

class BacklogLoading extends BacklogState {}

class BacklogLoaded extends BacklogState {
  final List<UserStoryModel> stories;
  final String searchQuery;
  final String statusFilter;
  final String priorityFilter;
  final String tagFilter;
  final BacklogSortBy sortBy;
  final bool isSeeding;

  const BacklogLoaded({
    required this.stories,
    this.searchQuery = '',
    this.statusFilter = 'Tất cả',
    this.priorityFilter = 'Tất cả',
    this.tagFilter = 'Tất cả',
    this.sortBy = BacklogSortBy.priorityDesc,
    this.isSeeding = false,
  });

  /// Tính toán danh sách User Stories sau khi áp dụng đồng thời Tìm kiếm, Lọc và Sắp xếp
  List<UserStoryModel> get filteredStories {
    final list = stories.where((story) {
      // 1. Lọc theo trạng thái
      if (statusFilter != 'Tất cả' &&
          story.status.toLowerCase() != statusFilter.toLowerCase()) {
        return false;
      }
      // 2. Lọc theo độ ưu tiên
      if (priorityFilter != 'Tất cả' &&
          story.priority.toUpperCase() != priorityFilter.toUpperCase()) {
        return false;
      }
      // 3. Lọc theo nhãn / tag
      if (tagFilter != 'Tất cả' &&
          !story.tags
              .map((t) => t.toLowerCase())
              .contains(tagFilter.toLowerCase())) {
        return false;
      }
      // 4. Tìm kiếm từ khóa (US-007)
      if (searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final matchKey = story.storyKey.toLowerCase().contains(query);
        final matchTitle = story.title.toLowerCase().contains(query);
        final matchDesc = story.description.toLowerCase().contains(query);
        final matchAssignee =
            story.assigneeName?.toLowerCase().contains(query) ?? false;
        final matchTag =
            story.tags.any((t) => t.toLowerCase().contains(query));

        if (!matchKey &&
            !matchTitle &&
            !matchDesc &&
            !matchAssignee &&
            !matchTag) {
          return false;
        }
      }
      return true;
    }).toList();

    // 5. Sắp xếp (US-009)
    list.sort((a, b) {
      switch (sortBy) {
        case BacklogSortBy.priorityDesc:
          return _priorityWeight(b.priority)
              .compareTo(_priorityWeight(a.priority));
        case BacklogSortBy.priorityAsc:
          return _priorityWeight(a.priority)
              .compareTo(_priorityWeight(b.priority));
        case BacklogSortBy.dueDateAsc:
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        case BacklogSortBy.pointsDesc:
          return b.storyPoints.compareTo(a.storyPoints);
        case BacklogSortBy.pointsAsc:
          return a.storyPoints.compareTo(b.storyPoints);
        case BacklogSortBy.storyKeyAsc:
          return a.storyKey.compareTo(b.storyKey);
      }
    });

    return list;
  }

  static int _priorityWeight(String priority) {
    switch (priority.toUpperCase()) {
      case 'CAO':
      case 'HIGH':
      case 'URGENT':
        return 3;
      case 'TB':
      case 'TRUNG BÌNH':
      case 'MEDIUM':
        return 2;
      case 'THẤP':
      case 'LOW':
        return 1;
      default:
        return 0;
    }
  }

  /// Trích xuất danh sách tag duy nhất từ các User Stories
  List<String> get availableTags {
    final set = <String>{};
    for (final s in stories) {
      set.addAll(s.tags);
    }
    final list = set.toList();
    list.sort();
    return list;
  }

  /// Kiểm tra có đang áp dụng bất kỳ bộ lọc hoặc tìm kiếm nào không
  bool get hasActiveFilters =>
      searchQuery.trim().isNotEmpty ||
      statusFilter != 'Tất cả' ||
      priorityFilter != 'Tất cả' ||
      tagFilter != 'Tất cả';

  /// Số lượng bộ lọc thuộc tính đang kích hoạt (không tính search text)
  int get activeFilterCount {
    int count = 0;
    if (statusFilter != 'Tất cả') count++;
    if (priorityFilter != 'Tất cả') count++;
    if (tagFilter != 'Tất cả') count++;
    return count;
  }

  @override
  List<Object?> get props => [
        stories,
        searchQuery,
        statusFilter,
        priorityFilter,
        tagFilter,
        sortBy,
        isSeeding,
      ];

  BacklogLoaded copyWith({
    List<UserStoryModel>? stories,
    String? searchQuery,
    String? statusFilter,
    String? priorityFilter,
    String? tagFilter,
    BacklogSortBy? sortBy,
    bool? isSeeding,
  }) {
    return BacklogLoaded(
      stories: stories ?? this.stories,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      priorityFilter: priorityFilter ?? this.priorityFilter,
      tagFilter: tagFilter ?? this.tagFilter,
      sortBy: sortBy ?? this.sortBy,
      isSeeding: isSeeding ?? this.isSeeding,
    );
  }
}

class BacklogError extends BacklogState {
  final String message;

  const BacklogError(this.message);

  @override
  List<Object?> get props => [message];
}
