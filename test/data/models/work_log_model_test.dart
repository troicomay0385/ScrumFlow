import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/data/models/work_log_model.dart';

void main() {
  final now = DateTime(2026, 10, 17, 14, 30, 45);
  final dateOnly = DateTime(2026, 10, 17);

  group('WorkLogModel Tests (US-066)', () {
    test('toMap lưu đúng kiểu dữ liệu và Timestamp cho ngày tháng', () {
      final model = WorkLogModel(
        id: 'wl-1',
        taskId: 't-101',
        projectId: 'p-1',
        userId: 'u-phuc',
        userName: 'Lê Phúc',
        hours: 2.5,
        note: 'Hoàn thành tính năng đăng nhập',
        workDate: dateOnly,
        createdAt: now,
      );

      final map = model.toMap();
      expect(map['id'], 'wl-1');
      expect(map['taskId'], 't-101');
      expect(map['projectId'], 'p-1');
      expect(map['userId'], 'u-phuc');
      expect(map['userName'], 'Lê Phúc');
      expect(map['hours'], 2.5);
      expect(map['note'], 'Hoàn thành tính năng đăng nhập');
      expect(map['workDate'], isA<Timestamp>());
      expect((map['workDate'] as Timestamp).toDate(), dateOnly);
      expect(map['createdAt'], isA<Timestamp>());
    });

    test('fromMap parse chính xác từ Timestamp và docId', () {
      final map = {
        'taskId': 't-101',
        'projectId': 'p-1',
        'userId': 'u-phuc',
        'userName': 'Lê Phúc',
        'hours': 1.75,
        'note': 'Review PR',
        'workDate': Timestamp.fromDate(DateTime(2026, 10, 15, 18, 0, 0)),
        'createdAt': Timestamp.fromDate(now),
      };

      final model = WorkLogModel.fromMap(map, 'wl-doc-123');
      expect(model.id, 'wl-doc-123');
      expect(model.taskId, 't-101');
      expect(model.projectId, 'p-1');
      expect(model.userId, 'u-phuc');
      expect(model.userName, 'Lê Phúc');
      expect(model.hours, 1.75);
      expect(model.note, 'Review PR');
      // workDate phải được chuẩn hoá về 00:00:00 (chỉ lấy phần ngày)
      expect(model.workDate, DateTime(2026, 10, 15));
      expect(model.createdAt, now);
    });

    test('fromMap parse chính xác từ chuỗi ISO string', () {
      final map = {
        'id': 'wl-iso',
        'taskId': 't-101',
        'projectId': 'p-1',
        'userId': 'u-phuc',
        'userName': 'Lê Phúc',
        'hours': 3,
        'note': '',
        'workDate': '2026-10-12T08:30:00.000',
        'createdAt': '2026-10-12T09:00:00.000',
      };

      final model = WorkLogModel.fromMap(map);
      expect(model.id, 'wl-iso');
      expect(model.hours, 3.0);
      expect(model.workDate, DateTime(2026, 10, 12));
    });

    test('fromMap chịu lỗi an toàn khi thiếu field hoặc sai kiểu', () {
      final emptyMap = <String, dynamic>{};
      final model = WorkLogModel.fromMap(emptyMap);

      expect(model.id, '');
      expect(model.taskId, '');
      expect(model.projectId, '');
      expect(model.userId, '');
      expect(model.userName, '');
      expect(model.hours, 0.0);
      expect(model.note, '');
      expect(model.workDate, isNotNull);
      expect(model.createdAt, isNotNull);

      final invalidTypesMap = <String, dynamic>{
        'hours': 'hai giờ',
        'workDate': 12345,
        'createdAt': false,
      };
      final model2 = WorkLogModel.fromMap(invalidTypesMap);
      expect(model2.hours, 0.0);
    });

    test('copyWith cập nhật chính xác các field', () {
      final original = WorkLogModel(
        id: 'wl-1',
        taskId: 't-1',
        projectId: 'p-1',
        userId: 'u-1',
        userName: 'User 1',
        hours: 1.0,
        note: 'Note 1',
        workDate: dateOnly,
        createdAt: now,
      );

      final updated = original.copyWith(
        hours: 2.25,
        note: 'Note updated',
      );

      expect(updated.id, 'wl-1');
      expect(updated.hours, 2.25);
      expect(updated.note, 'Note updated');
      expect(updated.taskId, original.taskId);
    });

    test('Equatable so sánh chính xác theo giá trị', () {
      final item1 = WorkLogModel(
        id: 'wl-1',
        taskId: 't-1',
        projectId: 'p-1',
        userId: 'u-1',
        userName: 'User 1',
        hours: 1.0,
        workDate: dateOnly,
        createdAt: now,
      );

      final item2 = WorkLogModel(
        id: 'wl-1',
        taskId: 't-1',
        projectId: 'p-1',
        userId: 'u-1',
        userName: 'User 1',
        hours: 1.0,
        workDate: dateOnly,
        createdAt: now,
      );

      expect(item1, equals(item2));
    });
  });
}
