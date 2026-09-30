import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/app/authorization/permission.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/app/authorization/role_permissions.dart';

void main() {
  group('ProjectRole Firestore mapping', () {
    test('toFirestoreValue / fromFirestoreValue round-trip', () {
      for (final role in ProjectRole.values) {
        expect(
          ProjectRole.fromFirestoreValue(role.toFirestoreValue()),
          role,
        );
      }
    });

    test('fromFirestoreValue trả về null cho giá trị không hợp lệ', () {
      expect(ProjectRole.fromFirestoreValue('ADMIN'), isNull);
      expect(ProjectRole.fromFirestoreValue(null), isNull);
      expect(ProjectRole.fromFirestoreValue(''), isNull);
    });
  });

  group('hasPermission', () {
    test('PO có quyền quản lý project, quản lý thành viên và đổi role', () {
      expect(hasPermission(ProjectRole.po, Permission.viewMembers), isTrue);
      expect(hasPermission(ProjectRole.po, Permission.manageMembers), isTrue);
      expect(hasPermission(ProjectRole.po, Permission.changeMemberRole), isTrue);
      expect(hasPermission(ProjectRole.po, Permission.manageProject), isTrue);
    });

    test('Product Backlog (US-009/010/014): PO & SM được quản lý, MEMBER chỉ xem', () {
      expect(hasPermission(ProjectRole.po, Permission.manageBacklog), isTrue);
      expect(hasPermission(ProjectRole.sm, Permission.manageBacklog), isTrue);
      expect(hasPermission(ProjectRole.member, Permission.manageBacklog), isFalse);
      expect(hasPermission(null, Permission.manageBacklog), isFalse);
      for (final role in ProjectRole.values) {
        expect(hasPermission(role, Permission.viewBacklog), isTrue);
      }
    });

    test('SM và MEMBER không có quyền quản lý thành viên và quản lý project', () {
      for (final role in [ProjectRole.sm, ProjectRole.member]) {
        expect(hasPermission(role, Permission.manageMembers), isFalse);
        expect(hasPermission(role, Permission.changeMemberRole), isFalse);
        expect(hasPermission(role, Permission.manageProject), isFalse);
      }
    });

    test('role null (không phải thành viên) không có bất kỳ quyền nào', () {
      for (final permission in Permission.values) {
        expect(hasPermission(null, permission), isFalse);
      }
    });

    test('mọi role đều có quyền viewProject', () {
      for (final role in ProjectRole.values) {
        expect(hasPermission(role, Permission.viewProject), isTrue);
      }
    });
  });
}
