import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/app/constants/sprint_status.dart';
import 'package:scrumflow/app/constants/task_status.dart';

void main() {
  group('TaskStatus', () {
    test('hằng số giá trị chuẩn', () {
      expect(TaskStatus.todo, 'To Do');
      expect(TaskStatus.inProgress, 'In Progress');
      expect(TaskStatus.done, 'Done');
      expect(TaskStatus.values, ['To Do', 'In Progress', 'Done']);
    });

    test('next: chuyển trạng thái tuần tự', () {
      expect(TaskStatus.next(TaskStatus.todo), TaskStatus.inProgress);
      expect(TaskStatus.next(TaskStatus.inProgress), TaskStatus.done);
      expect(TaskStatus.next(TaskStatus.done), isNull);
      expect(TaskStatus.next('other'), isNull);
    });

    test('previous: quay về trạng thái trước đó', () {
      expect(TaskStatus.previous(TaskStatus.done), TaskStatus.inProgress);
      expect(TaskStatus.previous(TaskStatus.inProgress), TaskStatus.todo);
      expect(TaskStatus.previous(TaskStatus.todo), isNull);
      expect(TaskStatus.previous('other'), isNull);
    });

    test('normalize: trả về giá trị chuẩn hoặc fallback về todo', () {
      expect(TaskStatus.normalize('To Do'), TaskStatus.todo);
      expect(TaskStatus.normalize('to do'), TaskStatus.todo);
      expect(TaskStatus.normalize('In Progress'), TaskStatus.inProgress);
      expect(TaskStatus.normalize('in progress'), TaskStatus.inProgress);
      expect(TaskStatus.normalize('Done'), TaskStatus.done);
      expect(TaskStatus.normalize('done'), TaskStatus.done);
      expect(TaskStatus.normalize('random'), TaskStatus.todo);
      expect(TaskStatus.normalize(''), TaskStatus.todo);
    });
  });

  group('SprintStatus', () {
    test('hằng số giá trị chuẩn', () {
      expect(SprintStatus.planned, 'Planned');
      expect(SprintStatus.active, 'Active');
      expect(SprintStatus.completed, 'Completed');
      expect(SprintStatus.values, ['Planned', 'Active', 'Completed']);
    });
  });
}
