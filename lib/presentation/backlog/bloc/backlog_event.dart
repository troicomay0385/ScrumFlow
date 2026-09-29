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

/// Đổi bộ lọc trạng thái; `null` = "Tất cả".
class BacklogStatusFilterChanged extends BacklogEvent {
  final String? status;

  const BacklogStatusFilterChanged(this.status);

  @override
  List<Object?> get props => [status];
}

/// Đổi tiêu chí sắp xếp hiển thị (US-009).
class BacklogSortChanged extends BacklogEvent {
  final BacklogSortOption sortOption;

  const BacklogSortChanged(this.sortOption);

  @override
  List<Object?> get props => [sortOption];
}
