import 'package:equatable/equatable.dart';

enum BacklogSortBy {
  priorityDesc('Ưu tiên: Cao -> Thấp'),
  priorityAsc('Ưu tiên: Thấp -> Cao'),
  dueDateAsc('Hạn chót: Gần nhất'),
  pointsDesc('Story Points: Cao -> Thấp'),
  pointsAsc('Story Points: Thấp -> Cao'),
  storyKeyAsc('Mã US: Tăng dần');

  final String label;
  const BacklogSortBy(this.label);
}

abstract class BacklogEvent extends Equatable {
  const BacklogEvent();

  @override
  List<Object?> get props => [];
}

class BacklogSubscriptionRequested extends BacklogEvent {
  final String projectId;

  const BacklogSubscriptionRequested(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

class BacklogSeedMockRequested extends BacklogEvent {
  final String projectId;

  const BacklogSeedMockRequested(this.projectId);

  @override
  List<Object?> get props => [projectId];
}

/// US-007: Thay đổi từ khóa tìm kiếm
class BacklogSearchChanged extends BacklogEvent {
  final String query;

  const BacklogSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

/// US-008: Thay đổi bộ lọc Trạng thái (Tất cả, To Do, In Progress, Done, Rejected)
class BacklogStatusFilterChanged extends BacklogEvent {
  final String status;

  const BacklogStatusFilterChanged(this.status);

  @override
  List<Object?> get props => [status];
}

/// US-008: Thay đổi bộ lọc Độ ưu tiên (Tất cả, CAO, TB, THẤP)
class BacklogPriorityFilterChanged extends BacklogEvent {
  final String priority;

  const BacklogPriorityFilterChanged(this.priority);

  @override
  List<Object?> get props => [priority];
}

/// US-008: Thay đổi bộ lọc Nhãn / Tag
class BacklogTagFilterChanged extends BacklogEvent {
  final String tag;

  const BacklogTagFilterChanged(this.tag);

  @override
  List<Object?> get props => [tag];
}

/// US-009: Thay đổi tiêu chí sắp xếp
class BacklogSortChanged extends BacklogEvent {
  final BacklogSortBy sortBy;

  const BacklogSortChanged(this.sortBy);

  @override
  List<Object?> get props => [sortBy];
}

/// Đặt lại toàn bộ bộ lọc và từ khóa tìm kiếm về mặc định
class BacklogFilterResetRequested extends BacklogEvent {
  const BacklogFilterResetRequested();
}
