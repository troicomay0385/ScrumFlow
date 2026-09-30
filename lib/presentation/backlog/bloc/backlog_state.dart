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

  /// US-007: Từ khóa tìm kiếm
  final String searchQuery;

  /// US-008: Bộ lọc trạng thái; `null` hoặc 'Tất cả' = "Tất cả".
  final String? statusFilter;

  /// US-008: Bộ lọc độ ưu tiên (CAO, TB, THẤP)
  final String? priorityFilter;

  /// US-008: Bộ lọc tag
  final String? tagFilter;

  /// US-009: Tiêu chí sắp xếp
  final BacklogSortOption sortOption;

  /// Danh sách hiển thị = [stories] sau khi search, filter rồi sort.
  final List<UserStoryModel> visibleStories;

  /// Getter tương thích ngược với code nhánh Duy
  List<UserStoryModel> get filteredStories => visibleStories;

  /// Getter tương thích ngược với code nhánh Duy
  BacklogSortOption get sortBy => sortOption;

  /// Số lượng bộ lọc đang kích hoạt (phục vụ hiển thị badge filter)
  int get activeFilterCount {
    int count = 0;
    if (searchQuery.trim().isNotEmpty) count++;
    if (statusFilter != null &&
        statusFilter!.isNotEmpty &&
        statusFilter != 'Tất cả') {
      count++;
    }
    if (priorityFilter != null &&
        priorityFilter!.isNotEmpty &&
        priorityFilter != 'Tất cả') {
      count++;
    }
    if (tagFilter != null && tagFilter!.isNotEmpty && tagFilter != 'Tất cả') {
      count++;
    }
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
      ];

  BacklogLoaded copyWith({
    List<UserStoryModel>? stories,
    bool? isSeeding,
    String? searchQuery,
    String? Function()? statusFilter,
    String? Function()? priorityFilter,
    String? Function()? tagFilter,
    BacklogSortOption? sortOption,
  }) {
    return BacklogLoaded(
      stories: stories ?? this.stories,
      isSeeding: isSeeding ?? this.isSeeding,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
      priorityFilter:
          priorityFilter != null ? priorityFilter() : this.priorityFilter,
      tagFilter: tagFilter != null ? tagFilter() : this.tagFilter,
      sortOption: sortOption ?? this.sortOption,
    );
  }
}

class BacklogError extends BacklogState {
  final String message;

  const BacklogError(this.message);

  @override
  List<Object?> get props => [message];
}
