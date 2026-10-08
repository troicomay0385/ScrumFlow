import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;
import 'package:equatable/equatable.dart';
import '../../../data/models/user_story_model.dart';
import '../utils/backlog_view.dart';

abstract class BacklogState extends Equatable {
  const BacklogState();

  @override
  List<Object?> get props => [];
}

class BacklogInitial extends BacklogState {}

class BacklogLoading extends BacklogState {}

class BacklogLoaded extends BacklogState {
  /// Danh sách gốc từ stream (thứ tự Firestore) — KPI tổng số/tổng SP
  /// luôn tính trên danh sách này, không phụ thuộc filter.
  final List<UserStoryModel> stories;
  final bool isSeeding;

  /// US-007: Từ khóa tìm kiếm hiện tại
  final String searchQuery;

  /// US-008: Bộ lọc trạng thái; `null` = "Tất cả".
  final String? statusFilter;

  /// US-008: Bộ lọc độ ưu tiên (CAO, TB, THẤP); `null` = "Tất cả".
  final String? priorityFilter;

  /// US-008: Bộ lọc nhãn/tag; `null` = "Tất cả".
  final String? tagFilter;

  final BacklogSortOption sortOption;

  /// Danh sách hiển thị = [stories] sau khi search, filter rồi sort.
  final List<UserStoryModel> visibleStories;

  /// Con trỏ phân trang server-side (cursor-based) — null = chưa dùng hoặc trang đầu.
  final DocumentSnapshot? lastDocument;

  /// `true` nếu Firestore còn trang kế tiếp.
  final bool hasMore;

  /// `true` khi đang load trang tiếp theo.
  final bool isLoadingMore;

  /// Đếm số bộ lọc đang kích hoạt (để hiện badge trên nút lọc)
  int get activeFilterCount {
    int count = 0;
    if (statusFilter != null && statusFilter!.isNotEmpty && statusFilter != 'Tất cả') count++;
    if (priorityFilter != null && priorityFilter!.isNotEmpty && priorityFilter != 'Tất cả') count++;
    if (tagFilter != null && tagFilter!.isNotEmpty && tagFilter != 'Tất cả') count++;
    if (searchQuery.trim().isNotEmpty) count++;
    return count;
  }

  BacklogLoaded({
    required this.stories,
    this.isSeeding = false,
    this.searchQuery = '',
    this.statusFilter,
    this.priorityFilter,
    this.tagFilter,
    this.sortOption = BacklogSortOption.defaultOrder,
    this.lastDocument,
    this.hasMore = false,
    this.isLoadingMore = false,
  }) : visibleStories = applyBacklogView(
          stories,
          searchQuery: searchQuery,
          statusFilter: statusFilter,
          priorityFilter: priorityFilter,
          tagFilter: tagFilter,
          sortOption: sortOption,
        );

  @override
  List<Object?> get props => [
        stories,
        isSeeding,
        searchQuery,
        statusFilter,
        priorityFilter,
        tagFilter,
        sortOption,
        hasMore,
        isLoadingMore,
      ];

  BacklogLoaded copyWith({
    List<UserStoryModel>? stories,
    bool? isSeeding,
    String? searchQuery,
    String? Function()? statusFilter,
    String? Function()? priorityFilter,
    String? Function()? tagFilter,
    BacklogSortOption? sortOption,
    DocumentSnapshot? Function()? lastDocument,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return BacklogLoaded(
      stories: stories ?? this.stories,
      isSeeding: isSeeding ?? this.isSeeding,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      priorityFilter: priorityFilter != null ? priorityFilter() : this.priorityFilter,
      tagFilter: tagFilter != null ? tagFilter() : this.tagFilter,
      sortOption: sortOption ?? this.sortOption,
      lastDocument: lastDocument != null ? lastDocument() : this.lastDocument,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class BacklogError extends BacklogState {
  final String message;

  const BacklogError(this.message);

  @override
  List<Object?> get props => [message];
}
