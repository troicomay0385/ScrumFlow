import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/app/theme/app_theme.dart';
import 'package:scrumflow/data/models/project_member_display.dart';
import 'package:scrumflow/data/models/project_member_model.dart';
import 'package:scrumflow/data/models/task_model.dart';
import 'package:scrumflow/data/models/user_model.dart';
import 'package:scrumflow/presentation/ai/bloc/sprint_risk_cubit.dart';
import 'package:scrumflow/presentation/ai/bloc/sprint_risk_state.dart';
import 'package:scrumflow/presentation/ai/bloc/task_risk_cubit.dart';
import 'package:scrumflow/presentation/ai/bloc/task_risk_state.dart';
import 'package:scrumflow/presentation/ai/widgets/risk_badge.dart';
import 'package:scrumflow/presentation/ai/widgets/sprint_high_risk_tasks_card.dart';
import 'package:scrumflow/presentation/ai/widgets/task_risk_radar_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final baseNow = DateTime(2026, 10, 22, 12);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  List<ProjectMemberDisplay> buildMembers() {
    return [
      ProjectMemberDisplay(
        membership: ProjectMemberModel(
          id: 'p1_u1',
          projectId: 'p1',
          userId: 'u1',
          role: ProjectRole.member,
          createdBy: 'u0',
          createdAt: baseNow,
          updatedAt: baseNow,
        ),
        user: UserModel(
          id: 'u1',
          fullName: 'Phạm Duy',
          email: 'duy@scrumflow.com',
          loginProvider: 'email',
          createdAt: baseNow,
        ),
      ),
      ProjectMemberDisplay(
        membership: ProjectMemberModel(
          id: 'p1_u2',
          projectId: 'p1',
          userId: 'u2',
          role: ProjectRole.sm,
          createdBy: 'u0',
          createdAt: baseNow,
          updatedAt: baseNow,
        ),
        user: UserModel(
          id: 'u2',
          fullName: 'Nguyễn Hiếu',
          email: 'hieu@scrumflow.com',
          loginProvider: 'email',
          createdAt: baseNow,
        ),
      ),
    ];
  }

  group('TaskRiskCubit & SprintRiskCubit', () {
    test(
      'TaskRiskCubit tải dự báo và cập nhật giả lập What-if tức thì',
      () async {
        final cubit = TaskRiskCubit(
          projectId: 'p1',
          nowProvider: () => baseNow,
        );

        final task = TaskModel(
          id: 't1',
          storyId: 's1',
          projectId: 'p1',
          title: 'Task đang trễ tiến độ',
          description: '',
          status: 'To Do',
          assigneeId: 'u1',
          assigneeName: 'Phạm Duy',
          deadline: baseNow.add(const Duration(hours: 8)),
          createdAt: baseNow.subtract(const Duration(days: 5)),
          updatedAt: baseNow,
        );

        await cubit.evaluateTask(
          task: task,
          members: buildMembers(),
          allProjectTasks: [task],
        );

        expect(cubit.state.status, equals(TaskRiskStatus.loaded));
        expect(cubit.state.prediction, isNotNull);
        expect(cubit.state.prediction!.isPredictable, isTrue);

        final initialProb = cubit.state.prediction!.probability;

        // Kéo thanh trượt gia hạn thêm 4 ngày và đổi sang u2
        cubit.simulateWhatIf(
          assigneeId: 'u2',
          assigneeName: 'Nguyễn Hiếu',
          addedDays: 4,
        );

        expect(cubit.state.simulatedAddedDays, equals(4));
        expect(cubit.state.selectedAssigneeId, equals('u2'));
        expect(cubit.state.activeSimulation, isNotNull);
        expect(
          cubit.state.activeSimulation!.newProbability,
          lessThan(initialProb),
        );

        await cubit.close();
      },
    );

    test(
      'SprintRiskCubit xếp hạng danh sách task theo xác suất rủi ro giảm dần',
      () async {
        final cubit = SprintRiskCubit(
          projectId: 'p1',
          nowProvider: () => baseNow,
        );

        final highRiskTask = TaskModel(
          id: 't_high',
          storyId: 's1',
          projectId: 'p1',
          title: 'Task Rủi ro cao',
          description: '',
          status: 'To Do',
          assigneeId: null, // chưa giao + sát hạn
          deadline: baseNow.subtract(const Duration(days: 2)),
          createdAt: baseNow.subtract(const Duration(days: 7)),
          updatedAt: baseNow,
        );

        final lowRiskTask = TaskModel(
          id: 't_low',
          storyId: 's1',
          projectId: 'p1',
          title: 'Task Rủi ro thấp',
          description: '',
          status: 'In Progress',
          assigneeId: 'u2',
          loggedHours: 6.0,
          deadline: baseNow.add(const Duration(days: 10)),
          createdAt: baseNow.subtract(const Duration(days: 1)),
          updatedAt: baseNow,
        );

        await cubit.evaluateTasksList(
          tasks: [lowRiskTask, highRiskTask],
          members: buildMembers(),
        );

        expect(cubit.state.status, equals(SprintRiskStatus.loaded));
        expect(cubit.state.actionableRiskTasks.length, equals(2));
        expect(cubit.state.actionableRiskTasks.first.task.id, equals('t_high'));
        expect(
          cubit.state.actionableRiskTasks.first.probability,
          greaterThan(cubit.state.actionableRiskTasks.last.probability),
        );

        await cubit.close();
      },
    );
  });

  group(
    'Widget Tests — RiskBadge, TaskRiskRadarCard, WhatIfBottomSheet & SprintHighRiskTasksCard',
    () {
      testWidgets('RiskBadge hiển thị đúng mức độ rủi ro và phần trăm', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: Column(
                children: [
                  RiskBadge(probability: 0.18),
                  RiskBadge(probability: 0.50),
                  RiskBadge(probability: 0.82),
                ],
              ),
            ),
          ),
        );

        expect(find.textContaining('18%'), findsOneWidget);
        expect(find.textContaining('50%'), findsOneWidget);
        expect(find.textContaining('82%'), findsOneWidget);
      });

      testWidgets(
        'TaskRiskRadarCard hiển thị đầy đủ lý do, mở What-if sheet và áp dụng gợi ý',
        (tester) async {
          final cubit = TaskRiskCubit(
            projectId: 'p1',
            nowProvider: () => baseNow,
          );
          final task = TaskModel(
            id: 't_ui_1',
            storyId: 's1',
            projectId: 'p1',
            title: 'Xây dựng màn hình báo cáo',
            description: '',
            status: 'To Do',
            assigneeId: 'u1',
            assigneeName: 'Phạm Duy',
            deadline: baseNow.add(const Duration(hours: 6)),
            createdAt: baseNow.subtract(const Duration(days: 4)),
            updatedAt: baseNow,
          );

          await cubit.evaluateTask(
            task: task,
            members: buildMembers(),
            allProjectTasks: [task],
          );

          String? appliedAssignee;
          DateTime? appliedDeadline;

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: BlocProvider.value(
                    value: cubit,
                    child: TaskRiskRadarCard(
                      canApplyWhatIf: true,
                      onApplyWhatIf: (newAssignee, newDeadline) async {
                        appliedAssignee = newAssignee;
                        appliedDeadline = newDeadline;
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byKey(const Key('task_risk_radar_card')), findsOneWidget);
          expect(find.text('AI Risk Radar'), findsOneWidget);
          expect(find.text('3 yếu tố ảnh hưởng lớn nhất:'), findsOneWidget);

          // Mở bottom sheet What-if
          await tester.tap(
            find.byKey(const Key('task_risk_open_what_if_button')),
          );
          await tester.pumpAndSettle();

          expect(
            find.text('Giả lập điều chỉnh rủi ro (What-if)'),
            findsOneWidget,
          );

          // Chọn thành viên u2 (Nguyễn Hiếu)
          final memberFinder = find.byKey(const Key('what_if_member_u2'));
          await tester.ensureVisible(memberFinder);
          await tester.tap(memberFinder);
          await tester.pumpAndSettle();

          // Bấm nút Áp dụng
          final applyFinder = find.byKey(const Key('what_if_apply_button'));
          await tester.ensureVisible(applyFinder);
          await tester.tap(applyFinder);
          await tester.pumpAndSettle();

          expect(appliedAssignee, equals('u2'));
          expect(appliedDeadline, isNull);

          await cubit.close();
        },
      );

      testWidgets(
        'TaskRiskRadarCard hiển thị trạng thái Chưa đặt deadline khi task không có deadline',
        (tester) async {
          final cubit = TaskRiskCubit(
            projectId: 'p1',
            nowProvider: () => baseNow,
          );
          final noDeadlineTask = TaskModel(
            id: 't_no_dl',
            storyId: 's1',
            projectId: 'p1',
            title: 'Task chưa đặt hạn',
            description: '',
            status: 'To Do',
            deadline: null,
            createdAt: baseNow,
            updatedAt: baseNow,
          );

          await cubit.evaluateTask(task: noDeadlineTask);

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: BlocProvider.value(
                  value: cubit,
                  child: const TaskRiskRadarCard(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('task_risk_missing_deadline_view')),
            findsOneWidget,
          );
          expect(find.textContaining('Chưa đặt deadline'), findsOneWidget);

          await cubit.close();
        },
      );

      testWidgets(
        'SprintHighRiskTasksCard hiển thị danh sách task rủi ro cao',
        (tester) async {
          final cubit = SprintRiskCubit(
            projectId: 'p1',
            nowProvider: () => baseNow,
          );
          final task = TaskModel(
            id: 't_sprint_1',
            storyId: 's1',
            projectId: 'p1',
            title: 'Tối ưu truy vấn cơ sở dữ liệu',
            description: '',
            status: 'To Do',
            deadline: baseNow.subtract(const Duration(days: 1)),
            createdAt: baseNow.subtract(const Duration(days: 5)),
            updatedAt: baseNow,
          );

          await cubit.evaluateTasksList(tasks: [task], members: buildMembers());

          await tester.pumpWidget(
            MaterialApp(
              theme: AppTheme.lightTheme,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: BlocProvider.value(
                    value: cubit,
                    child: const SprintHighRiskTasksCard(projectId: 'p1'),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(
            find.byKey(const Key('sprint_high_risk_tasks_card')),
            findsOneWidget,
          );
          expect(find.text('Tối ưu truy vấn cơ sở dữ liệu'), findsOneWidget);

          await cubit.close();
        },
      );
    },
  );
}
