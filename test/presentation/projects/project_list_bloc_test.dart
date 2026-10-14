// US-063 — Tải danh sách project: mất mạng, timeout, lỗi máy chủ, thử lại
// và chống request trùng lặp.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/app/errors/app_failure.dart';
import 'package:scrumflow/app/services/connectivity_service.dart';
import 'package:scrumflow/data/models/project_model.dart';
import 'package:scrumflow/data/models/project_summary.dart';
import 'package:scrumflow/data/repositories/project_repository.dart';
import 'package:scrumflow/presentation/projects/bloc/project_list_bloc.dart';
import 'package:scrumflow/presentation/projects/bloc/project_list_event.dart';
import 'package:scrumflow/presentation/projects/bloc/project_list_state.dart';

class _MockProjectRepository extends Mock implements ProjectRepository {}

class _MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late _MockProjectRepository repository;
  late _MockConnectivityService connectivity;

  final summary = ProjectSummary(
    project: ProjectModel(
      id: 'p1',
      name: 'ScrumFlow',
      description: 'Mục tiêu',
      createdBy: 'u1',
      createdAt: DateTime(2026, 10, 1),
      updatedAt: DateTime(2026, 10, 1),
    ),
    myRole: ProjectRole.po,
  );

  setUp(() {
    repository = _MockProjectRepository();
    connectivity = _MockConnectivityService();
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
  });

  blocTest<ProjectListBloc, ProjectListState>(
    'có mạng + tải thành công → Loading rồi Loaded',
    setUp: () => when(
      () => repository.getMyProjects(),
    ).thenAnswer((_) async => [summary]),
    build: () => ProjectListBloc(repository, connectivityService: connectivity),
    act: (bloc) => bloc.add(ProjectListRequested()),
    expect: () => [
      isA<ProjectListLoading>(),
      isA<ProjectListLoaded>().having((s) => s.projects, 'projects', [summary]),
    ],
  );

  blocTest<ProjectListBloc, ProjectListState>(
    'không có mạng → báo lỗi noConnection, KHÔNG gọi Firestore',
    setUp: () =>
        when(() => connectivity.isOnline()).thenAnswer((_) async => false),
    build: () => ProjectListBloc(repository, connectivityService: connectivity),
    act: (bloc) => bloc.add(ProjectListRequested()),
    expect: () => [
      isA<ProjectListLoading>(),
      isA<ProjectListError>()
          .having((s) => s.failureType, 'type', AppFailureType.noConnection)
          .having((s) => s.failure.isRetryable, 'retryable', isTrue),
    ],
    verify: (_) => verifyNever(() => repository.getMyProjects()),
  );

  blocTest<ProjectListBloc, ProjectListState>(
    'request quá thời gian chờ → lỗi timeout, loading được kết thúc',
    setUp: () => when(
      () => repository.getMyProjects(),
    ).thenAnswer((_) => Completer<List<ProjectSummary>>().future),
    build: () => ProjectListBloc(
      repository,
      connectivityService: connectivity,
      timeout: const Duration(milliseconds: 30),
    ),
    act: (bloc) => bloc.add(ProjectListRequested()),
    wait: const Duration(milliseconds: 100),
    expect: () => [
      isA<ProjectListLoading>(),
      isA<ProjectListError>().having(
        (s) => s.failureType,
        'type',
        AppFailureType.timeout,
      ),
    ],
  );

  blocTest<ProjectListBloc, ProjectListState>(
    'lỗi máy chủ Firebase → thông báo thân thiện, không lộ mã kỹ thuật',
    setUp: () => when(
      () => repository.getMyProjects(),
    ).thenThrow(FirebaseException(plugin: 'cloud_firestore', code: 'internal')),
    build: () => ProjectListBloc(repository, connectivityService: connectivity),
    act: (bloc) => bloc.add(ProjectListRequested()),
    expect: () => [
      isA<ProjectListLoading>(),
      isA<ProjectListError>()
          .having((s) => s.failureType, 'type', AppFailureType.server)
          .having(
            (s) => s.message,
            'message',
            isNot(contains('cloud_firestore')),
          ),
    ],
  );

  test('thử lại sau khi mạng hồi phục → tải thành công', () async {
    var online = false;
    when(() => connectivity.isOnline()).thenAnswer((_) async => online);
    when(() => repository.getMyProjects()).thenAnswer((_) async => [summary]);
    final bloc = ProjectListBloc(repository, connectivityService: connectivity);

    bloc.add(ProjectListRequested());
    await expectLater(bloc.stream, emitsThrough(isA<ProjectListError>()));

    online = true;
    bloc.add(ProjectListRequested());
    await expectLater(bloc.stream, emitsThrough(isA<ProjectListLoaded>()));
    await bloc.close();
  });

  test('bấm thử lại liên tục khi đang tải → chỉ 1 request', () async {
    final completer = Completer<List<ProjectSummary>>();
    when(() => repository.getMyProjects()).thenAnswer((_) => completer.future);
    final bloc = ProjectListBloc(repository, connectivityService: connectivity);

    bloc.add(ProjectListRequested());
    await Future<void>.delayed(Duration.zero);
    bloc
      ..add(ProjectListRequested())
      ..add(ProjectListRequested());
    await Future<void>.delayed(Duration.zero);
    completer.complete([summary]);
    await expectLater(bloc.stream, emitsThrough(isA<ProjectListLoaded>()));

    verify(() => repository.getMyProjects()).called(1);
    await bloc.close();
  });
}
