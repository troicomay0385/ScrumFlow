import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/app/theme/app_theme.dart';
import 'package:scrumflow/data/models/task_model.dart';
import 'package:scrumflow/presentation/ai/bloc/model_lab_cubit.dart';
import 'package:scrumflow/presentation/ai/bloc/model_lab_state.dart';
import 'package:scrumflow/presentation/ai/screens/model_lab_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final baseNow = DateTime(2026, 10, 22, 12);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  List<TaskModel> buildSampleDoneTasks(int count) {
    return List<TaskModel>.generate(count, (i) {
      final isLate = i.isEven;
      final deadline = baseNow.subtract(const Duration(days: 5));
      return TaskModel(
        id: 'done_task_$i',
        storyId: 's1',
        projectId: 'p_lab',
        title: 'Task hoàn thành #$i',
        description: '',
        status: 'Done',
        assigneeId: 'u1',
        deadline: deadline,
        createdAt: baseNow.subtract(const Duration(days: 10)),
        updatedAt: isLate
            ? deadline.add(const Duration(days: 2))
            : deadline.subtract(const Duration(days: 1)),
      );
    });
  }

  group('ModelLabCubit — US-071', () {
    test(
      'loadModelInfo tải mô hình, đếm mẫu real và cảnh báo khi < 10 mẫu real',
      () async {
        final cubit = ModelLabCubit(projectId: 'p_lab');
        final tasks = buildSampleDoneTasks(4);

        await cubit.loadModelInfo(preloadedTasks: tasks);

        expect(cubit.state.status, equals(ModelLabStatus.loaded));
        expect(cubit.state.artifact, isNotNull);
        expect(cubit.state.detectedRealTaskCount, equals(4));
        expect(cubit.state.hasLowRealDataWarning, isTrue);

        await cubit.close();
      },
    );

    test(
      'retrainWithProjectData gộp mẫu real, lưu lịch sử loss và xuất JSON hợp lệ',
      () async {
        final cubit = ModelLabCubit(projectId: 'p_lab');
        final tasks = buildSampleDoneTasks(6);

        await cubit.loadModelInfo(preloadedTasks: tasks);
        await cubit.retrainWithProjectData(
          preloadedTasks: tasks,
          seed: 99,
          syntheticCount: 200,
          epochs: 40,
        );

        expect(cubit.state.status, equals(ModelLabStatus.loaded));
        expect(cubit.state.previousMetricsBeforeRetrain, isNotNull);
        expect(cubit.state.artifact!.realSampleCount, equals(6));
        expect(cubit.state.liveTrainLosses, isNotEmpty);

        final exported = cubit.exportWeightsJson();
        final decoded = jsonDecode(exported) as Map<String, dynamic>;
        expect(decoded['realSampleCount'], equals(6));
        expect(decoded['weights'], isA<List<dynamic>>());

        // Đặt lại mô hình mặc định
        await cubit.resetToDefaultModel();
        expect(cubit.state.artifact!.realSampleCount, equals(0));

        await cubit.close();
      },
    );
  });

  group('ModelLabScreen Widget Tests — US-071', () {
    testWidgets(
      'Hiển thị đầy đủ thẻ dữ liệu, Loss Curve Canvas, Confusion Matrix 2x2, Baseline & Feature Importance',
      (tester) async {
        final cubit = ModelLabCubit(projectId: 'p_lab');
        final tasks = buildSampleDoneTasks(3);
        await cubit.loadModelInfo(preloadedTasks: tasks);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: BlocProvider.value(
              value: cubit,
              child: ModelLabScreen(projectId: 'p_lab', preloadedTasks: tasks),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('model_lab_dataset_card')), findsOneWidget);
        expect(
          find.byKey(const Key('model_lab_low_real_data_warning')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('model_lab_loss_curve_card')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('model_lab_loss_canvas')), findsOneWidget);
        expect(find.byKey(const Key('model_lab_metrics_card')), findsOneWidget);
        expect(
          find.byKey(const Key('model_lab_confusion_matrix')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('model_lab_baseline_card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('model_lab_feature_importance_card')),
          findsOneWidget,
        );

        await cubit.close();
      },
    );
  });
}
