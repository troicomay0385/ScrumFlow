import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/data/models/sprint_progress.dart';
import 'package:scrumflow/data/models/task_model.dart';

void main() {
  TaskModel createTask({required String id, required String status}) {
    final now = DateTime(2026, 10, 1);
    return TaskModel(
      id: id,
      storyId: 'story-1',
      title: 'Task $id',
      description: '',
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('SprintProgress', () {
    test('0 task: trả về các trường bằng 0, donePercent = 0 và isEmpty = true', () {
      final progress = SprintProgress.fromTasks([]);

      expect(progress.todo, 0);
      expect(progress.inProgress, 0);
      expect(progress.done, 0);
      expect(progress.total, 0);
      expect(progress.donePercent, 0);
      expect(progress.isEmpty, isTrue);
    });

    test('toàn Done: donePercent = 100% và isEmpty = false', () {
      final tasks = [
        createTask(id: '1', status: 'Done'),
        createTask(id: '2', status: 'Done'),
        createTask(id: '3', status: 'Done'),
      ];
      final progress = SprintProgress.fromTasks(tasks);

      expect(progress.todo, 0);
      expect(progress.inProgress, 0);
      expect(progress.done, 3);
      expect(progress.total, 3);
      expect(progress.donePercent, 100);
      expect(progress.isEmpty, isFalse);
    });

    test('status lạ hoặc không hợp lệ được quy về todo qua TaskStatus.normalize', () {
      final tasks = [
        createTask(id: '1', status: 'UnknownStatus'),
        createTask(id: '2', status: 'Blocked'),
        createTask(id: '3', status: ''),
        createTask(id: '4', status: 'In Progress'),
        createTask(id: '5', status: 'Done'),
      ];
      final progress = SprintProgress.fromTasks(tasks);

      // 3 task status lạ được quy về To Do
      expect(progress.todo, 3);
      expect(progress.inProgress, 1);
      expect(progress.done, 1);
      expect(progress.total, 5);
      expect(progress.donePercent, 20); // 1 / 5 = 20%
    });

    test('làm tròn donePercent chính xác theo số nguyên gần nhất', () {
      // 1 / 3 = 33.333% -> làm tròn thành 33%
      final progress33 = SprintProgress.fromTasks([
        createTask(id: '1', status: 'Done'),
        createTask(id: '2', status: 'To Do'),
        createTask(id: '3', status: 'In Progress'),
      ]);
      expect(progress33.donePercent, 33);

      // 2 / 3 = 66.666% -> làm tròn thành 67%
      final progress67 = SprintProgress.fromTasks([
        createTask(id: '1', status: 'Done'),
        createTask(id: '2', status: 'Done'),
        createTask(id: '3', status: 'In Progress'),
      ]);
      expect(progress67.donePercent, 67);

      // 1 / 6 = 16.666% -> làm tròn thành 17%
      final progress17 = SprintProgress.fromTasks([
        createTask(id: '1', status: 'Done'),
        createTask(id: '2', status: 'To Do'),
        createTask(id: '3', status: 'To Do'),
        createTask(id: '4', status: 'To Do'),
        createTask(id: '5', status: 'In Progress'),
        createTask(id: '6', status: 'In Progress'),
      ]);
      expect(progress17.donePercent, 17);
    });

    test('so sánh Equatable props', () {
      const p1 = SprintProgress(todo: 1, inProgress: 2, done: 3);
      const p2 = SprintProgress(todo: 1, inProgress: 2, done: 3);
      const p3 = SprintProgress(todo: 0, inProgress: 2, done: 3);

      expect(p1, equals(p2));
      expect(p1 == p3, isFalse);
    });
  });
}
