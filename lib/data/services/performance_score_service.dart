import '../models/performance_score_model.dart';
import '../models/project_member_display.dart';
import '../models/task_model.dart';

/// Dịch vụ tính toán điểm hiệu suất thành viên (US-058) và Trợ lý AI gợi ý phân công (US-057).
class PerformanceScoreService {
  /// Trọng số theo công thức US-058
  final double w1; // Tỷ lệ đúng hạn (mặc định 0.5)
  final double w2; // Mức độ rảnh rỗi / workload (mặc định 0.3)
  final double w3; // Điểm đánh giá cơ bản (mặc định 0.2)
  final int workloadMax; // Giới hạn task In Progress tối đa (mặc định 5)

  const PerformanceScoreService({
    this.w1 = 0.5,
    this.w2 = 0.3,
    this.w3 = 0.2,
    this.workloadMax = 5,
  });

  /// Tính điểm hiệu suất cho danh sách thành viên dựa trên các tasks trong dự án.
  List<MemberPerformanceScore> calculateScores({
    required List<ProjectMemberDisplay> members,
    required List<TaskModel> allProjectTasks,
    DateTime? now,
  }) {
    if (members.isEmpty) return [];

    final results = <MemberPerformanceScore>[];

    for (final member in members) {
      final userTasks = allProjectTasks
          .where((t) => t.assigneeId == member.userId)
          .toList();

      final totalTasks = userTasks.length;
      int completedOnTime = 0;
      int completedOverdue = 0;
      int inProgress = 0;

      for (final t in userTasks) {
        if (t.status == 'Done') {
          if (t.deadline == null) {
            completedOnTime++;
          } else {
            // Task hoàn thành: kiểm tra thời điểm cập nhật so với deadline
            if (t.updatedAt.isBefore(t.deadline!) ||
                t.updatedAt.isAtSameMomentAs(t.deadline!)) {
              completedOnTime++;
            } else {
              completedOverdue++;
            }
          }
        } else if (t.status == 'In Progress') {
          inProgress++;
        }
      }

      final completedTasks = completedOnTime + completedOverdue;

      // 1. onTimeRate:
      // Nếu đã có task hoàn thành: completedOnTime / completedTasks
      // Nếu thành viên mới (chưa có task nào): giả định 1.0 (sẵn sàng làm việc)
      final double onTimeRate = completedTasks > 0
          ? (completedOnTime / completedTasks).clamp(0.0, 1.0)
          : 1.0;

      // 2. workloadFactor: 1 - (inProgress / workloadMax)
      final double workloadFactor =
          (1.0 - (inProgress / workloadMax.toDouble())).clamp(0.0, 1.0);

      // 3. ratingScore: 1.0
      const double ratingScore = 1.0;

      // 4. finalScore theo công thức US-058
      final double finalScore =
          (w1 * onTimeRate + w2 * workloadFactor + w3 * ratingScore)
              .clamp(0.0, 1.0);

      // 5. Tạo lý do gợi ý AI thông minh
      String reason;
      if (totalTasks == 0) {
        reason = 'Thành viên mới sẵn sàng nhận việc • Workload tối ưu (0/5)';
      } else if (inProgress == 0 && onTimeRate >= 0.9) {
        reason =
            'Tỷ lệ đúng hạn xuất sắc ${(onTimeRate * 100).round()}% • Đang hoàn toàn rảnh rỗi';
      } else if (inProgress >= workloadMax) {
        reason = 'Đang tải tối đa ($inProgress/$workloadMax task đang làm)';
      } else {
        reason =
            'Đúng hạn ${(onTimeRate * 100).round()}% • Đang xử lý $inProgress/$workloadMax task';
      }

      final displayName = member.user?.fullName.isNotEmpty == true
          ? member.user!.fullName
          : (member.user?.email ?? 'Thành viên');

      results.add(MemberPerformanceScore(
        userId: member.userId,
        userName: displayName,
        userEmail: member.user?.email,
        role: member.membership.role,
        totalTasks: totalTasks,
        completedOnTimeTasks: completedOnTime,
        completedOverdueTasks: completedOverdue,
        inProgressTasks: inProgress,
        onTimeRate: onTimeRate,
        workloadFactor: workloadFactor,
        ratingScore: ratingScore,
        finalScore: finalScore,
        recommendationReason: reason,
      ));
    }

    // Sắp xếp điểm giảm dần: người có finalScore cao nhất đứng đầu
    results.sort((a, b) {
      final scoreCmp = b.finalScore.compareTo(a.finalScore);
      if (scoreCmp != 0) return scoreCmp;
      return a.inProgressTasks.compareTo(b.inProgressTasks);
    });

    if (results.isNotEmpty) {
      // Đánh dấu Top 1 đề xuất tốt nhất
      final top = results.first;
      results[0] = MemberPerformanceScore(
        userId: top.userId,
        userName: top.userName,
        userEmail: top.userEmail,
        role: top.role,
        totalTasks: top.totalTasks,
        completedOnTimeTasks: top.completedOnTimeTasks,
        completedOverdueTasks: top.completedOverdueTasks,
        inProgressTasks: top.inProgressTasks,
        onTimeRate: top.onTimeRate,
        workloadFactor: top.workloadFactor,
        ratingScore: top.ratingScore,
        finalScore: top.finalScore,
        recommendationReason:
            '🌟 Đề xuất tốt nhất: ${top.recommendationReason}',
        isTopPick: true,
      );
    }

    return results;
  }
}
