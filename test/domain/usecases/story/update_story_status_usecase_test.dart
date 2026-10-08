import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/domain/repositories/story_repository.dart';
import 'package:scrumflow/domain/usecases/story/update_story_status_usecase.dart';

class MockStoryRepository extends Mock implements StoryRepository {}

void main() {
  late MockStoryRepository mockRepository;
  late UpdateStoryStatusUseCase useCase;

  setUp(() {
    mockRepository = MockStoryRepository();
    useCase = UpdateStoryStatusUseCase(mockRepository);
  });

  group('UpdateStoryStatusUseCase', () {
    test('ném lỗi khi projectId rỗng', () async {
      expect(
        () => useCase(
          projectId: '',
          storyId: 'story-1',
          newStatus: 'In Progress',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('projectId không hợp lệ'),
          ),
        ),
      );
    });

    test('ném lỗi khi storyId rỗng', () async {
      expect(
        () => useCase(
          projectId: 'proj-1',
          storyId: '',
          newStatus: 'In Progress',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('storyId không hợp lệ'),
          ),
        ),
      );
    });

    test('ném lỗi khi newStatus không nằm trong danh sách hợp lệ', () async {
      expect(
        () => useCase(
          projectId: 'proj-1',
          storyId: 'story-1',
          newStatus: 'Archived',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Trạng thái không hợp lệ'),
          ),
        ),
      );
    });

    for (final status in ['To Do', 'In Progress', 'Done', 'Rejected']) {
      test('gọi repository thành công với trạng thái hợp lệ "$status"', () async {
        when(
          () => mockRepository.updateStoryStatus(
            projectId: any(named: 'projectId'),
            storyId: any(named: 'storyId'),
            newStatus: any(named: 'newStatus'),
          ),
        ).thenAnswer((_) async {});

        await useCase(
          projectId: 'proj-1',
          storyId: 'story-1',
          newStatus: status,
        );

        verify(
          () => mockRepository.updateStoryStatus(
            projectId: 'proj-1',
            storyId: 'story-1',
            newStatus: status,
          ),
        ).called(1);
      });
    }
  });
}
