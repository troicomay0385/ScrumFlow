import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/app/services/notification_service.dart';
import 'package:scrumflow/data/models/attachment_model.dart';
import 'package:scrumflow/data/models/project_member_display.dart';
import 'package:scrumflow/data/models/project_member_model.dart';
import 'package:scrumflow/data/models/sprint_model.dart';
import 'package:scrumflow/data/models/task_model.dart';
import 'package:scrumflow/data/models/user_model.dart';
import 'package:scrumflow/data/models/user_story_model.dart';
import 'package:scrumflow/data/repositories/attachment_repository.dart';
import 'package:scrumflow/data/repositories/backlog_repository.dart';
import 'package:scrumflow/data/repositories/sprint_repository.dart';
import 'package:scrumflow/data/repositories/task_repository.dart';
import 'package:scrumflow/data/services/sample_data_seeder.dart';

class MockBacklogRepository extends Mock implements BacklogRepository {}

class MockTaskRepository extends Mock implements TaskRepository {}

class MockAttachmentRepository extends Mock implements AttachmentRepository {}

class MockSprintRepository extends Mock implements SprintRepository {}

class MockNotificationService extends Mock implements NotificationService {}

class FakeAttachmentTarget extends Fake implements AttachmentTarget {}

class FakeUserStoryModel extends Fake implements UserStoryModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAttachmentTarget());
    registerFallbackValue(FakeUserStoryModel());
  });

  late MockBacklogRepository backlogRepo;
  late MockTaskRepository taskRepo;
  late MockAttachmentRepository attachmentRepo;
  late MockSprintRepository sprintRepo;
  late MockNotificationService notificationService;
  late SampleDataSeeder seeder;

  final now = DateTime(2026, 10, 7);

  final sampleTask = TaskModel(
    id: 'task-1',
    storyId: 'story-1',
    projectId: 'p1',
    title: 'Task test',
    description: '',
    status: 'To Do',
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    backlogRepo = MockBacklogRepository();
    taskRepo = MockTaskRepository();
    attachmentRepo = MockAttachmentRepository();
    sprintRepo = MockSprintRepository();
    notificationService = MockNotificationService();

    seeder = SampleDataSeeder(
      backlogRepo: backlogRepo,
      taskRepo: taskRepo,
      attachmentRepo: attachmentRepo,
      sprintRepo: sprintRepo,
      notificationService: notificationService,
    );

    when(() => backlogRepo.saveUserStory(any(), any()))
        .thenAnswer((_) async {});

    when(() => sprintRepo.seedSprint(
          projectId: any(named: 'projectId'),
          name: any(named: 'name'),
          goal: any(named: 'goal'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          status: any(named: 'status'),
          storyIds: any(named: 'storyIds'),
        )).thenAnswer((_) async => SprintModel(
          id: 'sprint-1',
          projectId: 'p1',
          name: 'Sprint 1',
          goal: 'Goal',
          startDate: now,
          endDate: now.add(const Duration(days: 14)),
          status: 'Active',
          createdAt: now,
          updatedAt: now,
        ));

    when(() => taskRepo.createTask(
          storyId: any(named: 'storyId'),
          projectId: any(named: 'projectId'),
          title: any(named: 'title'),
          description: any(named: 'description'),
          assigneeId: any(named: 'assigneeId'),
          assigneeName: any(named: 'assigneeName'),
          deadline: any(named: 'deadline'),
        )).thenAnswer((_) async => sampleTask);

    when(() => taskRepo.updateTaskStatus(any(), any()))
        .thenAnswer((_) async {});

    when(() => attachmentRepo.addAttachment(
          target: any(named: 'target'),
          fileName: any(named: 'fileName'),
          fileSize: any(named: 'fileSize'),
          fileType: any(named: 'fileType'),
          fileUrl: any(named: 'fileUrl'),
          isLink: any(named: 'isLink'),
        )).thenAnswer((_) async => AttachmentModel(
          id: 'att-1',
          projectId: 'p1',
          fileName: 'test.pdf',
          fileSize: 100,
          fileType: 'pdf',
          uploadedById: 'u1',
          uploadedByName: 'User',
          createdAt: now,
        ));

    when(() => notificationService.showTaskDeadlineAlert(
          taskTitle: any(named: 'taskTitle'),
          deadline: any(named: 'deadline'),
          hoursRemaining: any(named: 'hoursRemaining'),
        )).thenAnswer((_) async {});
  });

  group('SampleDataSeeder (Sprint 2, 3, 4 Test Lab)', () {
    test('seeds sample sprint, stories, tasks, attachments and triggers deadline alert',
        () async {
      final member = ProjectMemberDisplay(
        membership: ProjectMemberModel(
          id: 'p1_u1',
          projectId: 'p1',
          userId: 'u1',
          role: ProjectRole.member,
          createdBy: 'admin',
          createdAt: now,
          updatedAt: now,
        ),
        user: UserModel(
          id: 'u1',
          email: 'u1@example.com',
          fullName: 'Test User',
          createdAt: now,
          loginProvider: 'email',
        ),
      );

      final result = await seeder.seedSampleData(
        projectId: 'p1',
        members: [member],
        currentUserId: 'u1',
        currentUserName: 'Test User',
      );

      expect(result.createdSprints, 1);
      expect(result.createdStories, 4);
      expect(result.createdTasks, 4);
      expect(result.createdAttachments, 4);
      expect(result.hasNotifiedDeadline, isTrue);

      verify(() => backlogRepo.saveUserStory(any(), any())).called(4);
      verify(() => sprintRepo.seedSprint(
            projectId: any(named: 'projectId'),
            name: any(named: 'name'),
            goal: any(named: 'goal'),
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            status: any(named: 'status'),
            storyIds: any(named: 'storyIds'),
          )).called(1);
      verify(() => taskRepo.createTask(
            storyId: any(named: 'storyId'),
            projectId: any(named: 'projectId'),
            title: any(named: 'title'),
            description: any(named: 'description'),
            assigneeId: any(named: 'assigneeId'),
            assigneeName: any(named: 'assigneeName'),
            deadline: any(named: 'deadline'),
          )).called(4);
      verify(() => attachmentRepo.addAttachment(
            target: any(named: 'target'),
            fileName: any(named: 'fileName'),
            fileSize: any(named: 'fileSize'),
            fileType: any(named: 'fileType'),
            fileUrl: any(named: 'fileUrl'),
            isLink: any(named: 'isLink'),
          )).called(4);
      verify(() => notificationService.showTaskDeadlineAlert(
            taskTitle: any(named: 'taskTitle'),
            deadline: any(named: 'deadline'),
            hoursRemaining: any(named: 'hoursRemaining'),
          )).called(1);
    });
  });
}
