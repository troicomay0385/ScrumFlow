import 'package:equatable/equatable.dart';

import '../utils/backlog_view.dart';

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

/// US-008: Đổi bộ lọc trạng thái; `null` hoặc 'Tất cả' = "Tất cả".
class BacklogStatusFilterChanged extends BacklogEvent {
  final String? status;

  const BacklogStatusFilterChanged(this.status);

  @override
  List<Object?> get props => [status];
}

/// US-008: Thay đổi bộ lọc Độ ưu tiên (Tất cả, CAO, TB, THẤP)
class BacklogPriorityFilterChanged extends BacklogEvent {
  final String? priority;

  const BacklogPriorityFilterChanged(this.priority);

  @override
  List<Object?> get props => [priority];
}

/// US-008: Thay đổi bộ lọc Nhãn / Tag
class BacklogTagFilterChanged extends BacklogEvent {
  final String? tag;

  const BacklogTagFilterChanged(this.tag);

  @override
  List<Object?> get props => [tag];
}

/// US-009: Đổi tiêu chí sắp xếp hiển thị.
class BacklogSortChanged extends BacklogEvent {
  final BacklogSortOption sortOption;

  const BacklogSortChanged(this.sortOption);

  @override
  List<Object?> get props => [sortOption];
}

/// Đặt lại toàn bộ bộ lọc và từ khóa tìm kiếm về mặc định
class BacklogFilterResetRequested extends BacklogEvent {
  const BacklogFilterResetRequested();
}
