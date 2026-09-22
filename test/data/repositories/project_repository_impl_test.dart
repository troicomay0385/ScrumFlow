import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/data/datasources/firebase_auth_datasource.dart';
import 'package:scrumflow/data/datasources/project_datasource.dart';
import 'package:scrumflow/data/datasources/project_member_datasource.dart';
import 'package:scrumflow/data/models/project_member_model.dart';
import 'package:scrumflow/data/models/project_model.dart';
import 'package:scrumflow/data/repositories/project_repository_impl.dart';

class MockProjectDataSource extends Mock implements ProjectDataSource {}

class MockProjectMemberDataSource extends Mock
    implements ProjectMemberDataSource {}

class MockFirebaseAuthDataSource extends Mock
    implements FirebaseAuthDataSource {}

class MockUser extends Mock implements User {}

void main() {
  late MockProjectDataSource projectDataSource;
  late MockProjectMemberDataSource memberDataSource;
  late MockFirebaseAuthDataSource authDataSource;
  late MockUser user;
  late ProjectRepositoryImpl repository;

  const currentUid = 'user-po-123';
  const projectId = 'project-1';

  setUpAll(() {
    registerFallbackValue(ProjectRole.po);
  });

  setUp(() {
    projectDataSource = MockProjectDataSource();
    memberDataSource = MockProjectMemberDataSource();
    authDataSource = MockFirebaseAuthDataSource();
    user = MockUser();

    when(() => user.uid).thenReturn(currentUid);
    when(() => authDataSource.currentUser).thenReturn(user);

    repository = ProjectRepositoryImpl(
      projectDataSource: projectDataSource,
      memberDataSource: memberDataSource,
      authDataSource: authDataSource,
    );
  });

  group('createProject', () {
    test('tạo project thành công và tự động gán user làm PO', () async {
      final now = DateTime(2026, 1, 1);
      final createdProject = ProjectModel(
        id: projectId,
        name: 'Dự án mẫu',
        description: 'Mục tiêu backlog và sprint',
        createdBy: currentUid,
        createdAt: now,
        updatedAt: now,
      );

      final membership = ProjectMemberModel(
        id: '${projectId}_$currentUid',
        projectId: projectId,
        userId: currentUid,
        role: ProjectRole.po,
        createdBy: currentUid,
        createdAt: now,
        updatedAt: now,
      );

      when(() => projectDataSource.createProject(
            name: 'Dự án mẫu',
            description: 'Mục tiêu backlog và sprint',
            createdBy: currentUid,
          )).thenAnswer((_) async => createdProject);

      when(() => memberDataSource.createMembership(
            projectId: projectId,
            userId: currentUid,
            role: ProjectRole.po,
            createdBy: currentUid,
          )).thenAnswer((_) async => membership);

      final result = await repository.createProject(
        name: 'Dự án mẫu',
        description: 'Mục tiêu backlog và sprint',
      );

      expect(result.id, projectId);
      expect(result.name, 'Dự án mẫu');
      expect(result.description, 'Mục tiêu backlog và sprint');
      verify(() => memberDataSource.createMembership(
            projectId: projectId,
            userId: currentUid,
            role: ProjectRole.po,
            createdBy: currentUid,
          )).called(1);
    });

    test('rollback xoá project nếu tạo PO membership thất bại', () async {
      final now = DateTime(2026, 1, 1);
      final createdProject = ProjectModel(
        id: projectId,
        name: 'Dự án lỗi',
        description: 'Mô tả',
        createdBy: currentUid,
        createdAt: now,
        updatedAt: now,
      );

      when(() => projectDataSource.createProject(
            name: any(named: 'name'),
            description: any(named: 'description'),
            createdBy: any(named: 'createdBy'),
          )).thenAnswer((_) async => createdProject);

      when(() => memberDataSource.createMembership(
            projectId: any(named: 'projectId'),
            userId: any(named: 'userId'),
            role: any(named: 'role'),
            createdBy: any(named: 'createdBy'),
          )).thenThrow(Exception('Firestore membership error'));

      when(() => projectDataSource.deleteProject(projectId))
          .thenAnswer((_) async {});

      await expectLater(
        repository.createProject(name: 'Dự án lỗi', description: 'Mô tả'),
        throwsA(isA<Exception>()),
      );

      verify(() => projectDataSource.deleteProject(projectId)).called(1);
    });
  });

  group('updateProject', () {
    test('PO cập nhật thành công thông tin mục tiêu / mô tả project', () async {
      final now = DateTime(2026, 1, 1);
      final poMembership = ProjectMemberModel(
        id: '${projectId}_$currentUid',
        projectId: projectId,
        userId: currentUid,
        role: ProjectRole.po,
        createdBy: currentUid,
        createdAt: now,
        updatedAt: now,
      );

      when(() => memberDataSource.getMembership(
            projectId: projectId,
            userId: currentUid,
          )).thenAnswer((_) async => poMembership);

      when(() => projectDataSource.updateProject(
            projectId: projectId,
            name: 'Tên mới',
            description: 'Mục tiêu mới cập nhật',
          )).thenAnswer((_) async {});

      await repository.updateProject(
        projectId: projectId,
        name: 'Tên mới',
        description: 'Mục tiêu mới cập nhật',
      );

      verify(() => projectDataSource.updateProject(
            projectId: projectId,
            name: 'Tên mới',
            description: 'Mục tiêu mới cập nhật',
          )).called(1);
    });

    test('Member thường (không phải PO) bị từ chối cập nhật project', () async {
      final now = DateTime(2026, 1, 1);
      final regularMembership = ProjectMemberModel(
        id: '${projectId}_$currentUid',
        projectId: projectId,
        userId: currentUid,
        role: ProjectRole.member,
        createdBy: 'other-user',
        createdAt: now,
        updatedAt: now,
      );

      when(() => memberDataSource.getMembership(
            projectId: projectId,
            userId: currentUid,
          )).thenAnswer((_) async => regularMembership);

      expect(
        () => repository.updateProject(
          projectId: projectId,
          name: 'Tên mới',
          description: 'Mục tiêu mới',
        ),
        throwsA(
          predicate((e) =>
              e is Exception &&
              e.toString().contains('không có quyền chỉnh sửa')),
        ),
      );

      verifyNever(() => projectDataSource.updateProject(
            projectId: any(named: 'projectId'),
            name: any(named: 'name'),
            description: any(named: 'description'),
          ));
    });

    test('User không thuộc project bị từ chối cập nhật project', () async {
      when(() => memberDataSource.getMembership(
            projectId: projectId,
            userId: currentUid,
          )).thenAnswer((_) async => null);

      expect(
        () => repository.updateProject(
          projectId: projectId,
          name: 'Tên mới',
          description: 'Mục tiêu mới',
        ),
        throwsA(
          predicate((e) =>
              e is Exception &&
              e.toString().contains('không có quyền chỉnh sửa')),
        ),
      );
    });
  });
}
