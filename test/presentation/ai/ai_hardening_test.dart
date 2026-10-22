import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/app/theme/app_theme.dart';
import 'package:scrumflow/data/ai/ai_model_store.dart';
import 'package:scrumflow/data/ai/risk_prediction_service.dart';
import 'package:scrumflow/data/ai/sprint_forecast_service.dart';
import 'package:scrumflow/data/models/project_member_display.dart';
import 'package:scrumflow/data/models/project_member_model.dart';
import 'package:scrumflow/data/models/sprint_model.dart';
import 'package:scrumflow/data/models/task_model.dart';
import 'package:scrumflow/data/models/user_model.dart';
import 'package:scrumflow/data/models/user_story_model.dart';
import 'package:scrumflow/data/repositories/backlog_repository.dart';
import 'package:scrumflow/data/repositories/task_repository.dart';
import 'package:scrumflow/presentation/ai/bloc/model_lab_cubit.dart';
import 'package:scrumflow/presentation/ai/bloc/sprint_forecast_cubit.dart';
import 'package:scrumflow/presentation/ai/bloc/sprint_forecast_state.dart';
import 'package:scrumflow/presentation/ai/bloc/sprint_risk_cubit.dart';
import 'package:scrumflow/presentation/ai/bloc/task_risk_cubit.dart';
import 'package:scrumflow/presentation/ai/screens/model_lab_screen.dart';
import 'package:scrumflow/presentation/ai/widgets/sprint_forecast_card.dart';
import 'package:scrumflow/presentation/ai/widgets/sprint_high_risk_tasks_card.dart';
import 'package:scrumflow/presentation/ai/widgets/task_risk_radar_card.dart';
import 'package:scrumflow/presentation/ai/widgets/task_what_if_bottom_sheet.dart';
import 'package:scrumflow/presentation/sprints/widgets/burndown_chart_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OfflineFailingTaskRepo extends Mock implements TaskRepository {}

class _OfflineFailingBacklogRepo extends Mock implements BacklogRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 10, 22, 10, 0);

  late RiskPredictionService sharedPredictionService;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    sharedPredictionService = RiskPredictionService(
      modelStore: AiModelStore(),
      useIsolateForTraining: false,
    );
    await sharedPredictionService.ensureModelLoaded('proj_hardening');
  });

  TaskModel makeRiskyTask() {
    return TaskModel(
      id: 't_risky',
      storyId: 's_1',
      projectId: 'proj_hardening',
      title:
          'Triển khai mô hình Logistic Regression 10 đặc trưng với tên rất dài để kiểm thử chống tràn giao diện trên màn hình nhỏ 320px',
      description: 'Mô tả chi tiết kiểm thử khả năng co giãn của giao diện.',
      status: 'To Do',
      assigneeId: 'u_1',
      assigneeName: 'Nguyễn Văn Kiểm Thử Giao Diện Dài',
      deadline: now.add(const Duration(hours: 12)),
      loggedHours: 0.0,
      createdAt: now.subtract(const Duration(days: 6)),
      updatedAt: now,
    );
  }

  SprintModel makeSprint() {
    return SprintModel(
      id: 'sp_hardening',
      projectId: 'proj_hardening',
      name: 'Sprint 5 — AI Risk Radar & Forecast',
      goal: 'Đảm bảo không tràn layout ở mọi kích thước màn hình',
      storyIds: const ['s_1', 's_2'],
      startDate: now.subtract(const Duration(days: 5)),
      endDate: now.add(const Duration(days: 9)),
      status: 'Active',
      createdAt: now.subtract(const Duration(days: 5)),
      updatedAt: now,
    );
  }

  List<UserStoryModel> makeStories() {
    return [
      UserStoryModel(
        id: 's_1',
        projectId: 'proj_hardening',
        storyKey: 'US-069',
        title:
            'Dự đoán rủi ro trễ hạn Task bằng Logistic Regression kèm giải thích Top-3 đóng góp đặc trưng',
        description: 'Desc',
        priority: 'CAO',
        storyPoints: 8,
        status: 'In Progress',
        tags: const ['AI', 'Blocked'],
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
      ),
      UserStoryModel(
        id: 's_2',
        projectId: 'proj_hardening',
        storyKey: 'US-070',
        title: 'Dự báo tiến độ hoàn thành Sprint bằng mô phỏng Monte Carlo',
        description: 'Desc',
        priority: 'TB',
        storyPoints: 5,
        status: 'To Do',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
      ),
    ];
  }

  List<ProjectMemberDisplay> makeMembers() {
    return [
      ProjectMemberDisplay(
        membership: ProjectMemberModel(
          id: 'm1',
          projectId: 'proj_hardening',
          userId: 'u_1',
          role: ProjectRole.member,
          createdBy: 'u_0',
          createdAt: now,
          updatedAt: now,
        ),
        user: UserModel(
          id: 'u_1',
          email: 'u1@scrumflow.dev',
          fullName: 'Nguyễn Văn Kiểm Thử Giao Diện Dài',
          loginProvider: 'email',
          createdAt: now,
        ),
      ),
      ProjectMemberDisplay(
        membership: ProjectMemberModel(
          id: 'm2',
          projectId: 'proj_hardening',
          userId: 'u_2',
          role: ProjectRole.po,
          createdBy: 'u_0',
          createdAt: now,
          updatedAt: now,
        ),
        user: UserModel(
          id: 'u_2',
          email: 'po@scrumflow.dev',
          fullName: 'Lê Phúc (PO)',
          loginProvider: 'email',
          createdAt: now,
        ),
      ),
    ];
  }

  Future<void> pumpInViewport(
    WidgetTester tester, {
    required Size size,
    required double textScale,
    required ThemeData theme,
    required Widget child,
    double bottomInset = 0.0,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        builder: (context, appChild) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              size: size,
              textScaler: TextScaler.linear(textScale),
              viewInsets: EdgeInsets.only(bottom: bottomInset),
            ),
            child: appChild!,
          );
        },
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Phase 5.1 — Responsive, TextScale, Keyboard & Dark Mode Hardening', () {
    final viewports = <Size>[
      const Size(320, 568), // Màn hình nhỏ (iPhone SE)
      const Size(430, 932), // Màn hình lớn
    ];
    final textScales = <double>[1.0, 1.3];
    final darkModes = <bool>[false, true];

    for (final size in viewports) {
      for (final scale in textScales) {
        for (final isDark in darkModes) {
          final themeLabel = isDark ? 'Dark' : 'Light';
          testWidgets(
            'AI Cards & BottomSheets render without overflow at ${size.width.toInt()}x${size.height.toInt()}, scale=$scale, theme=$themeLabel',
            (tester) async {
              final themeData = isDark
                  ? AppTheme.darkTheme
                  : AppTheme.lightTheme;
              final task = makeRiskyTask();
              final sprint = makeSprint();
              final stories = makeStories();
              final members = makeMembers();

              final taskRiskCubit = TaskRiskCubit(
                projectId: 'proj_hardening',
                predictionService: sharedPredictionService,
                nowProvider: () => now,
              );
              await taskRiskCubit.evaluateTask(
                task: task,
                story: stories.first,
                sprint: sprint,
                allProjectTasks: [task],
                members: members,
              );

              final sprintRiskCubit = SprintRiskCubit(
                projectId: 'proj_hardening',
                predictionService: sharedPredictionService,
                nowProvider: () => now,
              );
              await sprintRiskCubit.evaluateTasksList(
                tasks: [task],
                storiesById: {for (final s in stories) s.id: s},
                sprintsByStoryId: {for (final s in stories) s.id: sprint},
                members: members,
              );

              final forecastCubit = SprintForecastCubit(
                projectId: 'proj_hardening',
              );
              await forecastCubit.computeForecast(
                sprint: sprint,
                sprintStories: stories,
                allSprints: [sprint],
              );
              final forecast =
                  (forecastCubit.state as SprintForecastLoaded).activeForecast;

              await pumpInViewport(
                tester,
                size: size,
                textScale: scale,
                theme: themeData,
                bottomInset: 260, // Giả lập bàn phím đang mở
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: taskRiskCubit),
                    BlocProvider.value(value: sprintRiskCubit),
                    BlocProvider.value(value: forecastCubit),
                  ],
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        const TaskRiskRadarCard(),
                        const SizedBox(height: 12),
                        const TaskWhatIfBottomSheet(),
                        const SizedBox(height: 12),
                        const SprintHighRiskTasksCard(
                          projectId: 'proj_hardening',
                        ),
                        const SizedBox(height: 12),
                        BurndownChartWidget(
                          sprint: sprint,
                          stories: stories,
                          forecast: forecast,
                        ),
                        const SizedBox(height: 12),
                        const SprintForecastCard(),
                        const SizedBox(height: 12),
                        const Material(child: SprintWhatIfBottomSheet()),
                      ],
                    ),
                  ),
                ),
              );

              expect(tester.takeException(), isNull);
              expect(
                find.byKey(const Key('task_risk_radar_card')),
                findsOneWidget,
              );
              expect(
                find.byKey(const Key('sprint_high_risk_tasks_card')),
                findsOneWidget,
              );
              expect(
                find.byKey(const Key('sprintForecastCard')),
                findsOneWidget,
              );

              await taskRiskCubit.close();
              await sprintRiskCubit.close();
              await forecastCubit.close();
            },
          );
        }
      }
    }

    testWidgets(
      'ModelLabScreen renders cleanly at 320x568 with textScale=1.3 in Dark Mode',
      (tester) async {
        final modelLabCubit = ModelLabCubit(
          projectId: 'proj_hardening',
          predictionService: sharedPredictionService,
        );
        await modelLabCubit.loadModelInfo(preloadedTasks: [makeRiskyTask()]);

        await pumpInViewport(
          tester,
          size: const Size(320, 568),
          textScale: 1.3,
          theme: AppTheme.darkTheme,
          child: BlocProvider.value(
            value: modelLabCubit,
            child: ModelLabScreen(
              projectId: 'proj_hardening',
              predictionService: sharedPredictionService,
              preloadedTasks: [makeRiskyTask()],
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.textContaining('AI Model Lab'), findsOneWidget);

        await modelLabCubit.close();
      },
    );
  });

  group('Phase 5.2 — Offline Resilience Verification', () {
    test(
      'RiskPredictionService, SprintForecastCubit & ModelLabCubit work 100% offline when repositories throw network errors',
      () async {
        final failingTaskRepo = _OfflineFailingTaskRepo();
        final failingBacklogRepo = _OfflineFailingBacklogRepo();

        when(
          () => failingTaskRepo.getTasksByProject(any()),
        ).thenThrow(Exception('SocketException: No Internet connection'));
        when(
          () => failingBacklogRepo.getUserStories(any()),
        ).thenThrow(Exception('SocketException: No Internet connection'));

        // 1. RiskPredictionService suy luận từ model lưu cục bộ trong SharedPreferences
        final task = makeRiskyTask();
        final prediction = await sharedPredictionService.predictTaskRisk(
          projectId: 'proj_hardening',
          task: task,
          story: makeStories().first,
          sprint: makeSprint(),
          allProjectTasks: [task],
          members: makeMembers(),
          now: now,
        );
        expect(prediction.isPredictable, isTrue);
        expect(prediction.probability, inInclusiveRange(0.0, 1.0));
        expect(prediction.topReasons, isNotEmpty);

        // 2. SprintForecastCubit vẫn chạy thành công khi BacklogRepository ném lỗi mạng
        final forecastCubit = SprintForecastCubit(
          projectId: 'proj_hardening',
          backlogRepository: failingBacklogRepo,
        );
        await forecastCubit.computeForecast(
          sprint: makeSprint(),
          sprintStories: makeStories(),
          allSprints: [makeSprint()],
        );
        expect(forecastCubit.state, isA<SprintForecastLoaded>());
        await forecastCubit.close();

        // 3. ModelLabCubit vẫn tải và huấn luyện lại thành công khi TaskRepository mất mạng
        final labCubit = ModelLabCubit(
          projectId: 'proj_hardening',
          predictionService: sharedPredictionService,
          taskRepository: failingTaskRepo,
          backlogRepository: failingBacklogRepo,
        );
        await labCubit.loadModelInfo();
        expect(labCubit.state.artifact, isNotNull);
        await labCubit.retrainWithProjectData(epochs: 20, syntheticCount: 150);
        expect(labCubit.state.artifact, isNotNull);
        await labCubit.close();
      },
    );
  });

  group(
    'Phase 5.3 — Performance Benchmarks (< 5ms inference, < 300ms Monte Carlo)',
    () {
      test(
        'Single-task risk inference < 5 ms and 1000-run Monte Carlo < 300 ms',
        () async {
          final task = makeRiskyTask();
          final story = makeStories().first;
          final sprint = makeSprint();
          final members = makeMembers();

          // Warm-up model in memory
          await sharedPredictionService.ensureModelLoaded('proj_hardening');

          const runs = 50;
          final swInference = Stopwatch()..start();
          for (int i = 0; i < runs; i++) {
            await sharedPredictionService.predictTaskRisk(
              projectId: 'proj_hardening',
              task: task,
              story: story,
              sprint: sprint,
              allProjectTasks: [task],
              members: members,
              now: now,
            );
          }
          swInference.stop();
          final avgInferenceMs =
              swInference.elapsedMicroseconds / 1000.0 / runs;

          const forecastService = SprintForecastService();
          final swMonteCarlo = Stopwatch()..start();
          final fcResult = forecastService.forecastSprint(
            sprint: sprint,
            sprintStories: makeStories(),
            allSprints: [sprint],
            numSimulations: 1000,
            now: now,
          );
          swMonteCarlo.stop();
          final monteCarloMs = swMonteCarlo.elapsedMicroseconds / 1000.0;

          // Ghi log số đo thực tế để đưa vào báo cáo
          // ignore: avoid_print
          print(
            '[BENCHMARK] Single-task inference avg: ${avgInferenceMs.toStringAsFixed(3)} ms (target < 5 ms) | 1000-run Monte Carlo: ${monteCarloMs.toStringAsFixed(2)} ms (target < 300 ms)',
          );

          expect(avgInferenceMs, lessThan(5.0));
          expect(monteCarloMs, lessThan(300.0));
          expect(fcResult.simulationsRun, 1000);
        },
      );
    },
  );
}
