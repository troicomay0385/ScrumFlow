import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/data/datasources/attachment_datasource.dart';
import 'package:scrumflow/data/datasources/firebase_auth_datasource.dart';
import 'package:scrumflow/data/datasources/firestore_datasource.dart';
import 'package:scrumflow/data/datasources/project_member_datasource.dart';
import 'package:scrumflow/data/models/attachment_model.dart';
import 'package:scrumflow/data/models/project_member_model.dart';
import 'package:scrumflow/data/models/user_model.dart';
import 'package:scrumflow/data/repositories/attachment_repository_impl.dart';

class MockAttachmentDataSource extends Mock implements AttachmentDataSource {}

class MockProjectMemberDataSource extends Mock
    implements ProjectMemberDataSource {}

class MockFirestoreDataSource extends Mock implements FirestoreDataSource {}

class MockFirebaseAuthDataSource extends Mock
    implements FirebaseAuthDataSource {}

class MockUser extends Mock implements User {}

class FakeAttachmentTarget extends Fake implements AttachmentTarget {}

class FakeAttachmentModel extends Fake implements AttachmentModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAttachmentTarget());
    registerFallbackValue(FakeAttachmentModel());
  });

  const uid = 'uid-test';
  const projectId = 'p1';
  const storyTarget = AttachmentTarget.story(projectId: projectId, storyId: 's1');
  const taskTarget = AttachmentTarget.task(projectId: projectId, taskId: 't1');
  final now = DateTime(2026, 10, 7, 10);

  late MockAttachmentDataSource dataSource;
  late MockProjectMemberDataSource memberDataSource;
  late MockFirestoreDataSource userDataSource;
  late MockFirebaseAuthDataSource authDataSource;
  late MockUser user;
  late AttachmentRepositoryImpl repository;

  void givenMembership(bool isMember) {
    when(() => memberDataSource.getMembership(
          projectId: projectId,
          userId: uid,
        )).thenAnswer((_) async => !isMember
        ? null
        : ProjectMemberModel(
            id: '${projectId}_$uid',
            projectId: projectId,
            userId: uid,
            role: ProjectRole.member,
            createdBy: 'owner',
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ));
  }

  setUp(() {
    dataSource = MockAttachmentDataSource();
    memberDataSource = MockProjectMemberDataSource();
    userDataSource = MockFirestoreDataSource();
    authDataSource = MockFirebaseAuthDataSource();
    user = MockUser();

    when(() => user.uid).thenReturn(uid);
    when(() => user.displayName).thenReturn('Duy Member');
    when(() => user.email).thenReturn('duy@scrumflow.com');
    when(() => authDataSource.currentUser).thenReturn(user);

    when(() => userDataSource.getUserProfile(uid)).thenAnswer(
      (_) async => UserModel(
        id: uid,
        email: 'duy@scrumflow.com',
        fullName: 'Duy FullName',
        createdAt: DateTime(2026, 1, 1),
        loginProvider: 'email',
      ),
    );

    repository = AttachmentRepositoryImpl(
      dataSource: dataSource,
      memberDataSource: memberDataSource,
      userDataSource: userDataSource,
      authDataSource: authDataSource,
      now: () => now,
    );
  });

  group('AttachmentRepositoryImpl', () {
    test('streamAttachments delegates to dataSource and propagates items', () {
      final list = [
        AttachmentModel(
          id: 'a1',
          projectId: projectId,
          fileName: 'f1.pdf',
          fileSize: 100,
          fileType: 'pdf',
          uploadedById: uid,
          uploadedByName: 'Duy',
          createdAt: now,
        ),
      ];
      when(() => dataSource.streamAttachments(storyTarget))
          .thenAnswer((_) => Stream.value(list));

      expect(repository.streamAttachments(storyTarget), emits(list));
    });

    test('addAttachment throws if user is not signed in', () async {
      when(() => authDataSource.currentUser).thenReturn(null);

      expect(
        () => repository.addAttachment(
          target: storyTarget,
          fileName: 'file.pdf',
          fileSize: 100,
          fileType: 'pdf',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('đăng nhập'),
        )),
      );
    });

    test('addAttachment throws if fileName is empty', () async {
      expect(
        () => repository.addAttachment(
          target: storyTarget,
          fileName: '   ',
          fileSize: 100,
          fileType: 'pdf',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('trống'),
        )),
      );
    });

    test('addAttachment throws if user is not project member', () async {
      givenMembership(false);

      expect(
        () => repository.addAttachment(
          target: storyTarget,
          fileName: 'file.pdf',
          fileSize: 100,
          fileType: 'pdf',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('thành viên của dự án'),
        )),
      );
    });

    test('addAttachment succeeds for story target', () async {
      givenMembership(true);

      final createdAttachment = AttachmentModel(
        id: 'doc1',
        projectId: projectId,
        storyId: 's1',
        fileName: 'design.png',
        fileSize: 2048,
        fileType: 'png',
        uploadedById: uid,
        uploadedByName: 'Duy FullName',
        createdAt: now,
      );

      when(() => dataSource.addAttachment(storyTarget, any()))
          .thenAnswer((_) async => createdAttachment);

      final result = await repository.addAttachment(
        target: storyTarget,
        fileName: 'design.png',
        fileSize: 2048,
        fileType: 'png',
      );

      expect(result.id, 'doc1');
      expect(result.fileName, 'design.png');
      expect(result.uploadedByName, 'Duy FullName');
      verify(() => dataSource.addAttachment(storyTarget, any())).called(1);
    });

    test('addAttachment succeeds for task target with link', () async {
      givenMembership(true);

      final createdAttachment = AttachmentModel(
        id: 'doc2',
        projectId: projectId,
        taskId: 't1',
        fileName: 'Figma URL',
        fileSize: 0,
        fileType: 'link',
        fileUrl: 'https://figma.com/file/123',
        isLink: true,
        uploadedById: uid,
        uploadedByName: 'Duy FullName',
        createdAt: now,
      );

      when(() => dataSource.addAttachment(taskTarget, any()))
          .thenAnswer((_) async => createdAttachment);

      final result = await repository.addAttachment(
        target: taskTarget,
        fileName: 'Figma URL',
        fileSize: 0,
        fileType: 'link',
        fileUrl: 'https://figma.com/file/123',
        isLink: true,
      );

      expect(result.id, 'doc2');
      expect(result.isLink, isTrue);
      expect(result.fileUrl, 'https://figma.com/file/123');
      verify(() => dataSource.addAttachment(taskTarget, any())).called(1);
    });

    test('deleteAttachment succeeds when user is project member', () async {
      givenMembership(true);
      when(() => dataSource.deleteAttachment(storyTarget, 'att1'))
          .thenAnswer((_) async {});

      await repository.deleteAttachment(
        target: storyTarget,
        attachmentId: 'att1',
      );

      verify(() => dataSource.deleteAttachment(storyTarget, 'att1')).called(1);
    });
  });
}
