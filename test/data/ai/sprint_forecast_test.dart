import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/data/ai/sprint_forecast_service.dart';
import 'package:scrumflow/data/models/sprint_model.dart';
import 'package:scrumflow/data/models/task_model.dart';
import 'package:scrumflow/data/models/user_story_model.dart';
import 'package:scrumflow/data/repositories/backlog_repository.dart';
import 'package:scrumflow/data/repositories/sprint_repository.dart';
import 'package:scrumflow/data/repositories/task_repository.dart';
import 'package:scrumflow/data/services/ai_demo_data_seeder.dart';
import 'package:scrumflow/domain/ai/core/sprint_forecast_engine.dart';

class _MockBacklogRepo extends Mock implements BacklogRepository {}

class _MockSprintRepo extends Mock implements SprintRepository {}

class _MockTaskRepo extends Mock implements TaskRepository {}

class _FakeUserStoryModel extends Fake implements UserStoryModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUserStoryModel());
  });

  group('SprintForecastService (US-070)', () {
    const service = SprintForecastService();
    final now = DateTime(2026, 10, 22);

    SprintModel makeSprint({
      required String id,
      required String status,
      required DateTime start,
      required DateTime end,
      required List<String> storyIds,
    }) {
      return SprintModel(
        id: id,
        projectId: 'p1',
        name: 'Sprint $id',
        goal: 'Goal',
        storyIds: storyIds,
        startDate: start,
        endDate: end,
        status: status,
        createdAt: start,
        updatedAt: start,
      );
    }

    UserStoryModel makeStory({
      required String id,
      required String key,
      required int points,
      required String status,
      DateTime? completedAt,
    }) {
      return UserStoryModel(
        id: id,
        projectId: 'p1',
        storyKey: key,
        title: 'Story $key',
        description: 'Desc',
        storyPoints: points,
        status: status,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: completedAt ?? now,
        completedAt: completedAt,
      );
    }

    test(
      '1. Uses closedSprintsVelocity when Completed/Closed sprints exist',
      () {
        final closedSprint = makeSprint(
          id: 's_closed',
          status: 'Completed',
          start: now.subtract(const Duration(days: 20)),
          end: now.subtract(const Duration(days: 10)),
          storyIds: ['st_done_1', 'st_done_2'],
        );
        final activeSprint = makeSprint(
          id: 's_active',
          status: 'Active',
          start: now.subtract(const Duration(days: 4)),
          end: now.add(const Duration(days: 10)),
          storyIds: ['st_act_1', 'st_act_2'],
        );

        final allStories = [
          makeStory(
            id: 'st_done_1',
            key: 'US-001',
            points: 10,
            status: 'Done',
            completedAt: now.subtract(const Duration(days: 12)),
          ),
          makeStory(
            id: 'st_done_2',
            key: 'US-002',
            points: 10,
            status: 'Done',
            completedAt: now.subtract(const Duration(days: 11)),
          ),
          makeStory(
            id: 'st_act_1',
            key: 'US-003',
            points: 5,
            status: 'In Progress',
          ),
          makeStory(id: 'st_act_2', key: 'US-004', points: 8, status: 'To Do'),
        ];

        final result = service.forecastSprint(
          sprint: activeSprint,
          sprintStories: allStories.sublist(2),
          allSprints: [closedSprint, activeSprint],
          allProjectStories: allStories,
          now: now,
        );

        expect(result.sourceType, ThroughputSourceType.closedSprintsVelocity);
        expect(result.isLowConfidence, isFalse);
        expect(
          result.daysToCompleteP10,
          lessThanOrEqualTo(result.daysToCompleteP50),
        );
        expect(
          result.daysToCompleteP50,
          lessThanOrEqualTo(result.daysToCompleteP90),
        );
        expect(result.whatIfSuggestions, isNotEmpty);
      },
    );

    test(
      '2. Falls back to activeSprintBurnRate when no closed sprints exist',
      () {
        final activeSprint = makeSprint(
          id: 's_active',
          status: 'Active',
          start: now.subtract(const Duration(days: 5)),
          end: now.add(const Duration(days: 9)),
          storyIds: ['st_1', 'st_2'],
        );
        final sprintStories = [
          makeStory(
            id: 'st_1',
            key: 'US-010',
            points: 5,
            status: 'Done',
            completedAt: now.subtract(const Duration(days: 2)),
          ),
          makeStory(
            id: 'st_2',
            key: 'US-011',
            points: 8,
            status: 'In Progress',
          ),
        ];

        final result = service.forecastSprint(
          sprint: activeSprint,
          sprintStories: sprintStories,
          allSprints: [activeSprint],
          now: now,
        );

        expect(result.sourceType, ThroughputSourceType.activeSprintBurnRate);
      },
    );

    test(
      '3. Falls back to defaultPrior with isLowConfidence = true when no history exists',
      () {
        final activeSprint = makeSprint(
          id: 's_active',
          status: 'Active',
          start: now.subtract(const Duration(days: 1)),
          end: now.add(const Duration(days: 6)),
          storyIds: ['st_1', 'st_2'],
        );
        final sprintStories = [
          makeStory(id: 'st_1', key: 'US-020', points: 8, status: 'To Do'),
          makeStory(id: 'st_2', key: 'US-021', points: 8, status: 'To Do'),
        ];

        final baseResult = service.forecastSprint(
          sprint: activeSprint,
          sprintStories: sprintStories,
          allSprints: [activeSprint],
          now: now,
        );

        expect(baseResult.sourceType, ThroughputSourceType.defaultPrior);
        expect(baseResult.isLowConfidence, isTrue);

        final reducedResult = service.forecastSprint(
          sprint: activeSprint,
          sprintStories: sprintStories,
          allSprints: [activeSprint],
          excludedStoryIds: const {'st_1'},
          now: now,
        );
        expect(
          reducedResult.completionProbability,
          greaterThanOrEqualTo(baseResult.completionProbability),
        );
      },
    );
  });

  group('AiDemoDataSeeder (with Mocks)', () {
    test(
      'Seeds 2 Completed sprints, 1 Active sprint, 8 stories & 12 tasks',
      () async {
        final backlogRepo = _MockBacklogRepo();
        final sprintRepo = _MockSprintRepo();
        final taskRepo = _MockTaskRepo();

        when(
          () => backlogRepo.saveUserStory(any(), any()),
        ).thenAnswer((_) async {});
        when(
          () => sprintRepo.seedSprint(
            projectId: any(named: 'projectId'),
            name: any(named: 'name'),
            goal: any(named: 'goal'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            status: any(named: 'status'),
            storyIds: any(named: 'storyIds'),
          ),
        ).thenAnswer(
          (inv) async => SprintModel(
            id: 'sp_mock',
            projectId: inv.namedArguments[#projectId] as String,
            name: inv.namedArguments[#name] as String,
            goal: inv.namedArguments[#goal] as String,
            startDate: inv.namedArguments[#startDate] as DateTime,
            endDate: inv.namedArguments[#endDate] as DateTime,
            status: inv.namedArguments[#status] as String,
            createdAt: DateTime(2026, 10, 22),
            updatedAt: DateTime(2026, 10, 22),
          ),
        );

        int taskSeq = 0;
        when(
          () => taskRepo.createTask(
            storyId: any(named: 'storyId'),
            projectId: any(named: 'projectId'),
            title: any(named: 'title'),
            description: any(named: 'description'),
            assigneeId: any(named: 'assigneeId'),
            assigneeName: any(named: 'assigneeName'),
            deadline: any(named: 'deadline'),
          ),
        ).thenAnswer((inv) async {
          taskSeq++;
          return TaskModel(
            id: 'task_mock_$taskSeq',
            storyId: inv.namedArguments[#storyId] as String,
            projectId: inv.namedArguments[#projectId] as String?,
            title: inv.namedArguments[#title] as String,
            description: inv.namedArguments[#description] as String,
            createdAt: DateTime(2026, 10, 22),
            updatedAt: DateTime(2026, 10, 22),
          );
        });

        when(
          () => taskRepo.updateTaskStatus(any(), any()),
        ).thenAnswer((_) async {});

        final seeder = AiDemoDataSeeder(
          backlogRepo: backlogRepo,
          sprintRepo: sprintRepo,
          taskRepo: taskRepo,
        );

        final res = await seeder.seedAiDemoData(
          projectId: 'proj_demo',
          members: const [],
          referenceNow: DateTime(2026, 10, 22),
        );

        expect(res.createdClosedSprints, 2);
        expect(res.createdActiveSprints, 1);
        expect(res.createdStories, 8);
        expect(res.createdTasks, 12);

        verify(() => backlogRepo.saveUserStory('proj_demo', any())).called(8);
        verify(
          () => taskRepo.createTask(
            storyId: any(named: 'storyId'),
            projectId: 'proj_demo',
            title: any(named: 'title'),
            description: any(named: 'description'),
            assigneeId: any(named: 'assigneeId'),
            assigneeName: any(named: 'assigneeName'),
            deadline: any(named: 'deadline'),
          ),
        ).called(12);
      },
    );
  });
}
