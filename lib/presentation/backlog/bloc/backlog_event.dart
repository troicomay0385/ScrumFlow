import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;
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

/// Đổi bộ lọc trạng thái; `null` hoặc 'Tất cả' = "Tất cả".
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

/// Đặt lại toàn bộ bộ lọc và từ khóa tìm kiếm về mặc định
class BacklogFilterResetRequested extends BacklogEvent {
  const BacklogFilterResetRequested();
}

/// Đổi tiêu chí sắp xếp hiển thị (US-009).
class BacklogSortChanged extends BacklogEvent {
  final BacklogSortOption sortOption;

  const BacklogSortChanged(this.sortOption);

  @override
  List<Object?> get props => [sortOption];
}

/// Yêu cầu xóa hàng loạt User Stories (US-053).
class BacklogDeleteStoriesRequested extends BacklogEvent {
  final String projectId;
  final List<String> storyIds;

  const BacklogDeleteStoriesRequested({
    required this.projectId,
    required this.storyIds,
  });

  @override
  List<Object?> get props => [projectId, storyIds];
}

/// Yêu cầu load trang đầu tiên theo phân trang server-side (US-054).
class BacklogPaginatedLoadRequested extends BacklogEvent {
  final String projectId;
  final int pageSize;
  final String? statusFilter;

  const BacklogPaginatedLoadRequested({
    required this.projectId,
    this.pageSize = 10,
    this.statusFilter,
  });

  @override
  List<Object?> get props => [projectId, pageSize, statusFilter];
}

/// Yêu cầu load trang tiếp theo (cursor-based).
class BacklogNextPageRequested extends BacklogEvent {
  final String projectId;
  final int pageSize;
  final String? statusFilter;
  final DocumentSnapshot? lastDocument;

  const BacklogNextPageRequested({
    required this.projectId,
    this.pageSize = 10,
    this.statusFilter,
    this.lastDocument,
  });

  @override
  List<Object?> get props => [projectId, pageSize, statusFilter];
}
