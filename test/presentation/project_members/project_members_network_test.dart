// US-063 — Quản lý thành viên: lỗi mạng/timeout có "Thử lại", lỗi
// "không phải thành viên" thì không; thử lại không tạo listener trùng.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/app/errors/app_failure.dart';
import 'package:scrumflow/data/repositories/project_member_repository.dart';
import 'package:scrumflow/presentation/project_members/bloc/project_members_bloc.dart';
import 'package:scrumflow/presentation/project_members/bloc/project_members_event.dart';
import 'package:scrumflow/presentation/project_members/bloc/project_members_state.dart';

class _MockProjectMemberRepository extends Mock
    implements ProjectMemberRepository {}

void main() {
  const projectId = 'p1';
  late _MockProjectMemberRepository repository;

  setUp(() => repository = _MockProjectMemberRepository());

  blocTest<ProjectMembersBloc, ProjectMembersState>(
    'lỗi mạng khi đọc role → ProjectMembersError có thể thử lại',
    setUp: () =>
        when(() => repository.streamCurrentUserRole(projectId)).thenAnswer(
          (_) => Stream.error(
            FirebaseException(
              plugin: 'cloud_firestore',
              code: 'unavailable',
              message: 'The client is offline',
            ),
          ),
        ),
    build: () => ProjectMembersBloc(repository),
    act: (bloc) => bloc.add(const ProjectMembersStarted(projectId)),
    expect: () => [
      isA<ProjectMembersLoading>(),
      isA<ProjectMembersError>()
          .having((s) => s.failureType, 'type', AppFailureType.noConnection)
          .having((s) => s.failure.isRetryable, 'retryable', isTrue),
    ],
  );

  blocTest<ProjectMembersBloc, ProjectMembersState>(
    'không nhận được role trong thời hạn → lỗi timeout',
    setUp: () => when(
      () => repository.streamCurrentUserRole(projectId),
    ).thenAnswer((_) => StreamController<ProjectRole?>().stream),
    build: () => ProjectMembersBloc(
      repository,
      firstLoadTimeout: const Duration(milliseconds: 30),
    ),
    act: (bloc) => bloc.add(const ProjectMembersStarted(projectId)),
    wait: const Duration(milliseconds: 100),
    expect: () => [
      isA<ProjectMembersLoading>(),
      isA<ProjectMembersError>().having(
        (s) => s.failureType,
        'type',
        AppFailureType.timeout,
      ),
    ],
  );

  blocTest<ProjectMembersBloc, ProjectMembersState>(
    'không phải thành viên → lỗi quyền, KHÔNG cho thử lại',
    setUp: () => when(
      () => repository.streamCurrentUserRole(projectId),
    ).thenAnswer((_) => Stream.value(null)),
    build: () => ProjectMembersBloc(repository),
    act: (bloc) => bloc.add(const ProjectMembersStarted(projectId)),
    expect: () => [
      isA<ProjectMembersLoading>(),
      isA<ProjectMembersError>()
          .having((s) => s.failureType, 'type', AppFailureType.permission)
          .having((s) => s.failure.isRetryable, 'retryable', isFalse),
    ],
  );

  test('thử lại → huỷ listener role cũ trước khi mở listener mới', () async {
    var active = 0;
    when(() => repository.streamCurrentUserRole(projectId)).thenAnswer((_) {
      return StreamController<ProjectRole?>(
        onListen: () => active++,
        onCancel: () => active--,
      ).stream;
    });
    final bloc = ProjectMembersBloc(repository);

    bloc.add(const ProjectMembersStarted(projectId));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    bloc.add(const ProjectMembersStarted(projectId));
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(active, 1);
    await bloc.close();
    expect(active, 0);
  });
}
