import 'package:flutter_test/flutter_test.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/data/ai/ai_model_store.dart';
import 'package:scrumflow/data/ai/risk_prediction_service.dart';
import 'package:scrumflow/data/ai/task_risk_feature_extractor.dart';
import 'package:scrumflow/data/models/project_member_display.dart';
import 'package:scrumflow/data/models/project_member_model.dart';
import 'package:scrumflow/data/models/sprint_model.dart';
import 'package:scrumflow/data/models/task_model.dart';
import 'package:scrumflow/data/models/user_model.dart';
import 'package:scrumflow/data/models/user_story_model.dart';
import 'package:scrumflow/domain/ai/core/ai_training_pipeline.dart';
import 'package:scrumflow/domain/ai/core/feature_spec.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const extractor = TaskRiskFeatureExtractor();
  final baseNow = DateTime(2026, 10, 22, 12);

  group('TaskRiskFeatureExtractor — Live & Chống rò rỉ nhãn', () {
    test('Xác định đúng lý do bỏ qua (Done hoặc chưa đặt deadline)', () {
      final doneTask = TaskModel(
        id: 't_done',
        storyId: 's1',
        title: 'Task Done',
        description: '',
        status: 'Done',
        deadline: baseNow.add(const Duration(days: 2)),
        createdAt: baseNow.subtract(const Duration(days: 3)),
        updatedAt: baseNow,
      );
      final noDeadlineTask = TaskModel(
        id: 't_nodeadline',
        storyId: 's1',
        title: 'Task No Deadline',
        description: '',
        status: 'In Progress',
        deadline: null,
        createdAt: baseNow.subtract(const Duration(days: 3)),
        updatedAt: baseNow,
      );
      final openTask = TaskModel(
        id: 't_open',
        storyId: 's1',
        title: 'Task Open',
        description: '',
        status: 'In Progress',
        deadline: baseNow.add(const Duration(days: 2)),
        createdAt: baseNow.subtract(const Duration(days: 3)),
        updatedAt: baseNow,
      );

      expect(
        extractor.checkSkipReason(doneTask),
        equals(TaskRiskSkipReason.alreadyDone),
      );
      expect(
        extractor.checkSkipReason(noDeadlineTask),
        equals(TaskRiskSkipReason.missingDeadline),
      );
      expect(extractor.checkSkipReason(openTask), isNull);
    });

    test('Trích xuất an toàn khi thiếu story, sprint, assignee, deadline', () {
      final minimalTask = TaskModel(
        id: 't_min',
        storyId: 's_missing',
        title: 'Minimal Task',
        description: '',
        status: 'To Do',
        assigneeId: null,
        deadline: null,
        createdAt: baseNow,
        updatedAt: baseNow,
      );

      final features = extractor.extractForLiveTask(
        task: minimalTask,
        now: baseNow,
      );

      expect(features.length, equals(TaskFeatureSpec.featureCount));
      for (final f in features) {
        expect(f.isNaN, isFalse);
        expect(f.isInfinite, isFalse);
      }
      expect(features[TaskFeatureSpec.idxUnassigned], equals(1.0));
    });

    test(
      'CHỐNG RÒ RỈ NHÃN (Anti-Label Leakage): Đổi updatedAt của task Done KHÔNG làm thay đổi vector đặc trưng',
      () {
        final createdAt = DateTime(2026, 10, 10, 9);
        final deadline = DateTime(2026, 10, 16, 18);

        final taskCompletedEarly = TaskModel(
          id: 't_real_1',
          storyId: 's1',
          projectId: 'p1',
          title: 'Xây dựng API đăng nhập',
          description: '',
          status: 'Done',
          assigneeId: 'u_dev',
          loggedHours: 6.0,
          deadline: deadline,
          createdAt: createdAt,
          updatedAt: DateTime(
            2026,
            10,
            14,
            15,
          ), // Hoàn thành sớm 2 ngày → nhãn 0
        );

        final taskCompletedLate = taskCompletedEarly.copyWith(
          updatedAt: DateTime(2026, 10, 20, 22), // Trễ 4 ngày → nhãn 1
        );

        final otherHistoricalTask = TaskModel(
          id: 't_real_other',
          storyId: 's1',
          projectId: 'p1',
          title: 'Task khác của cùng dev',
          description: '',
          status: 'Done',
          assigneeId: 'u_dev',
          deadline: deadline,
          createdAt: createdAt,
          updatedAt: DateTime(2026, 10, 15, 10),
        );

        final story = UserStoryModel(
          id: 's1',
          projectId: 'p1',
          storyKey: 'US-001',
          title: 'Story 1',
          description: '',
          priority: 'CAO',
          storyPoints: 8,
          createdAt: createdAt,
          updatedAt: createdAt,
        );

        final sprint = SprintModel(
          id: 'sp1',
          projectId: 'p1',
          name: 'Sprint 1',
          goal: 'Goal',
          storyIds: const ['s1'],
          startDate: DateTime(2026, 10, 1),
          endDate: DateTime(2026, 10, 15),
          status: 'Active',
          createdAt: createdAt,
          updatedAt: createdAt,
        );

        final sampleEarly = extractor.extractLabeledSampleFromDoneTask(
          task: taskCompletedEarly,
          story: story,
          sprint: sprint,
          allProjectTasks: [taskCompletedEarly, otherHistoricalTask],
        );

        final sampleLate = extractor.extractLabeledSampleFromDoneTask(
          task: taskCompletedLate,
          story: story,
          sprint: sprint,
          allProjectTasks: [taskCompletedLate, otherHistoricalTask],
        );

        expect(sampleEarly, isNotNull);
        expect(sampleLate, isNotNull);

        // Nhãn thay đổi từ 0 (đúng hạn) sang 1 (trễ hạn)
        expect(sampleEarly!.label, equals(0));
        expect(sampleLate!.label, equals(1));

        // Nhưng vector 10 đặc trưng phải BẤT BIẾN tuyệt đối (không rò rỉ updatedAt)
        expect(sampleEarly.features, equals(sampleLate.features));
      },
    );
  });

  group('AiModelStore — Lưu trữ SharedPreferences & Tự phục hồi khi hỏng', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'Lưu và đọc TrainedRiskModelArtifact toàn vẹn theo projectId',
      () async {
        final store = AiModelStore();
        const pipeline = AiTrainingPipeline();
        final artifact = pipeline.trainModel(
          syntheticCount: 160,
          epochs: 30,
          seed: 42,
        );

        await store.saveModel('proj_alpha', artifact);
        final loaded = await store.loadModel('proj_alpha');
        final otherProj = await store.loadModel('proj_beta');

        expect(loaded, isNotNull);
        expect(otherProj, isNull);
        expect(loaded!.model.bias, closeTo(artifact.model.bias, 1e-12));
        expect(
          loaded.model.weights.length,
          equals(TaskFeatureSpec.featureCount),
        );
      },
    );

    test(
      'Dữ liệu JSON bị hỏng hoặc sai schemaVersion trả về null an toàn',
      () async {
        final key = AiModelStore.storageKeyForProject('proj_corrupt');
        SharedPreferences.setMockInitialValues({
          key: '{corrupted_json_not_valid',
        });

        final store = AiModelStore();
        final loaded = await store.loadModel('proj_corrupt');
        expect(loaded, isNull);

        // Ghi JSON hợp lệ nhưng sai schemaVersion
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, '{"schemaVersion": 999}');
        final loadedWrongVer = await store.loadModel('proj_corrupt');
        expect(loadedWrongVer, isNull);
      },
    );
  });

  group('RiskPredictionService — Suy luận & Giả lập What-if', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'Tự huấn luyện bootstrap khi chưa có model và suy luận + gợi ý What-if hợp lệ',
      () async {
        final service = RiskPredictionService();
        final members = [
          ProjectMemberDisplay(
            membership: ProjectMemberModel(
              id: 'p1_u_busy',
              projectId: 'p1',
              userId: 'u_busy',
              role: ProjectRole.member,
              createdBy: 'u0',
              createdAt: baseNow,
              updatedAt: baseNow,
            ),
            user: UserModel(
              id: 'u_busy',
              fullName: 'Thành viên Quá tải',
              email: 'busy@scrumflow.com',
              loginProvider: 'email',
              createdAt: baseNow,
            ),
          ),
          ProjectMemberDisplay(
            membership: ProjectMemberModel(
              id: 'p1_u_free',
              projectId: 'p1',
              userId: 'u_free',
              role: ProjectRole.member,
              createdBy: 'u0',
              createdAt: baseNow,
              updatedAt: baseNow,
            ),
            user: UserModel(
              id: 'u_free',
              fullName: 'Thành viên Rảnh & Đúng hạn',
              email: 'free@scrumflow.com',
              loginProvider: 'email',
              createdAt: baseNow,
            ),
          ),
        ];

        final riskyTask = TaskModel(
          id: 't_risky',
          storyId: 's1',
          projectId: 'p1',
          title: 'Tích hợp cổng thanh toán phức tạp',
          description: '',
          status: 'To Do',
          assigneeId: 'u_busy',
          assigneeName: 'Thành viên Quá tải',
          loggedHours: 0.0,
          deadline: baseNow.add(const Duration(hours: 12)), // Sắp hết hạn
          createdAt: baseNow.subtract(const Duration(days: 5)),
          updatedAt: baseNow,
        );

        // u_busy có 5 task đang In Progress và 2 task trễ hạn trong lịch sử
        final allTasks = <TaskModel>[
          riskyTask,
          for (int i = 0; i < 5; i++)
            TaskModel(
              id: 'wip_$i',
              storyId: 's1',
              projectId: 'p1',
              title: 'WIP $i',
              description: '',
              status: 'In Progress',
              assigneeId: 'u_busy',
              createdAt: baseNow.subtract(const Duration(days: 3)),
              updatedAt: baseNow,
            ),
          for (int i = 0; i < 2; i++)
            TaskModel(
              id: 'late_$i',
              storyId: 's1',
              projectId: 'p1',
              title: 'Late $i',
              description: '',
              status: 'Done',
              assigneeId: 'u_busy',
              deadline: baseNow.subtract(const Duration(days: 4)),
              createdAt: baseNow.subtract(const Duration(days: 8)),
              updatedAt: baseNow.subtract(const Duration(days: 1)), // trễ
            ),
        ];

        final prediction = await service.predictTaskRisk(
          projectId: 'p1',
          task: riskyTask,
          members: members,
          allProjectTasks: allTasks,
          now: baseNow,
        );

        expect(prediction.isPredictable, isTrue);
        expect(prediction.probability, inInclusiveRange(0.0, 1.0));
        expect(prediction.topReasons.length, equals(3));
        expect(prediction.suggestions, isNotEmpty);

        // Kiểm tra What-if gia hạn thêm 5 ngày làm giảm xác suất trễ hạn
        final artifact = await service.ensureModelLoaded('p1');
        final extendedSim = service.simulateWhatIfSync(
          artifact: artifact,
          task: riskyTask,
          originalProbability: prediction.probability,
          allProjectTasks: allTasks,
          addedDays: 5,
          now: baseNow,
        );
        expect(extendedSim.newProbability, lessThan(prediction.probability));
      },
    );
  });
}
