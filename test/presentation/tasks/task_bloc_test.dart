import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/data/models/task_model.dart';
import 'package:scrumflow/data/repositories/task_repository.dart';
import 'package:scrumflow/presentation/tasks/bloc/task_bloc.dart';
import 'package:scrumflow/presentation/tasks/bloc/task_event.dart';
import 'package:scrumflow/presentation/tasks/bloc/task_state.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  const storyId = 'story-1';
  const taskId = 'task-1';
  final now = DateTime(2026, 10, 17);

  final task1 = TaskModel(
    id: taskId,
    storyId: storyId,
    title: 'Task 1',
    description: 'Mô tả task 1',
    status: 'To Do',
    createdAt: now,
    updatedAt: now,
  );

  final task2 = TaskModel(
    id: 'task-2',
    storyId: storyId,
    title: 'Task 2',
    description: 'Mô tả task 2',
    status: 'In Progress',
    createdAt: now,
    updatedAt: now,
  );

  late MockTaskRepository repository;

  setUp(() {
    repository = MockTaskRepository();
  });

  group('TaskBloc', () {
    test('trạng thái ban đầu là TaskInitial', () {
      final bloc = TaskBloc(repository: repository);
      expect(bloc.state, isA<TaskInitial>());
      bloc.close();
    });

    blocTest<TaskBloc, TaskState>(
      'TaskSubscriptionRequested emit Loading rồi emit Loaded khi stream có dữ liệu',
      build: () {
        when(() => repository.streamTasksByStory(storyId))
            .thenAnswer((_) => Stream.value([task1, task2]));
        return TaskBloc(repository: repository);
      },
      act: (bloc) => bloc.add(const TaskSubscriptionRequested(storyId)),
      expect: () => [
        isA<TaskLoading>(),
        TaskLoaded([task1, task2]),
      ],
      verify: (_) {
        verify(() => repository.streamTasksByStory(storyId)).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'cập nhật lạc quan thành công: đổi trạng thái trên UI ngay lập tức',
      build: () {
        when(() => repository.updateTaskStatus(taskId, 'In Progress'))
            .thenAnswer((_) async {});
        return TaskBloc(repository: repository);
      },
      seed: () => TaskLoaded([task1, task2]),
      act: (bloc) => bloc.add(const TaskStatusUpdated(taskId, 'In Progress')),
      expect: () => [
        TaskLoaded([task1.copyWith(status: 'In Progress'), task2]),
      ],
      verify: (_) {
        verify(() => repository.updateTaskStatus(taskId, 'In Progress')).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'repository lỗi → hoàn lại danh sách cũ + phát lỗi TaskError',
      build: () {
        when(() => repository.updateTaskStatus(taskId, 'In Progress'))
            .thenThrow(Exception('Lỗi mạng hoặc phân quyền'));
        return TaskBloc(repository: repository);
      },
      seed: () => TaskLoaded([task1, task2]),
      act: (bloc) => bloc.add(const TaskStatusUpdated(taskId, 'In Progress')),
      expect: () => [
        // 1. Cập nhật lạc quan
        TaskLoaded([task1.copyWith(status: 'In Progress'), task2]),
        // 2. Rollback về danh sách cũ
        TaskLoaded([task1, task2]),
        // 3. Phát thông báo lỗi
        const TaskError('Lỗi mạng hoặc phân quyền'),
      ],
      verify: (_) {
        verify(() => repository.updateTaskStatus(taskId, 'In Progress')).called(1);
      },
    );

    blocTest<TaskBloc, TaskState>(
      'repository ném FirebaseException permission-denied → hoàn lại danh sách cũ + ánh xạ tiếng Việt',
      build: () {
        when(() => repository.updateTaskStatus(taskId, 'Done'))
            .thenThrow(FirebaseException(
          plugin: 'firestore',
          code: 'permission-denied',
        ));
        return TaskBloc(repository: repository);
      },
      seed: () => TaskLoaded([task1]),
      act: (bloc) => bloc.add(const TaskStatusUpdated(taskId, 'Done')),
      expect: () => [
        TaskLoaded([task1.copyWith(status: 'Done')]),
        TaskLoaded([task1]),
        isA<TaskError>().having(
          (e) => e.message,
          'message',
          contains('Không có quyền truy cập dữ liệu'),
        ),
      ],
    );
  });
}
