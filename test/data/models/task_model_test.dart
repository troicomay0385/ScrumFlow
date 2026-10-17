import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/data/models/task_model.dart';

void main() {
  final created = DateTime(2026, 10, 1, 9);

  Map<String, dynamic> legacyMap() => {
        'id': 't1',
        'storyId': 's1',
        'title': 'Thiết kế màn hình Login',
        'description': '',
        'status': 'To Do',
        'assigneeId': 'u-phuc',
        'assigneeName': 'Phúc',
        'createdAt': Timestamp.fromDate(created),
        'updatedAt': Timestamp.fromDate(created),
      };

  group('TaskModel.fromMap — deadline & projectId (US-043, US-044)', () {
    test('dữ liệu cũ không có deadline/projectId vẫn đọc được, không crash', () {
      final task = TaskModel.fromMap(legacyMap(), 't1');
      expect(task.deadline, isNull);
      expect(task.projectId, isNull);
      expect(task.assigneeId, 'u-phuc');
      expect(task.title, 'Thiết kế màn hình Login');
    });

    test('deadline == null được giữ là null', () {
      final task = TaskModel.fromMap({...legacyMap(), 'deadline': null}, 't1');
      expect(task.deadline, isNull);
    });

    test('đọc deadline dạng Timestamp (cách lưu của TaskRepository)', () {
      final deadline = DateTime(2026, 10, 10);
      final task = TaskModel.fromMap({
        ...legacyMap(),
        'projectId': 'p1',
        'deadline': Timestamp.fromDate(deadline),
      }, 't1');
      expect(task.deadline, deadline);
      expect(task.projectId, 'p1');
    });

    test('đọc deadline dạng ISO string; giá trị sai kiểu → null', () {
      final iso = TaskModel.fromMap(
          {...legacyMap(), 'deadline': '2026-10-10T00:00:00.000'}, 't1');
      expect(iso.deadline, DateTime(2026, 10, 10));

      final garbage =
          TaskModel.fromMap({...legacyMap(), 'deadline': 'không phải ngày'}, 't1');
      expect(garbage.deadline, isNull);
      final wrongType = TaskModel.fromMap({...legacyMap(), 'deadline': 42}, 't1');
      expect(wrongType.deadline, isNull);
    });
  });

  group('TaskModel.copyWith', () {
    final task = TaskModel.fromMap({
      ...legacyMap(),
      'deadline': Timestamp.fromDate(DateTime(2026, 10, 10)),
    }, 't1');

    test('đổi assignee giữ nguyên các field khác', () {
      final updated = task.copyWith(assigneeId: 'u-hieu', assigneeName: 'Hiếu');
      expect(updated.assigneeId, 'u-hieu');
      expect(updated.assigneeName, 'Hiếu');
      expect(updated.title, task.title);
      expect(updated.deadline, task.deadline);
      expect(updated.storyId, task.storyId);
    });

    test('đổi deadline; clearDeadline/clearAssignee gán lại null', () {
      expect(task.copyWith(deadline: DateTime(2026, 11, 1)).deadline,
          DateTime(2026, 11, 1));
      expect(task.copyWith().deadline, task.deadline);
      expect(task.copyWith(clearDeadline: true).deadline, isNull);

      final unassigned = task.copyWith(clearAssignee: true);
      expect(unassigned.assigneeId, isNull);
      expect(unassigned.assigneeName, isNull);
    });

    test('đổi loggedHours giữ nguyên các field khác', () {
      final updated = task.copyWith(loggedHours: 4.5);
      expect(updated.loggedHours, 4.5);
      expect(updated.title, task.title);
      expect(updated.storyId, task.storyId);
      expect(updated.status, task.status);
    });
  });

  group('TaskModel — loggedHours (US-066)', () {
    test('thiếu field loggedHours mặc định là 0.0, không crash', () {
      final task = TaskModel.fromMap(legacyMap(), 't1');
      expect(task.loggedHours, 0.0);
    });

    test('loggedHours sai kiểu (String, boolean) trả về 0.0, không crash', () {
      final wrongTypeString =
          TaskModel.fromMap({...legacyMap(), 'loggedHours': 'hai giờ'}, 't1');
      expect(wrongTypeString.loggedHours, 0.0);

      final wrongTypeBool =
          TaskModel.fromMap({...legacyMap(), 'loggedHours': true}, 't1');
      expect(wrongTypeBool.loggedHours, 0.0);
    });

    test('đọc num dạng int và double chính xác', () {
      final intHours =
          TaskModel.fromMap({...legacyMap(), 'loggedHours': 3}, 't1');
      expect(intHours.loggedHours, 3.0);

      final doubleHours =
          TaskModel.fromMap({...legacyMap(), 'loggedHours': 2.75}, 't1');
      expect(doubleHours.loggedHours, 2.75);
    });

    test('round-trip toMap -> fromMap giữ nguyên loggedHours', () {
      final original = TaskModel(
        id: 't-test',
        storyId: 's1',
        title: 'Thử nghiệm round-trip',
        description: 'Mô tả',
        loggedHours: 6.25,
        createdAt: created,
        updatedAt: created,
      );

      final map = original.toMap();
      expect(map['loggedHours'], 6.25);

      final parsed = TaskModel.fromMap(map, 't-test');
      expect(parsed.loggedHours, 6.25);
      expect(parsed.title, original.title);
      expect(parsed.id, original.id);
    });
  });
}
