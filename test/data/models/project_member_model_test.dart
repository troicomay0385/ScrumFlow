import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/data/models/project_member_model.dart';

void main() {
  final baseMap = {
    'projectId': 'p1',
    'userId': 'u1',
    'createdBy': 'u1',
    'createdAt': DateTime(2026, 1, 1).toIso8601String(),
    'updatedAt': DateTime(2026, 1, 1).toIso8601String(),
  };

  test('fromMap parse role hợp lệ đúng và hasInvalidRole = false', () {
    final map = {...baseMap, 'role': 'PO'};
    final member = ProjectMemberModel.fromMap('p1_u1', map);

    expect(member.role, ProjectRole.po);
    expect(member.hasInvalidRole, isFalse);
  });

  test('fromMap KHÔNG throw khi role trong Firestore không hợp lệ — '
      'fallback về ProjectRole.member (quyền thấp nhất)', () {
    final map = {...baseMap, 'role': 'SUPER_ADMIN'};

    final member = ProjectMemberModel.fromMap('p1_u1', map);

    expect(member.role, ProjectRole.member);
    expect(member.hasInvalidRole, isTrue);
  });

  test('membershipIdFor tạo id xác định theo cặp projectId/userId', () {
    final id = ProjectMemberModel.membershipIdFor(projectId: 'p1', userId: 'u1');
    expect(id, 'p1_u1');
  });
}
