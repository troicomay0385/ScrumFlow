import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/app/errors/app_failure.dart';
import 'package:scrumflow/data/models/task_model.dart';
import 'package:scrumflow/data/models/work_log_model.dart';
import 'package:scrumflow/data/repositories/work_log_repository.dart';
import 'package:scrumflow/presentation/tasks/bloc/work_logs_cubit.dart';
import 'package:scrumflow/presentation/tasks/bloc/work_logs_state.dart';
import 'package:scrumflow/presentation/tasks/screens/task_board_screen.dart';
import 'package:scrumflow/presentation/tasks/widgets/work_logs_section.dart';

class MockWorkLogRepository extends Mock implements WorkLogRepository {}

class MockWorkLogsCubit extends Mock implements WorkLogsCubit {}

void main() {
  const projectId = 'proj-abc';
  final now = DateTime.now();

  final testTask = TaskModel(
    id: 'task-123',
    storyId: 'story-1',
    projectId: projectId,
    title: 'Giao diện Work Logs',
    description: 'Mô tả task',
    status: 'In Progress',
    loggedHours: 3.5,
    createdAt: now,
    updatedAt: now,
  );

  final testLogs = [
    WorkLogModel(
      id: 'log-1',
      taskId: testTask.id,
      projectId: projectId,
      userId: 'user-1',
      userName: 'Trần Thúy',
      hours: 2.0,
      note: 'Viết unit tests',
      workDate: DateTime(2026, 10, 16),
      createdAt: now.subtract(const Duration(minutes: 30)),
    ),
    WorkLogModel(
      id: 'log-2',
      taskId: testTask.id,
      projectId: projectId,
      userId: 'user-2',
      userName: 'Lê Phúc',
      hours: 1.5,
      note: '',
      workDate: DateTime(2026, 10, 17),
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
  ];

  late MockWorkLogsCubit cubit;

  setUp(() {
    cubit = MockWorkLogsCubit();
  });

  Widget buildSectionApp({
    required WorkLogsState state,
    double width = 400,
    double height = 800,
    ThemeData? theme,
  }) {
    when(() => cubit.state).thenReturn(state);
    when(() => cubit.stream).thenAnswer((_) => Stream.value(state));

    return MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: height,
          child: SingleChildScrollView(
            child: WorkLogsSection(
              task: testTask,
              projectId: projectId,
              cubit: cubit,
            ),
          ),
        ),
      ),
    );
  }

  group('WorkLogsSection', () {
    testWidgets('hiển thị empty message khi không có log', (tester) async {
      await tester.pumpWidget(buildSectionApp(
        state: const WorkLogsState(
          status: WorkLogsStatus.empty,
          taskId: 'task-123',
          workLogs: [],
        ),
      ));

      expect(find.text('Giờ làm việc'), findsOneWidget);
      expect(find.text('Chưa có giờ làm việc nào'), findsOneWidget);
      expect(find.byKey(const Key('work_logs_add_button')), findsOneWidget);
    });

    testWidgets('hiển thị loaded danh sách logs và tổng giờ', (tester) async {
      await tester.pumpWidget(buildSectionApp(
        state: WorkLogsState(
          status: WorkLogsStatus.loaded,
          taskId: testTask.id,
          workLogs: testLogs,
        ),
      ));

      expect(find.text('Giờ làm việc'), findsOneWidget);
      expect(find.text('Tổng: 3.5 giờ'), findsOneWidget);

      // Log 1
      expect(find.text('Trần Thúy'), findsOneWidget);
      expect(find.text('2 giờ'), findsOneWidget);
      expect(find.text('16/10/2026'), findsOneWidget);
      expect(find.text('Viết unit tests'), findsOneWidget);
      expect(find.text('30 phút trước'), findsOneWidget);

      // Log 2
      expect(find.text('Lê Phúc'), findsOneWidget);
      expect(find.text('1.5 giờ'), findsOneWidget);
      expect(find.text('17/10/2026'), findsOneWidget);
    });

    testWidgets('hiển thị error và bấm Thử lại gọi cubit.retry()',
        (tester) async {
      when(() => cubit.retry()).thenAnswer((_) async {});

      await tester.pumpWidget(buildSectionApp(
        state: const WorkLogsState(
          status: WorkLogsStatus.error,
          taskId: 'task-123',
          failure: AppFailure.noConnection(),
        ),
      ));

      expect(find.textContaining('Không có kết nối mạng'), findsOneWidget);
      final retryBtn = find.byKey(const Key('work_logs_retry_button'));
      expect(retryBtn, findsOneWidget);

      await tester.tap(retryBtn);
      await tester.pump();

      verify(() => cubit.retry()).called(1);
    });

    testWidgets('không tràn layout ở chiều rộng hẹp 320px', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(buildSectionApp(
        state: WorkLogsState(
          status: WorkLogsStatus.loaded,
          taskId: testTask.id,
          workLogs: testLogs,
        ),
        width: 320,
        height: 568,
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Giờ làm việc'), findsOneWidget);
    });

    testWidgets('hiển thị tốt ở dark mode', (tester) async {
      await tester.pumpWidget(buildSectionApp(
        state: WorkLogsState(
          status: WorkLogsStatus.loaded,
          taskId: testTask.id,
          workLogs: testLogs,
        ),
        theme: ThemeData.dark(),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Giờ làm việc'), findsOneWidget);
      expect(find.text('Trần Thúy'), findsOneWidget);
    });
  });

  group('TaskCard loggedHours chip', () {
    testWidgets(
        'hiển thị chip giờ làm việc khi task.loggedHours > 0 và không làm tràn ở cột hẹp 100px',
        (tester) async {
      final taskWithHours = TaskModel(
        id: 't-1',
        storyId: 's-1',
        projectId: projectId,
        title: 'Task có giờ làm việc rất dài để kiểm tra tràn chữ',
        description: 'Mô tả',
        status: 'To Do',
        loggedHours: 4.5,
        createdAt: now,
        updatedAt: now,
      );

      final taskWithoutHours = TaskModel(
        id: 't-2',
        storyId: 's-1',
        projectId: projectId,
        title: 'Task không có giờ',
        description: 'Mô tả',
        status: 'To Do',
        loggedHours: 0.0,
        createdAt: now,
        updatedAt: now,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 100, // Cột hẹp ~100px
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TaskCard(task: taskWithHours),
                    const SizedBox(height: 10),
                    TaskCard(task: taskWithoutHours),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      // Thẻ 1 có chip với 4.5h
      expect(
          find.byKey(const Key('task_logged_hours_chip_t-1')), findsOneWidget);
      expect(find.text('4.5h'), findsOneWidget);

      // Thẻ 2 không có chip
      expect(
          find.byKey(const Key('task_logged_hours_chip_t-2')), findsNothing);
    });
  });
}
