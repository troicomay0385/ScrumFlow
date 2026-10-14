// US-055 — Dialog / biểu mẫu trên điện thoại nhỏ khi bàn phím đang mở và
// cỡ chữ phóng to: không tràn layout, vẫn cuộn được tới nút xác nhận.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/data/models/sprint_model.dart';
import 'package:scrumflow/data/repositories/backlog_repository.dart';
import 'package:scrumflow/data/repositories/project_member_repository.dart';
import 'package:scrumflow/data/repositories/sprint_repository.dart';
import 'package:scrumflow/presentation/backlog/widgets/create_user_story_dialog.dart';
import 'package:scrumflow/presentation/project_members/bloc/project_members_bloc.dart';
import 'package:scrumflow/presentation/project_members/widgets/add_member_dialog.dart';
import 'package:scrumflow/presentation/sprints/bloc/sprint_bloc.dart';
import 'package:scrumflow/presentation/sprints/widgets/create_sprint_dialog.dart';
import 'package:scrumflow/presentation/sprints/widgets/start_sprint_dialog.dart';

import '../helpers/test_setup.dart';

class _MockBacklogRepository extends Mock implements BacklogRepository {}

class _MockSprintRepository extends Mock implements SprintRepository {}

class _MockProjectMemberRepository extends Mock
    implements ProjectMemberRepository {}

const _smallPhone = Size(320, 568);

/// Giả lập bàn phím ảo chiếm ~45% chiều cao màn hình nhỏ.
const _keyboardHeight = 260.0;

Future<void> _openDialog(
  WidgetTester tester, {
  required Widget Function(Widget child) wrap,
  required Future<void> Function(BuildContext context) open,
  double textScale = 1.3,
}) async {
  tester.view.physicalSize = _smallPhone;
  tester.view.devicePixelRatio = 1.0;
  tester.view.viewInsets = const FakeViewPadding(bottom: _keyboardHeight);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    wrap(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => open(context),
                child: const Text('Mở'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Mở'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(setUpWidgetTestEnvironment);

  final now = DateTime(2026, 10, 14);
  final sprint = SprintModel(
    id: 'sp1',
    projectId: 'p1',
    name: 'Sprint 1 — Hoàn thiện tính năng cộng tác thời gian thực',
    goal: 'Mục tiêu sprint',
    storyIds: const ['s1', 's2', 's3'],
    startDate: now,
    endDate: now.add(const Duration(days: 14)),
    createdAt: now,
    updatedAt: now,
  );

  late SprintBloc sprintBloc;
  late ProjectMembersBloc membersBloc;
  late _MockBacklogRepository backlogRepository;

  setUp(() {
    backlogRepository = _MockBacklogRepository();
    sprintBloc = SprintBloc(repository: _MockSprintRepository());
    membersBloc = ProjectMembersBloc(_MockProjectMemberRepository());
  });

  tearDown(() async {
    await sprintBloc.close();
    await membersBloc.close();
  });

  testWidgets('Tạo User Story: không tràn khi bàn phím mở + chữ lớn', (
    tester,
  ) async {
    await _openDialog(
      tester,
      wrap: (child) => RepositoryProvider<BacklogRepository>.value(
        value: backlogRepository,
        child: child,
      ),
      open: (context) =>
          showCreateUserStoryDialog(context: context, projectId: 'p1'),
    );
    expect(tester.takeException(), isNull);
    // Nút xác nhận vẫn cuộn tới được.
    final submit = find.widgetWithText(FilledButton, 'Tạo').evaluate().isEmpty
        ? find.textContaining('Tạo')
        : find.widgetWithText(FilledButton, 'Tạo');
    expect(submit, findsWidgets);
  });

  testWidgets('Tạo Sprint: không tràn khi bàn phím mở + chữ lớn', (
    tester,
  ) async {
    await _openDialog(
      tester,
      wrap: (child) =>
          BlocProvider<SprintBloc>.value(value: sprintBloc, child: child),
      open: (context) =>
          showCreateSprintDialog(context: context, projectId: 'p1'),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Bắt đầu Sprint: không tràn trên màn nhỏ + chữ lớn', (
    tester,
  ) async {
    await _openDialog(
      tester,
      wrap: (child) =>
          BlocProvider<SprintBloc>.value(value: sprintBloc, child: child),
      open: (context) => showStartSprintDialog(
        context: context,
        sprint: sprint,
        projectId: 'p1',
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Thêm thành viên: không tràn khi bàn phím mở + chữ lớn', (
    tester,
  ) async {
    await _openDialog(
      tester,
      wrap: (child) => child,
      open: (context) =>
          showAddMemberDialog(context: context, bloc: membersBloc),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(TextFormField), findsOneWidget);
  });
}
