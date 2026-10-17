import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/app/errors/app_failure.dart';
import 'package:scrumflow/app/services/connectivity_service.dart';
import 'package:scrumflow/data/models/project_model.dart';
import 'package:scrumflow/data/models/project_summary.dart';
import 'package:scrumflow/data/models/sprint_model.dart';
import 'package:scrumflow/data/models/sprint_progress.dart';
import 'package:scrumflow/presentation/dashboard/bloc/sprint_dashboard_cubit.dart';
import 'package:scrumflow/presentation/dashboard/bloc/sprint_dashboard_state.dart';
import 'package:scrumflow/presentation/dashboard/widgets/doughnut_chart.dart';
import 'package:scrumflow/presentation/dashboard/widgets/sprint_dashboard_card.dart';

import '../../helpers/test_setup.dart';

class FakeSprintDashboardCubit extends Cubit<SprintDashboardState>
    implements SprintDashboardCubit {
  FakeSprintDashboardCubit(super.initialState);

  int loadCalls = 0;
  String? lastLoadedProjectId;
  int retryCalls = 0;

  @override
  Duration get firstLoadTimeout => const Duration(seconds: 15);

  @override
  ConnectivityService? get connectivity => null;

  @override
  Future<void> load(String projectId) async {
    loadCalls++;
    lastLoadedProjectId = projectId;
  }

  @override
  void retry() {
    retryCalls++;
  }

  void emitState(SprintDashboardState state) => emit(state);
}

final _now = DateTime.now();

final _project1 = ProjectModel(
  id: 'p1',
  name: 'Dự án Alpha',
  description: 'Mô tả dự án Alpha',
  createdBy: 'u1',
  createdAt: _now,
  updatedAt: _now,
);

final _project2 = ProjectModel(
  id: 'p2',
  name: 'Dự án Beta',
  description: 'Mô tả dự án Beta',
  createdBy: 'u1',
  createdAt: _now,
  updatedAt: _now,
);

final _summary1 = ProjectSummary(project: _project1, myRole: ProjectRole.po);
final _summary2 = ProjectSummary(project: _project2, myRole: ProjectRole.sm);

final _activeSprint = SprintModel(
  id: 'sp1',
  projectId: 'p1',
  name: 'Sprint 1 - Tính năng Core',
  goal: 'Hoàn thành MVP cho Sprint 1',
  storyIds: const ['s1', 's2'],
  startDate: _now.subtract(const Duration(days: 3)),
  endDate: _now.add(const Duration(days: 7)),
  status: 'Active',
  createdAt: _now,
  updatedAt: _now,
);

Future<void> _setScreen(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Widget _app(Widget child, {double textScale = 1.0, ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? ThemeData.light(),
    home: Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: child,
        ),
      ),
    ),
    builder: (context, c) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: c!,
    ),
  );
}

void main() {
  setUpWidgetTestEnvironment();

  group('DoughnutChart Widget Tests', () {
    testWidgets('không crash khi total == 0 và hiển thị Semantics đúng',
        (tester) async {
      await tester.pumpWidget(
        _app(const DoughnutChart(
          todo: 0,
          inProgress: 0,
          done: 0,
          centerTitle: '0%',
          centerSubtitle: '0/0 task',
        )),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(DoughnutChart), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('0/0 task'), findsOneWidget);

      final semantics = tester.getSemantics(find.byType(DoughnutChart));
      expect(
        semantics.label,
        contains('Sprint: 0% hoàn thành, 0 To Do, 0 In Progress, 0 Done'),
      );
    });

    testWidgets('Semantics label tính đúng phần trăm khi có dữ liệu',
        (tester) async {
      await tester.pumpWidget(
        _app(const DoughnutChart(
          todo: 1,
          inProgress: 1,
          done: 2,
          centerTitle: '50%',
          centerSubtitle: '2/4 task',
        )),
      );
      await tester.pumpAndSettle();

      final semantics = tester.getSemantics(find.byType(DoughnutChart));
      expect(
        semantics.label,
        contains('Sprint: 50% hoàn thành, 1 To Do, 1 In Progress, 2 Done'),
      );
    });
  });

  group('SprintDashboardCard Widget Tests', () {
    testWidgets('State loading hiển thị skeleton gọn và không overflow',
        (tester) async {
      final fakeCubit = FakeSprintDashboardCubit(
        const SprintDashboardState(
          status: SprintDashboardStatus.loading,
          projectId: 'p1',
        ),
      );

      await tester.pumpWidget(
        _app(SprintDashboardCard(
          projects: [_summary1],
          cubit: fakeCubit,
        )),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(SprintDashboardCard), findsOneWidget);
      expect(find.text('Tiến độ Sprint'), findsOneWidget);
    });

    testWidgets('State noSprint hiển thị thông báo chưa có Sprint đang chạy',
        (tester) async {
      final fakeCubit = FakeSprintDashboardCubit(
        const SprintDashboardState(
          status: SprintDashboardStatus.noSprint,
          projectId: 'p1',
        ),
      );

      await tester.pumpWidget(
        _app(SprintDashboardCard(
          projects: [_summary1],
          cubit: fakeCubit,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chưa có Sprint đang chạy'), findsOneWidget);
    });

    testWidgets('State error hiển thị AppErrorView và nút thử lại hoạt động',
        (tester) async {
      final fakeCubit = FakeSprintDashboardCubit(
        const SprintDashboardState(
          status: SprintDashboardStatus.error,
          projectId: 'p1',
          failure: AppFailure.noConnection(),
        ),
      );

      await tester.pumpWidget(
        _app(SprintDashboardCard(
          projects: [_summary1],
          cubit: fakeCubit,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mất kết nối mạng'), findsOneWidget);
      expect(find.text('Thử lại'), findsOneWidget);

      await tester.tap(find.text('Thử lại'));
      await tester.pump();

      expect(fakeCubit.retryCalls, 1);
    });

    testWidgets('State loaded hiển thị đúng Doughnut, tiến độ, chú giải và chạm gọi navigation',
        (tester) async {
      final progress = const SprintProgress(
        todo: 1,
        inProgress: 1,
        done: 2,
      );

      final fakeCubit = FakeSprintDashboardCubit(
        SprintDashboardState(
          status: SprintDashboardStatus.loaded,
          projectId: 'p1',
          sprint: _activeSprint,
          progress: progress,
        ),
      );

      bool didTap = false;
      SprintModel? tappedSprint;

      await tester.pumpWidget(
        _app(SprintDashboardCard(
          projects: [_summary1],
          cubit: fakeCubit,
          onSprintTap: (sprint) {
            didTap = true;
            tappedSprint = sprint;
          },
        )),
      );
      await tester.pumpAndSettle();

      // Header
      expect(find.text('Sprint 1 - Tính năng Core'), findsOneWidget);
      expect(find.text('Còn 7 ngày'), findsOneWidget);

      // Doughnut text
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('2/4 task'), findsOneWidget);

      // Legends
      expect(find.text('Done'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('To Do'), findsOneWidget);

      // Tap card
      await tester.tap(find.byType(SprintDashboardCard));
      await tester.pump();

      expect(didTap, isTrue);
      expect(tappedSprint?.id, 'sp1');
    });

    testWidgets('State loaded với 0 task hiển thị dòng "Sprint chưa có task"',
        (tester) async {
      final fakeCubit = FakeSprintDashboardCubit(
        SprintDashboardState(
          status: SprintDashboardStatus.loaded,
          projectId: 'p1',
          sprint: _activeSprint,
          progress: const SprintProgress(todo: 0, inProgress: 0, done: 0),
        ),
      );

      await tester.pumpWidget(
        _app(SprintDashboardCard(
          projects: [_summary1],
          cubit: fakeCubit,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sprint chưa có task'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('0/0 task'), findsOneWidget);
    });

    testWidgets('State loaded khi toàn Done hiển thị 100%',
        (tester) async {
      final fakeCubit = FakeSprintDashboardCubit(
        SprintDashboardState(
          status: SprintDashboardStatus.loaded,
          projectId: 'p1',
          sprint: _activeSprint,
          progress: const SprintProgress(todo: 0, inProgress: 0, done: 5),
        ),
      );

      await tester.pumpWidget(
        _app(SprintDashboardCard(
          projects: [_summary1],
          cubit: fakeCubit,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('100%'), findsOneWidget);
      expect(find.text('5/5 task'), findsOneWidget);
    });

    testWidgets('Đa dự án: hiển thị hàng chip và đổi chip gọi cubit.load',
        (tester) async {
      final fakeCubit = FakeSprintDashboardCubit(
        SprintDashboardState(
          status: SprintDashboardStatus.loaded,
          projectId: 'p1',
          sprint: _activeSprint,
          progress: const SprintProgress(todo: 1, inProgress: 0, done: 1),
        ),
      );

      await tester.pumpWidget(
        _app(SprintDashboardCard(
          projects: [_summary1, _summary2],
          cubit: fakeCubit,
        )),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dự án Alpha'), findsOneWidget);
      expect(find.text('Dự án Beta'), findsOneWidget);

      await tester.tap(find.text('Dự án Beta'));
      await tester.pump();

      expect(fakeCubit.lastLoadedProjectId, 'p2');
    });

    testWidgets('Kích thước 320x568 với textScale 1.3 không bị tràn layout',
        (tester) async {
      await _setScreen(tester, const Size(320, 568));

      final fakeCubit = FakeSprintDashboardCubit(
        SprintDashboardState(
          status: SprintDashboardStatus.loaded,
          projectId: 'p1',
          sprint: _activeSprint,
          progress: const SprintProgress(todo: 3, inProgress: 2, done: 4),
        ),
      );

      await tester.pumpWidget(
        _app(
          SprintDashboardCard(
            projects: [_summary1, _summary2],
            cubit: fakeCubit,
          ),
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Kích thước 430x932 với textScale 1.3 không bị tràn layout',
        (tester) async {
      await _setScreen(tester, const Size(430, 932));

      final fakeCubit = FakeSprintDashboardCubit(
        SprintDashboardState(
          status: SprintDashboardStatus.loaded,
          projectId: 'p1',
          sprint: _activeSprint,
          progress: const SprintProgress(todo: 3, inProgress: 2, done: 4),
        ),
      );

      await tester.pumpWidget(
        _app(
          SprintDashboardCard(
            projects: [_summary1, _summary2],
            cubit: fakeCubit,
          ),
          textScale: 1.3,
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Dark theme hiển thị chính xác không lỗi', (tester) async {
      final fakeCubit = FakeSprintDashboardCubit(
        SprintDashboardState(
          status: SprintDashboardStatus.loaded,
          projectId: 'p1',
          sprint: _activeSprint,
          progress: const SprintProgress(todo: 2, inProgress: 1, done: 3),
        ),
      );

      await tester.pumpWidget(
        _app(
          SprintDashboardCard(
            projects: [_summary1],
            cubit: fakeCubit,
          ),
          theme: ThemeData.dark(),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SprintDashboardCard), findsOneWidget);
    });
  });
}
