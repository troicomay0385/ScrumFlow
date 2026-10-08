import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/data/models/project_member_display.dart';
import 'package:scrumflow/data/models/project_member_model.dart';
import 'package:scrumflow/data/models/task_model.dart';
import 'package:scrumflow/data/models/user_model.dart';
import 'package:scrumflow/data/services/performance_score_service.dart';

void main() {
  late PerformanceScoreService service;
  final now = DateTime(2026, 10, 7, 10);

  ProjectMemberDisplay makeMember({
    required String userId,
    required String name,
    ProjectRole role = ProjectRole.member,
  }) {
    return ProjectMemberDisplay(
      membership: ProjectMemberModel(
        id: 'p1_$userId',
        projectId: 'p1',
        userId: userId,
        role: role,
        createdBy: 'admin',
        createdAt: now,
        updatedAt: now,
      ),
      user: UserModel(
        id: userId,
        email: '$userId@example.com',
        fullName: name,
        createdAt: now,
        loginProvider: 'email',
      ),
    );
  }

  TaskModel makeTask({
    required String id,
    required String assigneeId,
    required String status,
    DateTime? deadline,
    DateTime? updatedAt,
  }) {
    return TaskModel(
      id: id,
      storyId: 's1',
      projectId: 'p1',
      title: 'Task $id',
      description: '',
      status: status,
      assigneeId: assigneeId,
      deadline: deadline,
      createdAt: now.subtract(const Duration(days: 2)),
      updatedAt: updatedAt ?? now,
    );
  }

  setUp(() {
    service = const PerformanceScoreService();
  });

  group('PerformanceScoreService (US-058 & US-057)', () {
    test('returns empty list when members are empty', () {
      final scores = service.calculateScores(
        members: [],
        allProjectTasks: [],
      );
      expect(scores, isEmpty);
    });

    test('calculates 100% score for brand new member with no tasks', () {
      final member = makeMember(userId: 'u1', name: 'Alice');
      final scores = service.calculateScores(
        members: [member],
        allProjectTasks: [],
      );

      expect(scores.length, 1);
      final s = scores.first;
      expect(s.userId, 'u1');
      expect(s.userName, 'Alice');
      expect(s.totalTasks, 0);
      expect(s.inProgressTasks, 0);
      expect(s.onTimeRate, 1.0);
      expect(s.workloadFactor, 1.0);
      expect(s.finalScore, 1.0);
      expect(s.isTopPick, isTrue);
      expect(s.recommendationReason, contains('Thành viên mới sẵn sàng nhận việc'));
    });

    test('calculates on-time rate and workload factor accurately', () {
      final member = makeMember(userId: 'u1', name: 'Bob');
      final deadline = DateTime(2026, 10, 5);

      final tasks = [
        // Hoàn thành đúng hạn: update trước deadline
        makeTask(
          id: 't1',
          assigneeId: 'u1',
          status: 'Done',
          deadline: deadline,
          updatedAt: deadline.subtract(const Duration(hours: 2)),
        ),
        // Hoàn thành trễ hạn: update sau deadline
        makeTask(
          id: 't2',
          assigneeId: 'u1',
          status: 'Done',
          deadline: deadline,
          updatedAt: deadline.add(const Duration(hours: 5)),
        ),
        // 1 task đang làm
        makeTask(
          id: 't3',
          assigneeId: 'u1',
          status: 'In Progress',
        ),
      ];

      final scores = service.calculateScores(
        members: [member],
        allProjectTasks: tasks,
      );

      final s = scores.first;
      expect(s.totalTasks, 3);
      expect(s.completedOnTimeTasks, 1);
      expect(s.completedOverdueTasks, 1);
      expect(s.inProgressTasks, 1);

      // onTimeRate = 1 / (1 + 1) = 0.5
      expect(s.onTimeRate, closeTo(0.5, 0.001));
      // workloadFactor = 1 - (1 / 5) = 0.8
      expect(s.workloadFactor, closeTo(0.8, 0.001));
      // finalScore = 0.5 * 0.5 + 0.3 * 0.8 + 0.2 * 1.0 = 0.25 + 0.24 + 0.20 = 0.69
      expect(s.finalScore, closeTo(0.69, 0.001));
      expect(s.scorePercentage, '69%');
    });

    test('handles maximum workload (5 or more In Progress tasks)', () {
      final member = makeMember(userId: 'u1', name: 'Charlie');
      final tasks = List.generate(
        5,
        (i) => makeTask(
          id: 't$i',
          assigneeId: 'u1',
          status: 'In Progress',
        ),
      );

      final scores = service.calculateScores(
        members: [member],
        allProjectTasks: tasks,
      );

      final s = scores.first;
      expect(s.inProgressTasks, 5);
      expect(s.workloadFactor, 0.0);
      expect(s.recommendationReason, contains('Đang tải tối đa'));
    });

    test('ranks members and marks the top recommendation (US-057 AI Top Pick)', () {
      final m1 = makeMember(userId: 'u1', name: 'Busy Bob');
      final m2 = makeMember(userId: 'u2', name: 'Optimal Alice');

      final tasks = [
        // m1 có 4 task in progress -> workloadFactor = 0.2
        ...List.generate(
          4,
          (i) => makeTask(
            id: 't_m1_$i',
            assigneeId: 'u1',
            status: 'In Progress',
          ),
        ),
        // m2 có 2 task done đúng hạn, 0 task in progress
        makeTask(
          id: 't_m2_1',
          assigneeId: 'u2',
          status: 'Done',
          deadline: DateTime(2026, 10, 5),
          updatedAt: DateTime(2026, 10, 4),
        ),
      ];

      final scores = service.calculateScores(
        members: [m1, m2],
        allProjectTasks: tasks,
      );

      expect(scores.length, 2);
      // Alice phải xếp đầu
      expect(scores.first.userId, 'u2');
      expect(scores.first.isTopPick, isTrue);
      expect(scores.first.recommendationReason, contains('🌟 Đề xuất tốt nhất:'));

      // Bob xếp thứ 2
      expect(scores[1].userId, 'u1');
      expect(scores[1].isTopPick, isFalse);
    });
  });
}
