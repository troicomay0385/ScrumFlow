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

  /// Bộ lọc trạng thái; `null` = "Tất cả".
  final String? statusFilter;
  final BacklogSortOption sortOption;

  /// Danh sách hiển thị = [stories] sau khi filter rồi sort.
  final List<UserStoryModel> visibleStories;

  BacklogLoaded({
    required this.stories,
    this.isSeeding = false,
    this.statusFilter,
    this.sortOption = BacklogSortOption.defaultOrder,
  }) : visibleStories = applyBacklogView(
          stories,
          statusFilter: statusFilter,
          sortOption: sortOption,
        );

  @override
  List<Object?> get props => [stories, isSeeding, statusFilter, sortOption];

  BacklogLoaded copyWith({
    List<UserStoryModel>? stories,
    bool? isSeeding,
    String? Function()? statusFilter,
    BacklogSortOption? sortOption,
  }) {
    return BacklogLoaded(
      stories: stories ?? this.stories,
      isSeeding: isSeeding ?? this.isSeeding,
      statusFilter: statusFilter != null ? statusFilter() : this.statusFilter,
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
