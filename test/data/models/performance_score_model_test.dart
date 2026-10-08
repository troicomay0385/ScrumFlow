import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/data/models/performance_score_model.dart';

void main() {
  group('MemberPerformanceScore (US-058 & US-057)', () {
    test('creates model and calculates formatters accurately', () {
      const score = MemberPerformanceScore(
        userId: 'u1',
        userName: 'Nguyen Van A',
        userEmail: 'vana@example.com',
        role: ProjectRole.member,
        totalTasks: 10,
        completedOnTimeTasks: 8,
        completedOverdueTasks: 1,
        inProgressTasks: 2,
        onTimeRate: 0.88,
        workloadFactor: 0.6,
        ratingScore: 1.0,
        finalScore: 0.82,
        recommendationReason: 'Đúng hạn 88% • Đang xử lý 2/5 task',
        isTopPick: true,
      );

      expect(score.userId, 'u1');
      expect(score.userName, 'Nguyen Van A');
      expect(score.userEmail, 'vana@example.com');
      expect(score.role, ProjectRole.member);
      expect(score.totalTasks, 10);
      expect(score.completedOnTimeTasks, 8);
      expect(score.completedOverdueTasks, 1);
      expect(score.inProgressTasks, 2);
      expect(score.onTimeRate, 0.88);
      expect(score.workloadFactor, 0.6);
      expect(score.ratingScore, 1.0);
      expect(score.finalScore, 0.82);
      expect(score.isTopPick, isTrue);

      // Formatters
      expect(score.scorePercentage, '82%');
      expect(score.workloadText, '2/5 task đang làm');
    });

    test('supports value equality via Equatable', () {
      const score1 = MemberPerformanceScore(
        userId: 'u1',
        userName: 'Nguyen Van A',
        role: ProjectRole.member,
        totalTasks: 5,
        completedOnTimeTasks: 5,
        inProgressTasks: 0,
        onTimeRate: 1.0,
        workloadFactor: 1.0,
        finalScore: 1.0,
        recommendationReason: 'Tối ưu',
      );

      const score2 = MemberPerformanceScore(
        userId: 'u1',
        userName: 'Nguyen Van A',
        role: ProjectRole.member,
        totalTasks: 5,
        completedOnTimeTasks: 5,
        inProgressTasks: 0,
        onTimeRate: 1.0,
        workloadFactor: 1.0,
        finalScore: 1.0,
        recommendationReason: 'Tối ưu',
      );

      expect(score1, equals(score2));
      expect(score1.props, equals(score2.props));
    });
  });
}
