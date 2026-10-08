import 'package:equatable/equatable.dart';

import '../../app/authorization/project_role.dart';

/// Model điểm hiệu suất và thông số phân công của 1 thành viên (US-058, US-057).
class MemberPerformanceScore extends Equatable {
  final String userId;
  final String userName;
  final String? userEmail;
  final ProjectRole role;

  /// Tổng số task được giao trong dự án
  final int totalTasks;

  /// Số task hoàn thành đúng hạn (Status 'Done' và hoàn thành trước/đúng deadline)
  final int completedOnTimeTasks;

  /// Số task đã hoàn thành nhưng quá hạn (Status 'Done' nhưng sau deadline)
  final int completedOverdueTasks;

  /// Số task đang thực hiện (Status 'In Progress')
  final int inProgressTasks;

  /// Tỷ lệ đúng hạn: w1 factor (0.0 -> 1.0)
  final double onTimeRate;

  /// Mức độ rảnh rỗi / tải công việc: w2 factor (0.0 -> 1.0)
  /// Tính theo công thức: clamp(1 - (inProgressTasks / workloadMax), 0.0, 1.0)
  final double workloadFactor;

  /// Điểm đánh giá cơ bản: w3 factor (1.0 = 100%)
  final double ratingScore;

  /// Điểm hiệu suất tổng hợp: 0.0 -> 1.0 (US-058)
  /// performance_score = w1*(onTimeRate) + w2*(workloadFactor) + w3*(ratingScore)
  final double finalScore;

  /// Lý do gợi ý của Trợ lý AI (US-057)
  final String recommendationReason;

  /// Có phải là thành viên được đề xuất tốt nhất không
  final bool isTopPick;

  const MemberPerformanceScore({
    required this.userId,
    required this.userName,
    this.userEmail,
    required this.role,
    required this.totalTasks,
    required this.completedOnTimeTasks,
    this.completedOverdueTasks = 0,
    required this.inProgressTasks,
    required this.onTimeRate,
    required this.workloadFactor,
    this.ratingScore = 1.0,
    required this.finalScore,
    required this.recommendationReason,
    this.isTopPick = false,
  });

  /// Hiển thị phần trăm điểm số (VD: "94%")
  String get scorePercentage => '${(finalScore * 100).round()}%';

  /// Nhãn hiển thị mức độ tải (VD: "1/5 task đang làm")
  String get workloadText => '$inProgressTasks/5 task đang làm';

  @override
  List<Object?> get props => [
        userId,
        userName,
        userEmail,
        role,
        totalTasks,
        completedOnTimeTasks,
        completedOverdueTasks,
        inProgressTasks,
        onTimeRate,
        workloadFactor,
        ratingScore,
        finalScore,
        recommendationReason,
        isTopPick,
      ];
}
